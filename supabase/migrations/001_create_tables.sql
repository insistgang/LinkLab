-- =====================================================
-- 共感 LinkAble 数据库初始化脚本
-- 创建核心表结构
-- =====================================================

-- 启用PostGIS扩展（用于地理坐标）
CREATE EXTENSION IF NOT EXISTS postgis;

-- =====================================================
-- 1. users 用户基础表
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone TEXT UNIQUE,                          -- 手机号登录
    name TEXT,                                  -- 昵称
    avatar_url TEXT,                            -- 头像URL
    role TEXT[] DEFAULT '{}',                   -- ['seeker', 'volunteer'] 可双角色
    disability_type TEXT[] DEFAULT '{}',        -- ['visual', 'hearing', 'physical', 'elderly', 'temporary']
    preferences JSONB DEFAULT '{}',             -- 无障碍偏好配置
    last_login_at TIMESTAMPTZ,                  -- 最后登录时间
    is_deleted BOOLEAN DEFAULT FALSE,           -- 软删除标记
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE users IS '用户基础表';
COMMENT ON COLUMN users.role IS '用户角色数组，支持seeker(求助者)和volunteer(志愿者)双角色';
COMMENT ON COLUMN users.disability_type IS '障碍类型：visual(视障), hearing(听障), physical(肢体), elderly(老年), temporary(临时)';
COMMENT ON COLUMN users.preferences IS '无障碍偏好配置，如字体大小、高对比度、语音速度等';

-- =====================================================
-- 2. volunteer_profiles 志愿者扩展表
-- =====================================================
CREATE TABLE volunteer_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    skills TEXT[] DEFAULT '{}',                 -- 技能标签数组
    level INT DEFAULT 1 CHECK (level >= 1 AND level <= 7),  -- 等级 1-7
    points INT DEFAULT 0,                       -- 积分
    credit_score DECIMAL(2,1) DEFAULT 5.0 CHECK (credit_score >= 1.0 AND credit_score <= 5.0),  -- 信用分 1-5
    is_verified BOOLEAN DEFAULT FALSE,          -- 实名认证
    available_schedule JSONB DEFAULT '{}',      -- 排班配置
    is_online BOOLEAN DEFAULT FALSE,            -- 在线状态
    last_heartbeat_at TIMESTAMPTZ,              -- 最后心跳时间
    total_help_count INT DEFAULT 0,             -- 累计帮助次数
    location GEOGRAPHY(POINT,4326),             -- PostGIS地理坐标(WGS84)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE volunteer_profiles IS '志愿者扩展表';
COMMENT ON COLUMN volunteer_profiles.skills IS '技能标签：medical(医疗), guide(导盲), tech(技术), sign(手语), elderly(敬老), child(儿童), daily(日常)';
COMMENT ON COLUMN volunteer_profiles.level IS '志愿者等级1-7，根据积分自动计算';
COMMENT ON COLUMN volunteer_profiles.available_schedule IS '可服务时间段配置';
COMMENT ON COLUMN volunteer_profiles.location IS '实时位置坐标，仅在匹配时对其他用户可见';

-- =====================================================
-- 3. help_requests 求助记录表
-- =====================================================
CREATE TABLE help_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seeker_id UUID NOT NULL REFERENCES users(id),
    type TEXT NOT NULL CHECK (type IN ('ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos')),
    intent TEXT,                                -- AI识别的意图
    urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('normal', 'important', 'urgent', 'emergency')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'ai_resolved', 'matching', 'matched', 'connected', 'completed', 'cancelled')),
    ai_response JSONB DEFAULT '{}',             -- AI处理结果缓存
    volunteer_id UUID REFERENCES users(id),     -- 匹配的志愿者
    location GEOGRAPHY(POINT,4326),             -- 求助位置
    duration_seconds INT,                       -- 通话时长(秒)
    seeker_rating INT CHECK (seeker_rating >= 1 AND seeker_rating <= 5),
    volunteer_rating INT CHECK (volunteer_rating >= 1 AND volunteer_rating <= 5),
    seeker_feedback TEXT,                       -- 求助者评价内容
    volunteer_feedback TEXT,                    -- 志愿者评价内容
    cancel_reason TEXT,                         -- 取消原因
    matched_at TIMESTAMPTZ,                     -- 匹配成功时间
    completed_at TIMESTAMPTZ,                   -- 完成时间
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE help_requests IS '求助记录表';
COMMENT ON COLUMN help_requests.type IS '求助类型：ai_auto(AI自动), async(异步), realtime_voice(实时语音), realtime_video(实时视频), sos(紧急)';
COMMENT ON COLUMN help_requests.urgency IS '紧急程度：normal(普通), important(重要), urgent(紧急), emergency(危急)';
COMMENT ON COLUMN help_requests.status IS '状态：pending(待处理), ai_resolved(AI已解决), matching(匹配中), matched(已匹配), connected(通话中), completed(已完成), cancelled(已取消)';

