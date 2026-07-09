-- ============================================
-- 用户中心和成长体系数据库表结构
-- ============================================

-- 用户签到表
CREATE TABLE IF NOT EXISTS user_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    checkin_date DATE NOT NULL,
    consecutive_days INTEGER DEFAULT 1,
    points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, checkin_date)
);

-- 积分交易记录表
CREATE TABLE IF NOT EXISTS point_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    type VARCHAR(50) NOT NULL, -- dailyCheckIn, weeklyBonus, monthlyBonus, realtimeHelp, asyncHelp, fiveStarRating, continuousHelpBonus, penalty, etc.
    description TEXT,
    related_id UUID, -- 关联的帮助请求ID等
    is_positive BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 志愿者档案表
CREATE TABLE IF NOT EXISTS volunteer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    level INTEGER DEFAULT 1,
    points INTEGER DEFAULT 0,
    credit_score DECIMAL(3,2) DEFAULT 5.00,
    is_verified BOOLEAN DEFAULT false,
    is_online BOOLEAN DEFAULT false,
    last_heartbeat_at TIMESTAMPTZ,
    total_help_count INTEGER DEFAULT 0,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 志愿者技能表
CREATE TABLE IF NOT EXISTS volunteer_skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    volunteer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(volunteer_id, skill_id)
);

-- 技能认证申请表
CREATE TABLE IF NOT EXISTS skill_verification_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    volunteer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    skill_id VARCHAR(50) NOT NULL,
    skill_name VARCHAR(100),
    certificate_url TEXT,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
    reviewer_note TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ
);

-- 常用志愿者表
CREATE TABLE IF NOT EXISTS favorite_volunteers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seeker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    volunteer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cooperation_count INTEGER DEFAULT 1,
    average_rating DECIMAL(2,1),
    last_cooperation_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(seeker_id, volunteer_id)
);

-- 徽章表
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- translator, helper100, helper500, helper1000, newYear, springFestival, lighthouse, continuous7, continuous30, skillMaster, risingStar, kindHeart, other
    name VARCHAR(100) NOT NULL,
    icon_url TEXT,
    description TEXT,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    is_new BOOLEAN DEFAULT true,
    UNIQUE(user_id, type)
);

-- 善意时间线表
CREATE TABLE IF NOT EXISTS volunteer_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    volunteer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    help_count INTEGER DEFAULT 0,
    minutes INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(volunteer_id, date)
);

-- 时间线事件表
CREATE TABLE IF NOT EXISTS timeline_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timeline_id UUID NOT NULL REFERENCES volunteer_timeline(id) ON DELETE CASCADE,
    help_request_id UUID,
    seeker_name VARCHAR(100),
    duration_minutes INTEGER,
    rating INTEGER,
    thank_you_note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 排班表
CREATE TABLE IF NOT EXISTS volunteer_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weekly_schedule JSONB DEFAULT '{}', -- {monday: [{start: '09:00', end: '12:00'}], ...}
    is_online BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'offline', -- online, offline, busy
    last_status_update_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 异步任务表
CREATE TABLE IF NOT EXISTS async_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    help_request_id UUID REFERENCES help_requests(id) ON DELETE CASCADE,
    seeker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    volunteer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    task_type VARCHAR(50) NOT NULL, -- ocr, translation, description, navigation, etc.
    description TEXT NOT NULL,
    image_url TEXT,
    status VARCHAR(20) DEFAULT 'pending', -- pending, assigned, processing, completed, cancelled
    result TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    assigned_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- ============================================
-- 创建索引
-- ============================================

CREATE INDEX IF NOT EXISTS idx_user_checkins_user_id ON user_checkins(user_id);
CREATE INDEX IF NOT EXISTS idx_user_checkins_date ON user_checkins(checkin_date);

CREATE INDEX IF NOT EXISTS idx_point_transactions_user_id ON point_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_point_transactions_type ON point_transactions(type);
CREATE INDEX IF NOT EXISTS idx_point_transactions_created_at ON point_transactions(created_at);

CREATE INDEX IF NOT EXISTS idx_volunteer_profiles_user_id ON volunteer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_profiles_is_online ON volunteer_profiles(is_online);
CREATE INDEX IF NOT EXISTS idx_volunteer_profiles_level ON volunteer_profiles(level);

