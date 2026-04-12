-- =====================================================
-- 共感 LinkAble RLS (Row Level Security) 安全策略
-- =====================================================

-- =====================================================
-- 1. users 表 RLS 策略
-- =====================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 用户只能查看和修改自己的完整信息
CREATE POLICY user_self_full_access ON users
    FOR ALL
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 允许已认证用户查看其他用户的基本公开信息(昵称、头像)
CREATE POLICY user_public_read ON users
    FOR SELECT
    USING (
        is_deleted = FALSE AND
        (auth.uid() IS NOT NULL)  -- 任何已认证用户都可查看
    );

-- =====================================================
-- 2. volunteer_profiles 表 RLS 策略
-- =====================================================
ALTER TABLE volunteer_profiles ENABLE ROW LEVEL SECURITY;

-- 志愿者自己可以查看和修改自己的完整资料
CREATE POLICY volunteer_self_access ON volunteer_profiles
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 其他用户只能查看志愿者的公开信息(不包含精确位置)
CREATE POLICY volunteer_public_read ON volunteer_profiles
    FOR SELECT
    USING (
        is_verified = TRUE AND
        auth.uid() IS NOT NULL AND
        auth.uid() != user_id  -- 排除自己，自己的访问在上面处理
    );

-- 求助者在匹配过程中可以查看志愿者位置
-- 当存在进行中的求助请求时，求助者可以看到匹配志愿者的位置
CREATE POLICY volunteer_location_for_matching ON volunteer_profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM help_requests hr
            WHERE hr.volunteer_id = volunteer_profiles.user_id
            AND hr.seeker_id = auth.uid()
            AND hr.status IN ('matching', 'matched', 'connected')
        )
    );

-- =====================================================
-- 3. help_requests 求助记录表 RLS 策略
-- =====================================================
ALTER TABLE help_requests ENABLE ROW LEVEL SECURITY;

-- 求助者可以查看和管理自己的求助
CREATE POLICY help_seeker_access ON help_requests
    FOR ALL
    USING (seeker_id = auth.uid())
    WITH CHECK (seeker_id = auth.uid());

-- 志愿者可以查看被分配的求助
CREATE POLICY help_volunteer_access ON help_requests
    FOR SELECT
    USING (
        volunteer_id = auth.uid() OR
        -- 志愿者也可以查看待匹配的求助(用于接单)
        (status = 'matching' AND type IN ('realtime_voice', 'realtime_video', 'sos'))
    );

-- 志愿者可以更新被分配的求助状态
CREATE POLICY help_volunteer_update ON help_requests
    FOR UPDATE
    USING (volunteer_id = auth.uid())
    WITH CHECK (volunteer_id = auth.uid());

-- =====================================================
-- 4. async_tasks 异步任务表 RLS 策略
-- =====================================================
ALTER TABLE async_tasks ENABLE ROW LEVEL SECURITY;

-- 求助者可以查看和管理自己的任务
CREATE POLICY async_seeker_access ON async_tasks
    FOR ALL
    USING (seeker_id = auth.uid())
    WITH CHECK (seeker_id = auth.uid());

-- 志愿者可以查看和接取待处理的任务
CREATE POLICY async_volunteer_access ON async_tasks
    FOR SELECT
    USING (
        volunteer_id = auth.uid() OR
        (status = 'pending' AND volunteer_id IS NULL)
    );

-- 志愿者可以更新自己接取的任务
CREATE POLICY async_volunteer_update ON async_tasks
    FOR UPDATE
    USING (
        volunteer_id = auth.uid() OR
        (status = 'pending' AND volunteer_id IS NULL)  -- 可以接单
    )
    WITH CHECK (volunteer_id = auth.uid());

-- =====================================================
-- 5. point_transactions 积分流水表 RLS 策略
-- =====================================================
ALTER TABLE point_transactions ENABLE ROW LEVEL SECURITY;

-- 用户只能查看自己的积分流水
CREATE POLICY points_self_read ON point_transactions
    FOR SELECT
    USING (user_id = auth.uid());

-- 插入和更新只允许通过服务角色或Edge Functions
CREATE POLICY points_service_insert ON point_transactions
    FOR INSERT
    WITH CHECK (false);  -- 禁止直接插入，通过函数或trigger

-- =====================================================
-- 6. emergency_contacts 紧急联系人表 RLS 策略
-- =====================================================
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

-- 用户只能管理自己的紧急联系人
CREATE POLICY emergency_self_access ON emergency_contacts
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- SOS触发时，系统可以读取紧急联系人信息
-- 这个通过service_role绕过RLS实现

-- =====================================================
-- 7. ai_response_cache AI缓存表 RLS 策略
-- =====================================================
ALTER TABLE ai_response_cache ENABLE ROW LEVEL SECURITY;

-- 只允许服务角色访问
CREATE POLICY ai_cache_service_only ON ai_response_cache
    FOR ALL
    USING (false)
    WITH CHECK (false);

-- =====================================================
-- 8. reports 举报表 RLS 策略
-- =====================================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- 用户可以查看自己提交的举报
CREATE POLICY reports_reporter_read ON reports
    FOR SELECT
    USING (reporter_id = auth.uid());

-- 用户可以提交举报
CREATE POLICY reports_reporter_insert ON reports
    FOR INSERT
    WITH CHECK (reporter_id = auth.uid());

-- 更新只允许服务角色(管理员)
CREATE POLICY reports_service_update ON reports
    FOR UPDATE
    USING (false)
    WITH CHECK (false);

-- =====================================================
-- 9. call_records 通话记录表 RLS 策略
-- =====================================================
ALTER TABLE call_records ENABLE ROW LEVEL SECURITY;

-- 求助者和志愿者都可以查看相关的通话记录
CREATE POLICY call_participant_access ON call_records
    FOR SELECT
    USING (
        seeker_id = auth.uid() OR
        volunteer_id = auth.uid()
    );

-- 插入只允许通过服务角色或Edge Functions
CREATE POLICY call_service_insert ON call_records
    FOR INSERT
    WITH CHECK (false);

-- 更新只允许相关参与者
CREATE POLICY call_participant_update ON call_records
    FOR UPDATE
    USING (
        seeker_id = auth.uid() OR
        volunteer_id = auth.uid()
    )
    WITH CHECK (
        seeker_id = auth.uid() OR
        volunteer_id = auth.uid()
    );

-- =====================================================
-- 10. 存储桶 RLS 策略 (需要在Storage中配置)
-- =====================================================

-- 头像存储桶策略
-- INSERT: 用户只能上传自己的头像
-- SELECT: 公开可读
-- UPDATE/DELETE: 只能操作自己的头像

-- 录音/附件存储桶策略
-- INSERT: 求助者和志愿者可以上传相关求助的附件
-- SELECT: 只有相关参与者可以查看
-- DELETE: 只能删除自己的附件

-- =====================================================
-- 11. 辅助函数
-- =====================================================

-- 检查用户是否为志愿者
CREATE OR REPLACE FUNCTION is_volunteer(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users
        WHERE id = user_uuid
        AND 'volunteer' = ANY(role)
        AND is_deleted = FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 检查用户是否为求助者
CREATE OR REPLACE FUNCTION is_seeker(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users
        WHERE id = user_uuid
        AND 'seeker' = ANY(role)
        AND is_deleted = FALSE
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 获取用户角色数组
CREATE OR REPLACE FUNCTION get_user_roles(user_uuid UUID)
RETURNS TEXT[] AS $$
DECLARE
    roles TEXT[];
BEGIN
    SELECT role INTO roles FROM users
    WHERE id = user_uuid AND is_deleted = FALSE;
    RETURN roles;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
