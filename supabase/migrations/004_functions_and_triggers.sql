-- =====================================================
-- 共感 LinkAble 數據庫函數和觸發器
-- =====================================================

-- =====================================================
-- 1. 輔助函數
-- =====================================================

-- 計算兩點間距離(米)
CREATE OR REPLACE FUNCTION calculate_distance(
    lat1 DECIMAL,
    lng1 DECIMAL,
    lat2 DECIMAL,
    lng2 DECIMAL
)
RETURNS DECIMAL AS $$
DECLARE
    R DECIMAL := 6371000; -- 地球半徑(米)
    dLat DECIMAL;
    dLng DECIMAL;
    a DECIMAL;
    c DECIMAL;
BEGIN
    dLat := RADIANS(lat2 - lat1);
    dLng := RADIANS(lng2 - lng1);
    a := SIN(dLat/2) * SIN(dLat/2) +
         COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
         SIN(dLng/2) * SIN(dLng/2);
    c := 2 * ATAN2(SQRT(a), SQRT(1-a));
    RETURN R * c;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 根據積分計算等級
CREATE OR REPLACE FUNCTION calculate_volunteer_level(points INT)
RETURNS INT AS $$
BEGIN
    RETURN CASE
        WHEN points >= 1200 THEN 7
        WHEN points >= 800 THEN 6
        WHEN points >= 500 THEN 5
        WHEN points >= 300 THEN 4
        WHEN points >= 150 THEN 3
        WHEN points >= 50 THEN 2
        ELSE 1
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 增加數值(用於觸發器)
CREATE OR REPLACE FUNCTION increment(x INT DEFAULT 1)
RETURNS INT AS $$
BEGIN
    RETURN x;
END;
$$ LANGUAGE plpgsql;

