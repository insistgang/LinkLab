-- 历史全量 schema：仅归档，禁止作为当前默认部署迁移。
-- =====================================================
-- 共感 LinkAble Schema 對齊腳本
-- AGENTS.md §4.4：根目錄 supabase/ 是唯一 schema source of truth
-- =====================================================

-- -----------------------------------------------------
-- 1. help_requests 狀態機與匹配字段對齊
-- -----------------------------------------------------

UPDATE help_requests
SET status = CASE
    WHEN status = 'pending' THEN 'created'
    WHEN status = 'matched' THEN 'connected'
    ELSE status
END;

ALTER TABLE help_requests
    ALTER COLUMN status SET DEFAULT 'created';

ALTER TABLE help_requests
    DROP CONSTRAINT IF EXISTS help_requests_status_check;

ALTER TABLE help_requests
    ADD CONSTRAINT help_requests_status_check
    CHECK (
        status IN (
            'created',
            'ai_processing',
            'ai_resolved',
            'matching',
            'connected',
            'completed',
            'cancelled',
            'expired'
        )
    );

ALTER TABLE help_requests
    ADD COLUMN IF NOT EXISTS help_type TEXT DEFAULT 'general',
    ADD COLUMN IF NOT EXISTS required_skills TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

COMMENT ON COLUMN help_requests.status IS
    '狀態機對齊 AGENTS.md §5.2：created, ai_processing, ai_resolved, matching, connected, completed, cancelled, expired';
COMMENT ON COLUMN help_requests.help_type IS
    '兼容 legacy real client / matching-engine 的求助分類字段，主事實來源仍爲根 schema';
COMMENT ON COLUMN help_requests.required_skills IS
    '匹配所需技能標籤，供 F9 Top 5 匹配使用';

-- -----------------------------------------------------
-- 2. volunteer_profiles 對齊真實匹配所需字段
-- -----------------------------------------------------

ALTER TABLE volunteer_profiles
    ADD COLUMN IF NOT EXISTS is_available BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

COMMENT ON COLUMN volunteer_profiles.is_available IS
    '競賽版真實鏈路兼容字段；默認導航仍由 Demo fallback 承擔';

-- -----------------------------------------------------
-- 3. PRD §6.3 MVP 核心表：virtual_identities
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS virtual_identities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    help_request_id UUID NOT NULL REFERENCES help_requests(id) ON DELETE CASCADE,
    virtual_code TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, help_request_id)
);

COMMENT ON TABLE virtual_identities IS
    'PRD §6.3 MVP 核心表：虛擬身份映射，用於匿名求助與臨時身份隔離';

-- -----------------------------------------------------
-- 4. 基礎設施表：保留在根 schema，供實驗性真實鏈路兼容
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_fingerprint TEXT,
    device_info TEXT,
    fcm_token TEXT,
    platform TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,
    invalidated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id)
);

CREATE TABLE IF NOT EXISTS push_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    success BOOLEAN NOT NULL DEFAULT FALSE,
    error_msg TEXT,
    message_id TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_call_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_type TEXT NOT NULL,
    input_preview TEXT,
    success BOOLEAN NOT NULL DEFAULT FALSE,
    error_msg TEXT,
    cost DECIMAL(10,4) DEFAULT 0,
    cached BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS emergency_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_id UUID REFERENCES emergency_contacts(id) ON DELETE SET NULL,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------
-- 5. 經緯度與 PostGIS geography 同步
-- -----------------------------------------------------

CREATE OR REPLACE FUNCTION sync_help_request_location_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    ELSIF NEW.location IS NOT NULL THEN
        NEW.latitude := ST_Y(NEW.location::geometry);
        NEW.longitude := ST_X(NEW.location::geometry);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_help_request_location_fields ON help_requests;
CREATE TRIGGER trigger_sync_help_request_location_fields
    BEFORE INSERT OR UPDATE OF latitude, longitude, location ON help_requests
    FOR EACH ROW
    EXECUTE FUNCTION sync_help_request_location_fields();

CREATE OR REPLACE FUNCTION sync_volunteer_location_fields()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    ELSIF NEW.location IS NOT NULL THEN
        NEW.latitude := ST_Y(NEW.location::geometry);
        NEW.longitude := ST_X(NEW.location::geometry);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_sync_volunteer_location_fields ON volunteer_profiles;
CREATE TRIGGER trigger_sync_volunteer_location_fields
    BEFORE INSERT OR UPDATE OF latitude, longitude, location ON volunteer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION sync_volunteer_location_fields();

UPDATE help_requests
SET latitude = COALESCE(latitude, ST_Y(location::geometry)),
    longitude = COALESCE(longitude, ST_X(location::geometry))
WHERE location IS NOT NULL;

UPDATE volunteer_profiles
SET latitude = COALESCE(latitude, ST_Y(location::geometry)),
    longitude = COALESCE(longitude, ST_X(location::geometry))
