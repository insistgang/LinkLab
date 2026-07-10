-- =====================================================
-- 共感 LinkAble 数据库索引优化脚本
-- =====================================================

-- =====================================================
-- 1. users 用户表索引
-- =====================================================

-- 手机号查询索引(用于登录)
CREATE INDEX idx_users_phone ON users(phone) WHERE is_deleted = FALSE;

-- 角色数组GIN索引(用于按角色筛选)
CREATE INDEX idx_users_role ON users USING GIN(role) WHERE is_deleted = FALSE;

-- 障碍类型数组GIN索引
CREATE INDEX idx_users_disability ON users USING GIN(disability_type) WHERE is_deleted = FALSE;

-- 创建时间索引(用于排序)
CREATE INDEX idx_users_created_at ON users(created_at DESC) WHERE is_deleted = FALSE;

-- 最后登录时间索引(用于活跃度分析)
CREATE INDEX idx_users_last_login ON users(last_login_at DESC) WHERE is_deleted = FALSE;

-- =====================================================
-- 2. volunteer_profiles 志愿者扩展表索引
-- =====================================================

-- 地理位置GIST索引(用于附近志愿者查询) - 最关键索引
CREATE INDEX idx_volunteer_location ON volunteer_profiles USING GIST(location)
    WHERE is_online = TRUE AND is_verified = TRUE;

-- 在线状态组合索引(匹配查询用)
CREATE INDEX idx_volunteer_online ON volunteer_profiles(is_online, is_verified, last_heartbeat_at DESC)
    WHERE is_online = TRUE;

-- 技能标签GIN索引(用于技能匹配)
CREATE INDEX idx_volunteer_skills ON volunteer_profiles USING GIN(skills);

-- 信用分排序索引
CREATE INDEX idx_volunteer_credit ON volunteer_profiles(credit_score DESC, points DESC)
    WHERE is_verified = TRUE;

-- 等级索引(用于等级筛选)
CREATE INDEX idx_volunteer_level ON volunteer_profiles(level DESC)
    WHERE is_verified = TRUE;

-- 累计帮助次数索引(用于排序)
CREATE INDEX idx_volunteer_help_count ON volunteer_profiles(total_help_count DESC);

-- 心跳时间索引(用于清理离线用户)
CREATE INDEX idx_volunteer_heartbeat ON volunteer_profiles(last_heartbeat_at)
    WHERE is_online = TRUE;

-- =====================================================
-- 3. help_requests 求助记录表索引
-- =====================================================

-- 求助者ID+创建时间复合索引(用于查询用户的求助历史)
CREATE INDEX idx_help_seeker ON help_requests(seeker_id, created_at DESC);

-- 志愿者ID+创建时间复合索引(用于查询志愿者的帮助历史)
CREATE INDEX idx_help_volunteer ON help_requests(volunteer_id, created_at DESC)
    WHERE volunteer_id IS NOT NULL;

-- 状态+紧急程度复合索引(用于匹配查询)
CREATE INDEX idx_help_status_urgency ON help_requests(status, urgency, created_at DESC);

-- 状态+类型复合索引(用于统计)
CREATE INDEX idx_help_status_type ON help_requests(status, type);

-- 地理位置GIST索引(用于附近求助查询)
CREATE INDEX idx_help_location ON help_requests USING GIST(location)
    WHERE status IN ('pending', 'matching');

-- 创建时间索引(用于排序和分页)
CREATE INDEX idx_help_created_at ON help_requests(created_at DESC);

-- 匹配时间索引(用于KPI统计)
CREATE INDEX idx_help_matched_at ON help_requests(matched_at)
    WHERE matched_at IS NOT NULL;

-- 完成时间索引(用于统计)
CREATE INDEX idx_help_completed_at ON help_requests(completed_at)
    WHERE completed_at IS NOT NULL;

-- AI已解决的状态索引
CREATE INDEX idx_help_ai_resolved ON help_requests(status, created_at DESC)
    WHERE status = 'ai_resolved';

-- =====================================================
-- 4. async_tasks 异步任务表索引
-- =====================================================

-- 状态+创建时间复合索引(用于任务队列查询)
CREATE INDEX idx_async_status ON async_tasks(status, created_at)
    WHERE status = 'pending';

-- 志愿者ID索引(用于查询志愿者的任务)
CREATE INDEX idx_async_volunteer ON async_tasks(volunteer_id, status, created_at DESC)
    WHERE volunteer_id IS NOT NULL;

-- 求助者ID索引
CREATE INDEX idx_async_seeker ON async_tasks(seeker_id, created_at DESC);

-- 截止时间索引(用于过期检测)
CREATE INDEX idx_async_deadline ON async_tasks(deadline_at)
    WHERE status IN ('pending', 'accepted', 'processing');

-- 任务类型索引(用于分类查询)
CREATE INDEX idx_async_type ON async_tasks(type, status);

-- =====================================================
-- 5. point_transactions 积分流水表索引
-- =====================================================

-- 用户ID+创建时间复合索引(用于查询积分历史)
CREATE INDEX idx_points_user ON point_transactions(user_id, created_at DESC);

-- 来源类型索引(用于统计)
CREATE INDEX idx_points_source ON point_transactions(source, created_at DESC);

-- 类型索引(用于分类统计)
CREATE INDEX idx_points_type ON point_transactions(type, created_at DESC);

-- =====================================================
-- 6. emergency_contacts 紧急联系人表索引
-- =====================================================

-- 用户ID+优先级复合索引
CREATE INDEX idx_emergency_user ON emergency_contacts(user_id, priority)
    WHERE is_active = TRUE;

-- =====================================================
-- 7. ai_response_cache AI缓存表索引
-- =====================================================

-- 过期时间索引(用于清理过期缓存)
CREATE INDEX idx_cache_expires ON ai_response_cache(expires_at)
    WHERE expires_at < NOW();

-- 查询类型索引(用于统计)
CREATE INDEX idx_cache_type ON ai_response_cache(query_type, hit_count DESC);

-- =====================================================
-- 8. reports 举报表索引
-- =====================================================

-- 状态索引(用于待处理举报列表)
CREATE INDEX idx_reports_status ON reports(status, created_at DESC)
    WHERE status = 'pending';

-- 被举报者索引
CREATE INDEX idx_reports_reported ON reports(reported_id, created_at DESC);

-- 举报者索引
CREATE INDEX idx_reports_reporter ON reports(reporter_id, created_at DESC);

-- =====================================================
-- 9. call_records 通话记录表索引
-- =====================================================

-- 求助记录ID索引
CREATE INDEX idx_call_request ON call_records(request_id);

-- 求助者ID索引
CREATE INDEX idx_call_seeker ON call_records(seeker_id, started_at DESC);

-- 志愿者ID索引
CREATE INDEX idx_call_volunteer ON call_records(volunteer_id, started_at DESC);

-- 通话状态索引
CREATE INDEX idx_call_status ON call_records(status, created_at DESC);

-- 通话质量索引(用于分析)
CREATE INDEX idx_call_quality ON call_records(quality_score)
    WHERE quality_score IS NOT NULL;

-- =====================================================
-- 统计信息更新(用于查询优化器)
-- =====================================================
ANALYZE users;
ANALYZE volunteer_profiles;
ANALYZE help_requests;
ANALYZE async_tasks;
ANALYZE point_transactions;
ANALYZE emergency_contacts;
ANALYZE ai_response_cache;
ANALYZE reports;
ANALYZE call_records;