-- =====================================================
-- 4. async_tasks 异步任务表
-- =====================================================
CREATE TABLE async_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES help_requests(id) ON DELETE CASCADE,
    seeker_id UUID NOT NULL REFERENCES users(id),
    volunteer_id UUID REFERENCES users(id),     -- 接单的志愿者
    title TEXT NOT NULL,                        -- 任务标题
    description TEXT,                           -- 任务描述
    type TEXT NOT NULL CHECK (type IN ('ocr', 'scene_desc', 'translation', 'guidance', 'other')),
    attachments JSONB DEFAULT '[]',             -- 附件列表(图片等)
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'processing', 'completed', 'cancelled', 'expired')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    result TEXT,                                -- 处理结果
    result_attachments JSONB DEFAULT '[]',      -- 结果附件
    deadline_at TIMESTAMPTZ,                    -- 截止时间
    accepted_at TIMESTAMPTZ,                    -- 接单时间
    completed_at TIMESTAMPTZ,                   -- 完成时间
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE async_tasks IS '异步任务表';
COMMENT ON COLUMN async_tasks.type IS '任务类型：ocr(文字识别), scene_desc(场景描述), translation(翻译), guidance(导航指引), other(其他)';
COMMENT ON COLUMN async_tasks.status IS '状态：pending(待接单), accepted(已接单), processing(处理中), completed(已完成), cancelled(已取消), expired(已过期)';

-- =====================================================
-- 5. point_transactions 积分流水表
-- =====================================================
CREATE TABLE point_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type TEXT NOT NULL CHECK (type IN ('earn', 'spend', 'bonus', 'penalty')),
    amount INT NOT NULL,                        -- 积分变化量(正数增加，负数减少)
    balance INT NOT NULL,                       -- 变动后余额
    source TEXT NOT NULL,                       -- 来源：help_complete, task_complete, sign_in, exchange等
    source_id UUID,                             -- 关联记录ID
    description TEXT,                           -- 描述
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE point_transactions IS '积分流水表';
COMMENT ON COLUMN point_transactions.type IS '类型：earn(获得), spend(消耗), bonus(奖励), penalty(扣除)';
COMMENT ON COLUMN point_transactions.source IS '积分来源：help_complete(帮助完成), task_complete(任务完成), sign_in(签到), exchange(兑换), system(系统)等';

-- =====================================================
-- 6. emergency_contacts 紧急联系人表
-- =====================================================
CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,                         -- 联系人姓名
    phone TEXT NOT NULL,                        -- 联系人电话
    relationship TEXT,                          -- 关系
    priority INT DEFAULT 1,                     -- 优先级(1最高)
    is_active BOOLEAN DEFAULT TRUE,             -- 是否启用
    notify_on_sos BOOLEAN DEFAULT TRUE,         -- SOS时是否通知
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE emergency_contacts IS '紧急联系人表';

-- =====================================================
-- 7. ai_response_cache AI响应缓存表
-- =====================================================
CREATE TABLE ai_response_cache (
    query_hash TEXT PRIMARY KEY,                -- 查询内容哈希
    query_type TEXT NOT NULL,                   -- 查询类型
    response JSONB NOT NULL,                    -- 缓存结果
    hit_count INT DEFAULT 1,                    -- 命中次数
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL             -- 过期时间
);

COMMENT ON TABLE ai_response_cache IS 'AI响应缓存表，用于降低API调用成本';

-- =====================================================
-- 8. reports 举报表
-- =====================================================
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id),
    reported_id UUID NOT NULL REFERENCES users(id),
    target_type TEXT NOT NULL CHECK (target_type IN ('user', 'help_request', 'task')),
    target_id UUID NOT NULL,                    -- 被举报对象ID
    reason TEXT NOT NULL,                       -- 举报原因
    description TEXT,                           -- 详细描述
    evidence JSONB DEFAULT '[]',                -- 证据附件
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'resolved', 'rejected')),
    result TEXT,                                -- 处理结果
    handled_by UUID REFERENCES users(id),       -- 处理人
    handled_at TIMESTAMPTZ,                     -- 处理时间
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE reports IS '举报表';
COMMENT ON COLUMN reports.target_type IS '举报对象类型：user(用户), help_request(求助), task(任务)';

-- =====================================================
-- 9. call_records 通话记录表(用于WebRTC信令和记录)
-- =====================================================
CREATE TABLE call_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES help_requests(id),
    seeker_id UUID NOT NULL REFERENCES users(id),
    volunteer_id UUID NOT NULL REFERENCES users(id),
    call_type TEXT NOT NULL CHECK (call_type IN ('voice', 'video')),
    status TEXT DEFAULT 'initiating' CHECK (status IN ('initiating', 'ringing', 'connected', 'ended', 'failed')),
    started_at TIMESTAMPTZ,                     -- 通话开始时间
    ended_at TIMESTAMPTZ,                       -- 通话结束时间
    duration_seconds INT,                       -- 通话时长
    end_reason TEXT,                            -- 结束原因
    ice_candidate_count INT,                    -- ICE候选数量(用于质量分析)
    quality_score INT CHECK (quality_score >= 1 AND quality_score <= 5),  -- 通话质量评分
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE call_records IS '通话记录表';

-- =====================================================
-- 创建更新时间触发器函数
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为需要自动更新updated_at的表创建触发器
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_volunteer_profiles_updated_at BEFORE UPDATE ON volunteer_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_help_requests_updated_at BEFORE UPDATE ON help_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_async_tasks_updated_at BEFORE UPDATE ON async_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_contacts_updated_at BEFORE UPDATE ON emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
