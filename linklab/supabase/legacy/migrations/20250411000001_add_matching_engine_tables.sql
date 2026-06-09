-- 志願者匹配引擎相關表和函數
-- 創建時間: 2025-04-11

-- ============================================
-- 1. 擴展幫助請求表
-- ============================================

-- 添加匹配相關字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'help_requests' AND column_name = 'required_skills') THEN
        ALTER TABLE help_requests ADD COLUMN required_skills TEXT[] DEFAULT '{}';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'help_requests' AND column_name = 'help_type') THEN
        ALTER TABLE help_requests ADD COLUMN help_type TEXT DEFAULT '一般求助';
    END IF;
END $$;

-- ============================================
-- 2. 創建匹配記錄表
-- ============================================

CREATE TABLE IF NOT EXISTS help_request_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    help_request_id UUID NOT NULL REFERENCES help_requests(id) ON DELETE CASCADE,
    volunteer_id UUID NOT NULL REFERENCES volunteer_profiles(id) ON DELETE CASCADE,
    volunteer_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    match_score DECIMAL(4,3) NOT NULL CHECK (match_score >= 0 AND match_score <= 1),
    distance DECIMAL(10,2), -- 距離（公里）
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'notified', 'accepted', 'rejected', 'expired', 'timeout')),
    priority INTEGER DEFAULT 1, -- 匹配優先級順序
    notified_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(help_request_id, volunteer_id)
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_help_request_matches_request_id ON help_request_matches(help_request_id);
CREATE INDEX IF NOT EXISTS idx_help_request_matches_volunteer_id ON help_request_matches(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_help_request_matches_status ON help_request_matches(status);
CREATE INDEX IF NOT EXISTS idx_help_request_matches_volunteer_user_id ON help_request_matches(volunteer_user_id);

-- 啓用RLS
ALTER TABLE help_request_matches ENABLE ROW LEVEL SECURITY;

-- RLS策略
CREATE POLICY "Users can view their own matches"
    ON help_request_matches FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM help_requests hr
            WHERE hr.id = help_request_matches.help_request_id
            AND (hr.seeker_id = auth.uid() OR help_request_matches.volunteer_user_id = auth.uid())
        )
    );

CREATE POLICY "System can insert matches"
    ON help_request_matches FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Volunteers can update their own matches"
    ON help_request_matches FOR UPDATE
    USING (volunteer_user_id = auth.uid());

-- ============================================
-- 3. 創建用戶設備表（用於FCM推送）
-- ============================================

CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    platform TEXT DEFAULT 'flutter', -- flutter, android, ios, web
    device_info JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(user_id, fcm_token)
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_fcm_token ON user_devices(fcm_token);
CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(is_active) WHERE is_active = true;

-- 啓用RLS
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- RLS策略
CREATE POLICY "Users can manage their own devices"
    ON user_devices FOR ALL
    USING (user_id = auth.uid());

-- ============================================
-- 4. 創建SOS廣播日誌表
-- ============================================

CREATE TABLE IF NOT EXISTS sos_broadcast_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sos_request_id UUID NOT NULL REFERENCES sos_requests(id) ON DELETE CASCADE,
    radius_km INTEGER NOT NULL,
    volunteers_count INTEGER DEFAULT 0,
    notified_count INTEGER DEFAULT 0,
    responded_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_sos_broadcast_logs_sos_id ON sos_broadcast_logs(sos_request_id);

-- 啓用RLS
ALTER TABLE sos_broadcast_logs ENABLE ROW LEVEL SECURITY;

-- RLS策略
CREATE POLICY "Only admins can view broadcast logs"
    ON sos_broadcast_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid()
            AND 'admin' = ANY(role)
        )
    );

-- ============================================
-- 5. 創建用戶在線狀態表
-- ============================================

CREATE TABLE IF NOT EXISTS user_presence (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    is_online BOOLEAN DEFAULT false,
    last_seen_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_user_presence_online ON user_presence(is_online) WHERE is_online = true;

-- 啓用RLS
ALTER TABLE user_presence ENABLE ROW LEVEL SECURITY;

-- RLS策略
CREATE POLICY "Users can view all presence"
    ON user_presence FOR SELECT
    USING (true);

CREATE POLICY "Users can update their own presence"
    ON user_presence FOR ALL
    USING (user_id = auth.uid());

-- ============================================
-- 6. 創建求助心跳錶（用於檢測連接狀態）
-- ============================================

CREATE TABLE IF NOT EXISTS help_request_heartbeats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    help_request_id UUID NOT NULL REFERENCES help_requests(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(help_request_id, user_id)
);

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_help_request_heartbeats_request_id ON help_request_heartbeats(help_request_id);
CREATE INDEX IF NOT EXISTS idx_help_request_heartbeats_timestamp ON help_request_heartbeats(timestamp);

-- 啓用RLS
ALTER TABLE help_request_heartbeats ENABLE ROW LEVEL SECURITY;

-- RLS策略
CREATE POLICY "Users can view heartbeats for their requests"
    ON help_request_heartbeats FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM help_requests hr
            WHERE hr.id = help_request_heartbeats.help_request_id
            AND (hr.seeker_id = auth.uid() OR hr.volunteer_id = auth.uid())
        )
    );

CREATE POLICY "Users can insert their own heartbeats"
    ON help_request_heartbeats FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- ============================================
-- 7. 創建PostGIS函數：獲取範圍內的志願者
-- ============================================