CREATE INDEX IF NOT EXISTS idx_volunteer_skills_volunteer_id ON volunteer_skills(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_skills_skill_id ON volunteer_skills(skill_id);

CREATE INDEX IF NOT EXISTS idx_favorite_volunteers_seeker_id ON favorite_volunteers(seeker_id);
CREATE INDEX IF NOT EXISTS idx_favorite_volunteers_volunteer_id ON favorite_volunteers(volunteer_id);

CREATE INDEX IF NOT EXISTS idx_badges_user_id ON badges(user_id);
CREATE INDEX IF NOT EXISTS idx_badges_type ON badges(type);

CREATE INDEX IF NOT EXISTS idx_volunteer_timeline_volunteer_id ON volunteer_timeline(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_timeline_date ON volunteer_timeline(date);

CREATE INDEX IF NOT EXISTS idx_timeline_events_timeline_id ON timeline_events(timeline_id);

CREATE INDEX IF NOT EXISTS idx_volunteer_schedules_user_id ON volunteer_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_volunteer_schedules_is_online ON volunteer_schedules(is_online);

CREATE INDEX IF NOT EXISTS idx_async_tasks_seeker_id ON async_tasks(seeker_id);
CREATE INDEX IF NOT EXISTS idx_async_tasks_volunteer_id ON async_tasks(volunteer_id);
CREATE INDEX IF NOT EXISTS idx_async_tasks_status ON async_tasks(status);

-- ============================================
-- 创建RLS策略
-- ============================================

ALTER TABLE user_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE point_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_timeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE volunteer_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE async_tasks ENABLE ROW LEVEL SECURITY;

-- 用户签到表策略
CREATE POLICY user_checkins_select ON user_checkins
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY user_checkins_insert ON user_checkins
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 积分交易表策略
CREATE POLICY point_transactions_select ON point_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- 志愿者档案表策略
CREATE POLICY volunteer_profiles_select ON volunteer_profiles
    FOR SELECT USING (true); -- 公开查询

CREATE POLICY volunteer_profiles_update_own ON volunteer_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY volunteer_profiles_insert_own ON volunteer_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 志愿者技能表策略
CREATE POLICY volunteer_skills_select ON volunteer_skills
    FOR SELECT USING (true);

CREATE POLICY volunteer_skills_update_own ON volunteer_skills
    FOR UPDATE USING (auth.uid() = volunteer_id);

CREATE POLICY volunteer_skills_insert_own ON volunteer_skills
    FOR INSERT WITH CHECK (auth.uid() = volunteer_id);

-- 技能认证申请表策略
CREATE POLICY skill_verification_requests_select ON skill_verification_requests
    FOR SELECT USING (auth.uid() = volunteer_id);

CREATE POLICY skill_verification_requests_insert_own ON skill_verification_requests
    FOR INSERT WITH CHECK (auth.uid() = volunteer_id);

-- 常用志愿者表策略
CREATE POLICY favorite_volunteers_select ON favorite_volunteers
    FOR SELECT USING (auth.uid() = seeker_id);

CREATE POLICY favorite_volunteers_insert_own ON favorite_volunteers
    FOR INSERT WITH CHECK (auth.uid() = seeker_id);

CREATE POLICY favorite_volunteers_delete_own ON favorite_volunteers
    FOR DELETE USING (auth.uid() = seeker_id);

-- 徽章表策略
CREATE POLICY badges_select ON badges
    FOR SELECT USING (true);

-- 时间线表策略
CREATE POLICY volunteer_timeline_select ON volunteer_timeline
    FOR SELECT USING (true);

-- 时间线事件表策略
CREATE POLICY timeline_events_select ON timeline_events
    FOR SELECT USING (true);

-- 排班表策略
CREATE POLICY volunteer_schedules_select ON volunteer_schedules
    FOR SELECT USING (true);

CREATE POLICY volunteer_schedules_update_own ON volunteer_schedules
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY volunteer_schedules_insert_own ON volunteer_schedules
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 异步任务表策略
CREATE POLICY async_tasks_select ON async_tasks
    FOR SELECT USING (
        auth.uid() = seeker_id OR
        auth.uid() = volunteer_id OR
        (status = 'pending' AND volunteer_id IS NULL)
    );

CREATE POLICY async_tasks_insert_own ON async_tasks
    FOR INSERT WITH CHECK (auth.uid() = seeker_id);

CREATE POLICY async_tasks_update_volunteer ON async_tasks
    FOR UPDATE USING (
        auth.uid() = volunteer_id OR
        (status = 'pending' AND volunteer_id IS NULL)
    );

-- ============================================
-- 创建RPC函数
-- ============================================

-- 添加用户积分（原子操作）
CREATE OR REPLACE FUNCTION add_user_points(
    p_user_id UUID,
    p_points INTEGER,
    p_type VARCHAR,
    p_description TEXT DEFAULT NULL,
    p_related_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- 插入交易记录
    INSERT INTO point_transactions (user_id, points, type, description, related_id, is_positive)
    VALUES (p_user_id, p_points, p_type, p_description, p_related_id, p_points > 0);

    -- 更新用户积分
    UPDATE users
    SET points = COALESCE(points, 0) + p_points
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 使用积分
CREATE OR REPLACE FUNCTION use_user_points(
    p_user_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT NULL,
    p_related_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_points INTEGER;
BEGIN
    -- 获取当前积分
    SELECT points INTO v_current_points FROM users WHERE id = p_user_id;

    -- 检查积分是否足够
    IF v_current_points < p_points THEN
        RETURN false;
    END IF;

    -- 插入交易记录
    INSERT INTO point_transactions (user_id, points, type, description, related_id, is_positive)
    VALUES (p_user_id, -p_points, 'other', p_description, p_related_id, false);

    -- 扣除积分
    UPDATE users
    SET points = points - p_points
    WHERE id = p_user_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 增加用户积分（简单版）
CREATE OR REPLACE FUNCTION increment_user_points(
    user_id UUID,
    points INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE users
    SET points = COALESCE(points, 0) + increment_user_points.points
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加志愿者积分
CREATE OR REPLACE FUNCTION add_volunteer_points(
    p_volunteer_id UUID,
    p_points INTEGER,
    p_type VARCHAR,
    p_description TEXT DEFAULT NULL,
    p_related_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    -- 插入交易记录
    INSERT INTO point_transactions (user_id, points, type, description, related_id, is_positive)
    VALUES (p_volunteer_id, p_points, p_type, p_description, p_related_id, p_points > 0);

    -- 更新志愿者积分
    UPDATE volunteer_profiles
    SET points = COALESCE(points, 0) + p_points
    WHERE user_id = p_volunteer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 增加志愿者积分（简单版）
CREATE OR REPLACE FUNCTION increment_volunteer_points(
    volunteer_id UUID,
    points INTEGER
)
RETURNS VOID AS $$
BEGIN
    UPDATE volunteer_profiles
    SET points = COALESCE(points, 0) + increment_volunteer_points.points
    WHERE user_id = volunteer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 检查并升级志愿者等级
CREATE OR REPLACE FUNCTION check_and_upgrade_volunteer_level(p_volunteer_id UUID)
RETURNS TABLE (
    old_level INTEGER,
    new_level INTEGER,
    upgraded BOOLEAN
) AS $$
DECLARE
    v_current_level INTEGER;
    v_current_points INTEGER;
    v_expected_level INTEGER;
BEGIN
    -- 获取当前等级和积分
    SELECT level, points INTO v_current_level, v_current_points
    FROM volunteer_profiles
    WHERE user_id = p_volunteer_id;

    -- 根据积分计算应达等级
    v_expected_level := CASE
        WHEN v_current_points >= 10000 THEN 7
        WHEN v_current_points >= 5000 THEN 6
        WHEN v_current_points >= 2000 THEN 5
        WHEN v_current_points >= 800 THEN 4
        WHEN v_current_points >= 300 THEN 3
        WHEN v_current_points >= 100 THEN 2
        ELSE 1
    END;

    -- 如果需要升级
    IF v_expected_level > v_current_level THEN
        UPDATE volunteer_profiles
        SET level = v_expected_level
        WHERE user_id = p_volunteer_id;

        RETURN QUERY SELECT v_current_level, v_expected_level, true;
    ELSE
        RETURN QUERY SELECT v_current_level, v_current_level, false;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 领取异步任务
CREATE OR REPLACE FUNCTION claim_async_task(
    p_task_id UUID,
    p_volunteer_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_status VARCHAR;
BEGIN
    -- 检查任务状态
    SELECT status INTO v_status FROM async_tasks WHERE id = p_task_id;

    IF v_status != 'pending' THEN
        RETURN false;
    END IF;

    -- 更新任务
    UPDATE async_tasks
    SET
        volunteer_id = p_volunteer_id,
        status = 'assigned',
        assigned_at = NOW()
    WHERE id = p_task_id AND status = 'pending';

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 完成异步任务
CREATE OR REPLACE FUNCTION complete_async_task(
    p_task_id UUID,
    p_result TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE async_tasks
    SET
        status = 'completed',
        result = p_result,
        completed_at = NOW()
    WHERE id = p_task_id AND status IN ('assigned', 'processing');

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 添加或更新常用志愿者
CREATE OR REPLACE FUNCTION upsert_favorite_volunteer(
    p_seeker_id UUID,
    p_volunteer_id UUID,
    p_rating INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_volunteer_name VARCHAR;
    v_existing_count INTEGER;
    v_existing_rating DECIMAL;
BEGIN
    -- 获取志愿者名称
    SELECT name INTO v_volunteer_name
    FROM users
    WHERE id = p_volunteer_id;

    -- 检查是否已存在
    SELECT cooperation_count, average_rating
    INTO v_existing_count, v_existing_rating
    FROM favorite_volunteers
    WHERE seeker_id = p_seeker_id AND volunteer_id = p_volunteer_id;

    IF v_existing_count IS NOT NULL THEN
        -- 更新
        UPDATE favorite_volunteers
        SET
            cooperation_count = v_existing_count + 1,
            average_rating = CASE
                WHEN p_rating IS NOT NULL THEN
                    (v_existing_rating * v_existing_count + p_rating) / (v_existing_count + 1)
                ELSE v_existing_rating
            END,
            last_cooperation_at = NOW()
        WHERE seeker_id = p_seeker_id AND volunteer_id = p_volunteer_id;
    ELSE
        -- 插入
        INSERT INTO favorite_volunteers (
            seeker_id,
            volunteer_id,
            volunteer_name,
            cooperation_count,
            average_rating,
            last_cooperation_at
        ) VALUES (
            p_seeker_id,
            p_volunteer_id,
            v_volunteer_name,
            1,
            p_rating,
            NOW()
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 授予徽章
CREATE OR REPLACE FUNCTION award_badge(
    p_user_id UUID,
    p_badge_type VARCHAR,
    p_badge_name VARCHAR,
    p_description TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO badges (user_id, type, name, description)
    VALUES (p_user_id, p_badge_type, p_badge_name, p_description)
    ON CONFLICT (user_id, type) DO NOTHING;

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 更新志愿者时间线
CREATE OR REPLACE FUNCTION update_volunteer_timeline(
    p_volunteer_id UUID,
    p_date DATE,
    p_minutes INTEGER,
    p_help_request_id UUID DEFAULT NULL,
    p_seeker_name VARCHAR DEFAULT NULL,
    p_rating INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_timeline_id UUID;
BEGIN
    -- 插入或更新时间线
    INSERT INTO volunteer_timeline (volunteer_id, date, help_count, minutes)
    VALUES (p_volunteer_id, p_date, 1, p_minutes)
    ON CONFLICT (volunteer_id, date)
    DO UPDATE SET
        help_count = volunteer_timeline.help_count + 1,
        minutes = volunteer_timeline.minutes + p_minutes,
        updated_at = NOW()
    RETURNING id INTO v_timeline_id;

    -- 如果没有返回id，查询获取
    IF v_timeline_id IS NULL THEN
        SELECT id INTO v_timeline_id
        FROM volunteer_timeline
        WHERE volunteer_id = p_volunteer_id AND date = p_date;
    END IF;

    -- 添加事件
    IF p_help_request_id IS NOT NULL THEN
        INSERT INTO timeline_events (
            timeline_id,
            help_request_id,
            seeker_name,
            duration_minutes,
            rating
        ) VALUES (
            v_timeline_id,
            p_help_request_id,
            p_seeker_name,
            p_minutes,
            p_rating
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 更新排班
CREATE OR REPLACE FUNCTION update_volunteer_schedule(
    p_user_id UUID,
    p_day VARCHAR,
    p_slots JSONB
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO volunteer_schedules (user_id, weekly_schedule)
    VALUES (p_user_id, jsonb_build_object(p_day, p_slots))
    ON CONFLICT (user_id)
    DO UPDATE SET
        weekly_schedule = volunteer_schedules.weekly_schedule || jsonb_build_object(p_day, p_slots),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 设置在线状态
CREATE OR REPLACE FUNCTION set_volunteer_online_status(
    p_user_id UUID,
    p_is_online BOOLEAN,
    p_status VARCHAR DEFAULT 'offline'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO volunteer_schedules (user_id, is_online, status, last_status_update_at)
    VALUES (p_user_id, p_is_online, p_status, NOW())
    ON CONFLICT (user_id)
    DO UPDATE SET
        is_online = p_is_online,
        status = p_status,
        last_status_update_at = NOW();

    -- 同时更新志愿者档案
    UPDATE volunteer_profiles
    SET
        is_online = p_is_online,
        last_heartbeat_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 获取志愿者统计数据
CREATE OR REPLACE FUNCTION get_volunteer_stats(p_volunteer_id UUID)
RETURNS TABLE (
    total_helps BIGINT,
    total_minutes BIGINT,
    average_rating DECIMAL,
    current_streak BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(help_count), 0)::BIGINT as total_helps,
        COALESCE(SUM(minutes), 0)::BIGINT as total_minutes,
        (SELECT AVG(rating::DECIMAL) FROM timeline_events te
         JOIN volunteer_timeline vt ON te.timeline_id = vt.id
         WHERE vt.volunteer_id = p_volunteer_id AND te.rating IS NOT NULL) as average_rating,
        (SELECT COUNT(*) FROM volunteer_timeline
         WHERE volunteer_id = p_volunteer_id
         AND date >= CURRENT_DATE - INTERVAL '7 days') as current_streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 获取求助者统计数据
CREATE OR REPLACE FUNCTION get_seeker_stats(p_seeker_id UUID)
RETURNS TABLE (
    total_requests BIGINT,
    ai_resolved_count BIGINT,
    volunteer_help_count BIGINT,
    sos_count BIGINT,
    total_duration_minutes BIGINT,
    average_rating DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::BIGINT as total_requests,
        COUNT(*) FILTER (WHERE status = 'ai_resolved')::BIGINT as ai_resolved_count,
        COUNT(*) FILTER (WHERE volunteer_id IS NOT NULL)::BIGINT as volunteer_help_count,
        COUNT(*) FILTER (WHERE type = 'sos')::BIGINT as sos_count,
        COALESCE(SUM(duration_seconds), 0)::BIGINT / 60 as total_duration_minutes,
        AVG(seeker_rating::DECIMAL) as average_rating
    FROM help_requests
    WHERE seeker_id = p_seeker_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 创建触发器
-- ============================================

-- 帮助请求完成后更新统计数据
CREATE OR REPLACE FUNCTION on_help_request_completed()
RETURNS TRIGGER AS $$
BEGIN
    -- 如果完成了且有志愿者
    IF NEW.status = 'completed' AND NEW.volunteer_id IS NOT NULL THEN
        -- 更新志愿者帮助次数
        UPDATE volunteer_profiles
        SET total_help_count = COALESCE(total_help_count, 0) + 1
        WHERE user_id = NEW.volunteer_id;

        -- 更新常用志愿者
        PERFORM upsert_favorite_volunteer(
            NEW.seeker_id,
            NEW.volunteer_id,
            NEW.seeker_rating
        );

        -- 更新时间线
        IF NEW.completed_at IS NOT NULL AND NEW.duration_seconds IS NOT NULL THEN
            PERFORM update_volunteer_timeline(
                NEW.volunteer_id,
                NEW.completed_at::DATE,
                NEW.duration_seconds / 60,
                NEW.id,
                (SELECT name FROM users WHERE id = NEW.seeker_id),
                NEW.seeker_rating
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_help_request_completed ON help_requests;
CREATE TRIGGER trigger_help_request_completed
    AFTER UPDATE ON help_requests
    FOR EACH ROW
    WHEN (OLD.status != 'completed' AND NEW.status = 'completed')
    EXECUTE FUNCTION on_help_request_completed();

-- 更新 updated_at 触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为相关表添加 updated_at 触发器
DROP TRIGGER IF EXISTS update_volunteer_profiles_updated_at ON volunteer_profiles;
CREATE TRIGGER update_volunteer_profiles_updated_at
    BEFORE UPDATE ON volunteer_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_volunteer_timeline_updated_at ON volunteer_timeline;
CREATE TRIGGER update_volunteer_timeline_updated_at
    BEFORE UPDATE ON volunteer_timeline
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_volunteer_schedules_updated_at ON volunteer_schedules;
CREATE TRIGGER update_volunteer_schedules_updated_at
    BEFORE UPDATE ON volunteer_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
