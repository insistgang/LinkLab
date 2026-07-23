-- 历史全量 schema：仅归档，禁止作为当前默认部署迁移。
-- =====================================================
-- 共感 LinkAble 數據庫索引優化腳本
-- =====================================================

-- =====================================================
-- 1. users 用戶表索引
-- =====================================================

-- 手機號查詢索引(用於登錄)
CREATE INDEX idx_users_phone ON users(phone) WHERE is_deleted = FALSE;

-- 角色數組GIN索引(用於按角色篩選)
CREATE INDEX idx_users_role ON users USING GIN(role) WHERE is_deleted = FALSE;

-- 障礙類型數組GIN索引
CREATE INDEX idx_users_disability ON users USING GIN(disability_type) WHERE is_deleted = FALSE;

-- 創建時間索引(用於排序)
CREATE INDEX idx_users_created_at ON users(created_at DESC) WHERE is_deleted = FALSE;

-- 最後登錄時間索引(用於活躍度分析)
CREATE INDEX idx_users_last_login ON users(last_login_at DESC) WHERE is_deleted = FALSE;

-- =====================================================
-- 2. volunteer_profiles 志願者擴展表索引
-- =====================================================

-- 地理位置GIST索引(用於附近志願者查詢) - 最關鍵索引
CREATE INDEX idx_volunteer_location ON volunteer_profiles USING GIST(location)
    WHERE is_online = TRUE AND is_verified = TRUE;

-- 在線狀態組合索引(匹配查詢用)
CREATE INDEX idx_volunteer_online ON volunteer_profiles(is_online, is_verified, last_heartbeat_at DESC)
    WHERE is_online = TRUE;

-- 技能標籤GIN索引(用於技能匹配)
CREATE INDEX idx_volunteer_skills ON volunteer_profiles USING GIN(skills);

-- 信用分排序索引
CREATE INDEX idx_volunteer_credit ON volunteer_profiles(credit_score DESC, points DESC)
    WHERE is_verified = TRUE;

-- 等級索引(用於等級篩選)
CREATE INDEX idx_volunteer_level ON volunteer_profiles(level DESC)
    WHERE is_verified = TRUE;

-- 累計幫助次數索引(用於排序)
CREATE INDEX idx_volunteer_help_count ON volunteer_profiles(total_help_count DESC);

-- 心跳時間索引(用於清理離線用戶)
CREATE INDEX idx_volunteer_heartbeat ON volunteer_profiles(last_heartbeat_at)
    WHERE is_online = TRUE;

-- =====================================================
-- 3. help_requests 求助記錄表索引
-- =====================================================

-- 求助者ID+創建時間複合索引(用於查詢用戶的求助歷史)
CREATE INDEX idx_help_seeker ON help_requests(seeker_id, created_at DESC);

-- 志願者ID+創建時間複合索引(用於查詢志願者的幫助歷史)
CREATE INDEX idx_help_volunteer ON help_requests(volunteer_id, created_at DESC)
    WHERE volunteer_id IS NOT NULL;

-- 狀態+緊急程度複合索引(用於匹配查詢)
CREATE INDEX idx_help_status_urgency ON help_requests(status, urgency, created_at DESC);

-- 狀態+類型複合索引(用於統計)
CREATE INDEX idx_help_status_type ON help_requests(status, type);

-- 地理位置GIST索引(用於附近求助查詢)
CREATE INDEX idx_help_location ON help_requests USING GIST(location)
    WHERE status IN ('pending', 'matching');

-- 創建時間索引(用於排序和分頁)
CREATE INDEX idx_help_created_at ON help_requests(created_at DESC);

-- 匹配時間索引(用於KPI統計)
CREATE INDEX idx_help_matched_at ON help_requests(matched_at)
    WHERE matched_at IS NOT NULL;

-- 完成時間索引(用於統計)
CREATE INDEX idx_help_completed_at ON help_requests(completed_at)
    WHERE completed_at IS NOT NULL;

-- AI已解決的狀態索引
CREATE INDEX idx_help_ai_resolved ON help_requests(status, created_at DESC)
    WHERE status = 'ai_resolved';

-- =====================================================
-- 4. async_tasks 異步任務表索引
-- =====================================================

-- 狀態+創建時間複合索引(用於任務隊列查詢)
CREATE INDEX idx_async_status ON async_tasks(status, created_at)
    WHERE status = 'pending';

-- 志願者ID索引(用於查詢志願者的任務)
CREATE INDEX idx_async_volunteer ON async_tasks(volunteer_id, status, created_at DESC)
    WHERE volunteer_id IS NOT NULL;

-- 求助者ID索引
CREATE INDEX idx_async_seeker ON async_tasks(seeker_id, created_at DESC);

-- 截止時間索引(用於過期檢測)
CREATE INDEX idx_async_deadline ON async_tasks(deadline_at)
    WHERE status IN ('pending', 'accepted', 'processing');

-- 任務類型索引(用於分類查詢)
CREATE INDEX idx_async_type ON async_tasks(type, status);

-- =====================================================
-- 5. point_transactions 積分流水錶索引
-- =====================================================

-- 用戶ID+創建時間複合索引(用於查詢積分歷史)
CREATE INDEX idx_points_user ON point_transactions(user_id, created_at DESC);

-- 來源類型索引(用於統計)
CREATE INDEX idx_points_source ON point_transactions(source, created_at DESC);

-- 類型索引(用於分類統計)
CREATE INDEX idx_points_type ON point_transactions(type, created_at DESC);

-- =====================================================
-- 6. emergency_contacts 緊急聯繫人表索引
-- =====================================================

-- 用戶ID+優先級複合索引
CREATE INDEX idx_emergency_user ON emergency_contacts(user_id, priority)
    WHERE is_active = TRUE;

-- =====================================================
-- 7. ai_response_cache AI緩存表索引
-- =====================================================

-- 過期時間索引(用於清理過期緩存)
CREATE INDEX idx_cache_expires ON ai_response_cache(expires_at)
    WHERE expires_at < NOW();

-- 查詢類型索引(用於統計)
CREATE INDEX idx_cache_type ON ai_response_cache(query_type, hit_count DESC);

-- =====================================================
-- 8. reports 舉報表索引
-- =====================================================

-- 狀態索引(用於待處理舉報列表)
CREATE INDEX idx_reports_status ON reports(status, created_at DESC)
    WHERE status = 'pending';

-- 被舉報者索引
CREATE INDEX idx_reports_reported ON reports(reported_id, created_at DESC);

-- 舉報者索引
CREATE INDEX idx_reports_reporter ON reports(reporter_id, created_at DESC);

-- =====================================================
-- 9. call_records 通話記錄表索引
-- =====================================================

-- 求助記錄ID索引
CREATE INDEX idx_call_request ON call_records(request_id);

-- 求助者ID索引
CREATE INDEX idx_call_seeker ON call_records(seeker_id, started_at DESC);

-- 志願者ID索引
CREATE INDEX idx_call_volunteer ON call_records(volunteer_id, started_at DESC);

-- 通話狀態索引
CREATE INDEX idx_call_status ON call_records(status, created_at DESC);

-- 通話質量索引(用於分析)
CREATE INDEX idx_call_quality ON call_records(quality_score)
    WHERE quality_score IS NOT NULL;

-- =====================================================
-- 統計信息更新(用於查詢優化器)
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