CREATE OR REPLACE FUNCTION get_volunteers_in_radius(
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    skills TEXT[],
    level INTEGER,
    credit_score DECIMAL,
    is_online BOOLEAN,
    is_available BOOLEAN,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    last_heartbeat_at TIMESTAMPTZ,
    distance_km DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        vp.id,
        vp.user_id,
        vp.skills,
        vp.level,
        vp.credit_score,
        vp.is_online,
        vp.is_available,
        vp.latitude,
        vp.longitude,
        vp.last_heartbeat_at,
        -- 使用Haversine公式計算距離
        (6371 * acos(
            cos(radians(lat)) *
            cos(radians(vp.latitude)) *
            cos(radians(vp.longitude) - radians(lng)) +
            sin(radians(lat)) *
            sin(radians(vp.latitude))
        ))::DOUBLE PRECISION AS distance_km
    FROM volunteer_profiles vp
    WHERE
        vp.is_online = true
        AND vp.is_available = true
        AND vp.latitude IS NOT NULL
        AND vp.longitude IS NOT NULL
        AND vp.last_heartbeat_at > NOW() - INTERVAL '5 minutes'
        AND (6371 * acos(
            cos(radians(lat)) *
            cos(radians(vp.latitude)) *
            cos(radians(vp.longitude) - radians(lng)) +
            sin(radians(lat)) *
            sin(radians(vp.latitude))
        )) <= radius_km
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. 創建函數：更新志願者心跳
-- ============================================

CREATE OR REPLACE FUNCTION update_volunteer_heartbeat(
    p_user_id UUID,
    p_lat DOUBLE PRECISION DEFAULT NULL,
    p_lng DOUBLE PRECISION DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE volunteer_profiles
    SET
        last_heartbeat_at = NOW(),
        latitude = COALESCE(p_lat, latitude),
        longitude = COALESCE(p_lng, longitude),
        is_online = true
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 9. 創建觸發器：自動更新updated_at
-- ============================================

-- 爲user_devices創建觸發器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_user_devices_updated_at ON user_devices;
CREATE TRIGGER update_user_devices_updated_at
    BEFORE UPDATE ON user_devices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 爲user_presence創建觸發器
DROP TRIGGER IF EXISTS update_user_presence_updated_at ON user_presence;
CREATE TRIGGER update_user_presence_updated_at
    BEFORE UPDATE ON user_presence
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 10. 創建函數：清理過期匹配記錄
-- ============================================

CREATE OR REPLACE FUNCTION cleanup_expired_matches()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 將過期匹配標記爲timeout
    UPDATE help_request_matches
    SET status = 'timeout'
    WHERE status = 'pending'
    AND expires_at < NOW();

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 11. 創建定時任務（需要pg_cron擴展）
-- ============================================

-- 每分鐘清理過期匹配（如果安裝了pg_cron）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        SELECT cron.schedule('cleanup-expired-matches', '* * * * *', 'SELECT cleanup_expired_matches()');
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron not available, skipping scheduled task setup';
END $$;

-- ============================================
-- 12. 添加volunteer_profiles缺失字段
-- ============================================

DO $$
BEGIN
    -- 添加is_available字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'volunteer_profiles' AND column_name = 'is_available') THEN
        ALTER TABLE volunteer_profiles ADD COLUMN is_available BOOLEAN DEFAULT true;
    END IF;

    -- 添加last_heartbeat_at字段（如果不存在）
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'volunteer_profiles' AND column_name = 'last_heartbeat_at') THEN
        ALTER TABLE volunteer_profiles ADD COLUMN last_heartbeat_at TIMESTAMPTZ;
    END IF;
END $$;

-- 創建索引
CREATE INDEX IF NOT EXISTS idx_volunteer_profiles_online_available ON volunteer_profiles(is_online, is_available)
    WHERE is_online = true AND is_available = true;
CREATE INDEX IF NOT EXISTS idx_volunteer_profiles_heartbeat ON volunteer_profiles(last_heartbeat_at);

-- ============================================
-- 13. 創建匹配統計視圖
-- ============================================

CREATE OR REPLACE VIEW matching_statistics AS
SELECT
    DATE_TRUNC('day', hr.created_at) AS date,
    COUNT(*) AS total_requests,
    COUNT(*) FILTER (WHERE hr.status = 'connected') AS matched_count,
    COUNT(*) FILTER (WHERE hr.status = 'async_pending') AS async_count,
    COUNT(*) FILTER (WHERE hr.status = 'cancelled') AS cancelled_count,
    AVG(EXTRACT(EPOCH FROM (hr.matched_at - hr.created_at))) FILTER (WHERE hr.status = 'connected') AS avg_match_time_seconds
FROM help_requests hr
GROUP BY DATE_TRUNC('day', hr.created_at)
ORDER BY date DESC;

-- ============================================
-- 14. 授予權限
-- ============================================

GRANT ALL ON help_request_matches TO authenticated;
GRANT ALL ON user_devices TO authenticated;
GRANT ALL ON user_presence TO authenticated;
GRANT ALL ON help_request_heartbeats TO authenticated;
GRANT SELECT ON matching_statistics TO authenticated;

-- 服務角色權限
GRANT ALL ON sos_broadcast_logs TO service_role;
GRANT EXECUTE ON FUNCTION get_volunteers_in_radius TO service_role;
GRANT EXECUTE ON FUNCTION update_volunteer_heartbeat TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_expired_matches TO service_role;

-- ============================================
-- 完成
-- ============================================

COMMENT ON TABLE help_request_matches IS '志願者匹配記錄表';
COMMENT ON TABLE user_devices IS '用戶設備表，用於FCM推送';
COMMENT ON TABLE sos_broadcast_logs IS 'SOS廣播日誌表';
COMMENT ON TABLE user_presence IS '用戶在線狀態表';
COMMENT ON TABLE help_request_heartbeats IS '求助會話心跳錶';
