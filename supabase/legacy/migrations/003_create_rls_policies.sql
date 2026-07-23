-- 历史全量 schema：仅归档，禁止作为当前默认部署迁移。
-- =====================================================
-- 共感 LinkAble RLS (Row Level Security) 安全策略
-- =====================================================

-- =====================================================
-- 1. users 表 RLS 策略
-- =====================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 用戶只能查看和修改自己的完整信息
CREATE POLICY user_self_full_access ON users
    FOR ALL
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 允許已認證用戶查看其他用戶的基本公開信息(暱稱、頭像)
CREATE POLICY user_public_read ON users
    FOR SELECT
    USING (
        is_deleted = FALSE AND
        (auth.uid() IS NOT NULL)  -- 任何已認證用戶都可查看
    );

-- =====================================================
-- 2. volunteer_profiles 表 RLS 策略
-- =====================================================
ALTER TABLE volunteer_profiles ENABLE ROW LEVEL SECURITY;

-- 志願者自己可以查看和修改自己的完整資料
CREATE POLICY volunteer_self_access ON volunteer_profiles
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 其他用戶只能查看志願者的公開信息(不包含精確位置)
CREATE POLICY volunteer_public_read ON volunteer_profiles
    FOR SELECT
    USING (
        is_verified = TRUE AND
        auth.uid() IS NOT NULL AND
        auth.uid() != user_id  -- 排除自己，自己的訪問在上面處理
    );

-- 求助者在匹配過程中可以查看志願者位置
-- 當存在進行中的求助請求時，求助者可以看到匹配志願者的位置
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
-- 3. help_requests 求助記錄表 RLS 策略
-- =====================================================
ALTER TABLE help_requests ENABLE ROW LEVEL SECURITY;

-- 求助者可以查看和管理自己的求助
CREATE POLICY help_seeker_access ON help_requests
    FOR ALL
    USING (seeker_id = auth.uid())
    WITH CHECK (seeker_id = auth.uid());

-- 志願者可以查看被分配的求助
CREATE POLICY help_volunteer_access ON help_requests
    FOR SELECT
    USING (
        volunteer_id = auth.uid() OR
        -- 志願者也可以查看待匹配的求助(用於接單)
        (status = 'matching' AND type IN ('realtime_voice', 'realtime_video', 'sos'))
    );

-- 志願者可以更新被分配的求助狀態
CREATE POLICY help_volunteer_update ON help_requests
    FOR UPDATE
    USING (volunteer_id = auth.uid())
    WITH CHECK (volunteer_id = auth.uid());

-- =====================================================
-- 4. async_tasks 異步任務表 RLS 策略
-- =====================================================
ALTER TABLE async_tasks ENABLE ROW LEVEL SECURITY;

-- 求助者可以查看和管理自己的任務
CREATE POLICY async_seeker_access ON async_tasks
    FOR ALL
    USING (seeker_id = auth.uid())
    WITH CHECK (seeker_id = auth.uid());

-- 志願者可以查看和接取待處理的任務
CREATE POLICY async_volunteer_access ON async_tasks
    FOR SELECT
    USING (
        volunteer_id = auth.uid() OR
        (status = 'pending' AND volunteer_id IS NULL)
    );

-- 志願者可以更新自己接取的任務
CREATE POLICY async_volunteer_update ON async_tasks
    FOR UPDATE
    USING (
        volunteer_id = auth.uid() OR
        (status = 'pending' AND volunteer_id IS NULL)  -- 可以接單
    )
    WITH CHECK (volunteer_id = auth.uid());

-- =====================================================
-- 5. point_transactions 積分流水錶 RLS 策略
-- =====================================================
ALTER TABLE point_transactions ENABLE ROW LEVEL SECURITY;

-- 用戶只能查看自己的積分流水
CREATE POLICY points_self_read ON point_transactions
    FOR SELECT
    USING (user_id = auth.uid());

-- 插入和更新只允許通過服務角色或Edge Functions
CREATE POLICY points_service_insert ON point_transactions
    FOR INSERT
    WITH CHECK (false);  -- 禁止直接插入，通過函數或trigger

-- =====================================================
-- 6. emergency_contacts 緊急聯繫人表 RLS 策略
-- =====================================================
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;

-- 用戶只能管理自己的緊急聯繫人
CREATE POLICY emergency_self_access ON emergency_contacts
    FOR ALL
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- SOS觸發時，系統可以讀取緊急聯繫人信息
-- 這個通過service_role繞過RLS實現

-- =====================================================
-- 7. ai_response_cache AI緩存表 RLS 策略
-- =====================================================
ALTER TABLE ai_response_cache ENABLE ROW LEVEL SECURITY;

-- 只允許服務角色訪問
CREATE POLICY ai_cache_service_only ON ai_response_cache
    FOR ALL
    USING (false)
    WITH CHECK (false);

-- =====================================================
-- 8. reports 舉報表 RLS 策略
-- =====================================================
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- 用戶可以查看自己提交的舉報
CREATE POLICY reports_reporter_read ON reports
    FOR SELECT
    USING (reporter_id = auth.uid());

-- 用戶可以提交舉報
CREATE POLICY reports_reporter_insert ON reports
    FOR INSERT
    WITH CHECK (reporter_id = auth.uid());

-- 更新只允許服務角色(管理員)
CREATE POLICY reports_service_update ON reports
    FOR UPDATE
    USING (false)
    WITH CHECK (false);

-- =====================================================
-- 9. call_records 通話記錄表 RLS 策略
-- =====================================================
ALTER TABLE call_records ENABLE ROW LEVEL SECURITY;

-- 求助者和志願者都可以查看相關的通話記錄
CREATE POLICY call_participant_access ON call_records
    FOR SELECT
    USING (
        seeker_id = auth.uid() OR
        volunteer_id = auth.uid()
    );

-- 插入只允許通過服務角色或Edge Functions
CREATE POLICY call_service_insert ON call_records
    FOR INSERT
    WITH CHECK (false);

-- 更新只允許相關參與者
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
-- 10. 存儲桶 RLS 策略 (需要在Storage中配置)
-- =====================================================

-- 頭像存儲桶策略
-- INSERT: 用戶只能上傳自己的頭像
-- SELECT: 公開可讀
-- UPDATE/DELETE: 只能操作自己的頭像

-- 錄音/附件存儲桶策略
-- INSERT: 求助者和志願者可以上傳相關求助的附件
-- SELECT: 只有相關參與者可以查看
-- DELETE: 只能刪除自己的附件

-- =====================================================
-- 11. 輔助函數
-- =====================================================

-- 檢查用戶是否爲志願者
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

-- 檢查用戶是否爲求助者
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

-- 獲取用戶角色數組
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