WHERE location IS NOT NULL;

-- -----------------------------------------------------
-- 6. 匹配函數、索引與 RLS 對齊
-- -----------------------------------------------------

CREATE OR REPLACE FUNCTION find_matching_volunteers(
    seeker_lat DECIMAL,
    seeker_lng DECIMAL,
    max_dist INT DEFAULT 5000,
    required_skills TEXT[] DEFAULT '{}',
    result_limit INT DEFAULT 5
)
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    avatar_url TEXT,
    skills TEXT[],
    level INT,
    credit_score DECIMAL,
    total_help_count INT,
    distance DECIMAL
) AS $$
DECLARE
    seeker_location GEOGRAPHY := ST_SetSRID(ST_MakePoint(seeker_lng, seeker_lat), 4326)::geography;
BEGIN
    RETURN QUERY
    SELECT
        vp.user_id,
        u.name,
        u.avatar_url,
        vp.skills,
        vp.level,
        vp.credit_score,
        vp.total_help_count,
        ST_Distance(
            COALESCE(
                vp.location,
                ST_SetSRID(ST_MakePoint(vp.longitude, vp.latitude), 4326)::geography
            ),
            seeker_location
        )::DECIMAL AS distance
    FROM volunteer_profiles vp
    JOIN users u ON u.id = vp.user_id
    WHERE
        vp.is_online = TRUE
        AND vp.is_verified = TRUE
        AND vp.is_available = TRUE
        AND (
            vp.location IS NOT NULL OR
            (vp.latitude IS NOT NULL AND vp.longitude IS NOT NULL)
        )
        AND COALESCE(vp.last_heartbeat_at, NOW() - INTERVAL '10 minutes') >= NOW() - INTERVAL '5 minutes'
        AND ST_DWithin(
            COALESCE(
                vp.location,
                ST_SetSRID(ST_MakePoint(vp.longitude, vp.latitude), 4326)::geography
            ),
            seeker_location,
            max_dist
        )
        AND (
            array_length(required_skills, 1) IS NULL OR
            required_skills = '{}' OR
            vp.skills && required_skills
        )
        AND u.is_deleted = FALSE
    ORDER BY
        vp.credit_score DESC,
        distance ASC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;

DROP INDEX IF EXISTS idx_help_location;
CREATE INDEX idx_help_location ON help_requests USING GIST(location)
    WHERE status IN ('created', 'ai_processing', 'matching');

CREATE INDEX IF NOT EXISTS idx_virtual_identities_user
    ON virtual_identities(user_id, expires_at DESC);
CREATE INDEX IF NOT EXISTS idx_virtual_identities_help_request
    ON virtual_identities(help_request_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user
    ON user_devices(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user
    ON notifications(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_push_logs_user
    ON push_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_emergency_notifications_user
    ON emergency_notifications(user_id, sent_at DESC);

DROP POLICY IF EXISTS volunteer_location_for_matching ON volunteer_profiles;
CREATE POLICY volunteer_location_for_matching ON volunteer_profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM help_requests hr
            WHERE hr.volunteer_id = volunteer_profiles.user_id
              AND hr.seeker_id = auth.uid()
              AND hr.status IN ('matching', 'connected')
        )
    );

ALTER TABLE virtual_identities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_call_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS virtual_identity_self_access ON virtual_identities;
CREATE POLICY virtual_identity_self_access ON virtual_identities
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS user_devices_self_access ON user_devices;
CREATE POLICY user_devices_self_access ON user_devices
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS notifications_self_access ON notifications;
CREATE POLICY notifications_self_access ON notifications
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS emergency_notifications_self_read ON emergency_notifications;
CREATE POLICY emergency_notifications_self_read ON emergency_notifications
    FOR SELECT
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS emergency_notifications_self_insert ON emergency_notifications;
CREATE POLICY emergency_notifications_self_insert ON emergency_notifications
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS push_logs_service_only ON push_logs;
CREATE POLICY push_logs_service_only ON push_logs
    FOR ALL
    USING (FALSE)
    WITH CHECK (FALSE);

DROP POLICY IF EXISTS ai_call_logs_service_only ON ai_call_logs;
CREATE POLICY ai_call_logs_service_only ON ai_call_logs
    FOR ALL
    USING (FALSE)
    WITH CHECK (FALSE);

DROP TRIGGER IF EXISTS update_virtual_identities_updated_at ON virtual_identities;
CREATE TRIGGER update_virtual_identities_updated_at
    BEFORE UPDATE ON virtual_identities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_devices_updated_at ON user_devices;
CREATE TRIGGER update_user_devices_updated_at
    BEFORE UPDATE ON user_devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ANALYZE help_requests;
ANALYZE volunteer_profiles;
ANALYZE virtual_identities;
ANALYZE user_devices;