-- 增加緩存命中次數
CREATE OR REPLACE FUNCTION increment_cache_hit(hash TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE ai_response_cache
    SET hit_count = hit_count + 1
    WHERE query_hash = hash;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 匹配查詢函數
-- =====================================================

-- 查找匹配的志願者
CREATE OR REPLACE FUNCTION find_matching_volunteers(
    seeker_lat DECIMAL,
    seeker_lng DECIMAL,
    max_dist INT DEFAULT 50000,
    required_skills TEXT[] DEFAULT '{}',
    result_limit INT DEFAULT 10
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
            vp.location::geography,
            ST_SetSRID(ST_MakePoint(seeker_lng, seeker_lat), 4326)::geography
        )::DECIMAL as distance
    FROM volunteer_profiles vp
    JOIN users u ON u.id = vp.user_id
    WHERE
        vp.is_online = TRUE
        AND vp.is_verified = TRUE
        AND ST_DWithin(
            vp.location::geography,
            ST_SetSRID(ST_MakePoint(seeker_lng, seeker_lat), 4326)::geography,
            max_dist
        )
        AND (array_length(required_skills, 1) IS NULL OR vp.skills && required_skills)
        AND u.is_deleted = FALSE
    ORDER BY
        vp.credit_score DESC,
        distance ASC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 觸發器函數
-- =====================================================

-- 更新志願者等級
CREATE OR REPLACE FUNCTION update_volunteer_level()
RETURNS TRIGGER AS $$
BEGIN
    NEW.level := calculate_volunteer_level(NEW.points);
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建觸發器：積分變化時更新等級
CREATE TRIGGER trigger_update_volunteer_level
    BEFORE UPDATE OF points ON volunteer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_volunteer_level();

-- 更新用戶最後登錄時間
CREATE OR REPLACE FUNCTION update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_login_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 求助記錄狀態變更日誌
CREATE OR REPLACE FUNCTION log_help_request_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 記錄狀態變更到日誌表(如果存在)
    IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO help_request_logs (
            request_id,
            old_status,
            new_status,
            changed_at
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建日誌表
CREATE TABLE IF NOT EXISTS help_request_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID REFERENCES help_requests(id),
    old_status TEXT,
    new_status TEXT,
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 創建觸發器
CREATE TRIGGER trigger_log_help_request_change
    AFTER UPDATE ON help_requests
    FOR EACH ROW
    EXECUTE FUNCTION log_help_request_change();

-- =====================================================
-- 4. 積分計算觸發器
-- =====================================================

-- 求助完成後計算積分
CREATE OR REPLACE FUNCTION calculate_help_points()
RETURNS TRIGGER AS $$
DECLARE
    points_to_add INT := 0;
    duration_min INT;
BEGIN
    -- 只處理狀態變爲completed的情況
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- 基礎積分
        IF NEW.type = 'sos' THEN
            points_to_add := 20;
        ELSIF NEW.type IN ('realtime_voice', 'realtime_video') THEN
            points_to_add := 10;
        ELSE
            points_to_add := 5;
        END IF;

        -- 時長獎勵
        IF NEW.duration_seconds IS NOT NULL THEN
            duration_min := NEW.duration_seconds / 60;
            IF duration_min >= 30 THEN
                points_to_add := points_to_add + 25;
            ELSIF duration_min >= 15 THEN
                points_to_add := points_to_add + 15;
            ELSIF duration_min >= 10 THEN
                points_to_add := points_to_add + 10;
            ELSIF duration_min >= 5 THEN
                points_to_add := points_to_add + 5;
            END IF;
        END IF;

        -- 評價獎勵
        IF NEW.seeker_rating IS NOT NULL THEN
            points_to_add := points_to_add + CASE NEW.seeker_rating
                WHEN 5 THEN 10
                WHEN 4 THEN 5
                WHEN 3 THEN 2
                WHEN 2 THEN 0
                WHEN 1 THEN -5
                ELSE 0
            END;
        END IF;

        -- 插入積分流水
        IF points_to_add > 0 AND NEW.volunteer_id IS NOT NULL THEN
            INSERT INTO point_transactions (
                user_id,
                type,
                amount,
                balance,
                source,
                source_id,
                description
            )
            SELECT
                NEW.volunteer_id,
                'earn',
                points_to_add,
                COALESCE((SELECT points FROM volunteer_profiles WHERE user_id = NEW.volunteer_id), 0) + points_to_add,
                'help_complete',
                NEW.id,
                '完成幫助獲得積分'
            WHERE EXISTS (SELECT 1 FROM volunteer_profiles WHERE user_id = NEW.volunteer_id);

            -- 更新志願者積分和累計幫助次數
            UPDATE volunteer_profiles
            SET
                points = points + points_to_add,
                total_help_count = total_help_count + 1
            WHERE user_id = NEW.volunteer_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建觸發器
CREATE TRIGGER trigger_calculate_help_points
    AFTER UPDATE ON help_requests
    FOR EACH ROW
    EXECUTE FUNCTION calculate_help_points();

-- =====================================================
-- 5. 異步任務積分計算
-- =====================================================

CREATE OR REPLACE FUNCTION calculate_async_task_points()
RETURNS TRIGGER AS $$
DECLARE
    points_to_add INT := 5;
BEGIN
    -- 只處理狀態變爲completed的情況
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        -- 優先級獎勵
        points_to_add := points_to_add + CASE NEW.priority
            WHEN 'urgent' THEN 10
            WHEN 'high' THEN 5
            WHEN 'normal' THEN 2
            ELSE 0
        END;

        -- 插入積分流水
        IF points_to_add > 0 AND NEW.volunteer_id IS NOT NULL THEN
            INSERT INTO point_transactions (
                user_id,
                type,
                amount,
                balance,
                source,
                source_id,
                description
            )
            SELECT
                NEW.volunteer_id,
                'earn',
                points_to_add,
                COALESCE((SELECT points FROM volunteer_profiles WHERE user_id = NEW.volunteer_id), 0) + points_to_add,
                'task_complete',
                NEW.id,
                '完成異步任務獲得積分'
            WHERE EXISTS (SELECT 1 FROM volunteer_profiles WHERE user_id = NEW.volunteer_id);

            -- 更新志願者積分
            UPDATE volunteer_profiles
            SET points = points + points_to_add
            WHERE user_id = NEW.volunteer_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 創建觸發器
CREATE TRIGGER trigger_calculate_async_task_points
    AFTER UPDATE ON async_tasks
    FOR EACH ROW
    EXECUTE FUNCTION calculate_async_task_points();

-- =====================================================
-- 6. 清理過期緩存的定時任務函數
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_expired_cache()
RETURNS VOID AS $$
BEGIN
    DELETE FROM ai_response_cache
    WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 視圖
-- =====================================================

-- 志願者統計視圖
CREATE OR REPLACE VIEW volunteer_stats AS
SELECT
    vp.user_id,
    u.name,
    vp.level,
    vp.points,
    vp.credit_score,
    vp.total_help_count,
    vp.is_online,
    vp.is_verified,
    COUNT(DISTINCT hr.id) FILTER (WHERE hr.status = 'completed') as completed_helps,
    COALESCE(AVG(hr.seeker_rating) FILTER (WHERE hr.status = 'completed'), 0) as avg_rating
FROM volunteer_profiles vp
JOIN users u ON u.id = vp.user_id
LEFT JOIN help_requests hr ON hr.volunteer_id = vp.user_id
WHERE u.is_deleted = FALSE
GROUP BY vp.user_id, u.name, vp.level, vp.points, vp.credit_score, vp.total_help_count, vp.is_online, vp.is_verified;

-- 求助統計視圖
CREATE OR REPLACE VIEW help_request_stats AS
SELECT
    DATE(created_at) as date,
    type,
    urgency,
    status,
    COUNT(*) as count,
    AVG(duration_seconds) FILTER (WHERE duration_seconds IS NOT NULL) as avg_duration,
    AVG(seeker_rating) FILTER (WHERE seeker_rating IS NOT NULL) as avg_rating
FROM help_requests
GROUP BY DATE(created_at), type, urgency, status;

-- =====================================================
-- 8. 初始化數據(可選)
-- =====================================================

-- 創建系統用戶(用於系統操作)
INSERT INTO users (id, phone, name, role, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'system',
    '系統',
    ARRAY['system'],
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 添加RLS策略排除系統用戶
CREATE POLICY system_user_bypass ON users
    FOR ALL
    USING (id = '00000000-0000-0000-0000-000000000000')
    WITH CHECK (id = '00000000-0000-0000-0000-000000000000');
