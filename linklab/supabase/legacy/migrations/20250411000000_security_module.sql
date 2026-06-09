-- 安全模塊數據庫表結構
-- 包含多級認證、通話錄音、信用分、舉報處理、緊急聯繫人等功能

-- ============================================
-- 1. 多級認證體系相關表
-- ============================================

-- 用戶認證狀態表
CREATE TABLE IF NOT EXISTS user_auth_status (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_verified BOOLEAN DEFAULT FALSE,
    real_name_verified BOOLEAN DEFAULT FALSE,
    disabled_cert_verified BOOLEAN DEFAULT FALSE,
    real_name TEXT,
    id_card_number TEXT,
    disabled_cert_image_url TEXT,
    phone_verified_at TIMESTAMPTZ,
    real_name_verified_at TIMESTAMPTZ,
    disabled_cert_verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 技能認證表
CREATE TABLE IF NOT EXISTS skill_certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    skill_code TEXT,
    certificate_image_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    reject_reason TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    verified_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 認證申請表
CREATE TABLE IF NOT EXISTS certification_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    auth_level TEXT NOT NULL CHECK (auth_level IN ('phone', 'realName', 'disabledCert', 'skillCert')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    skill_name TEXT,
    certificate_image_url TEXT,
    id_card_number TEXT,
    real_name TEXT,
    reject_reason TEXT,
    reviewer_id UUID REFERENCES auth.users(id),
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. 通話錄音相關表
-- ============================================

-- 通話錄音表
CREATE TABLE IF NOT EXISTS call_recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id UUID NOT NULL,
    seeker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    volunteer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    file_url TEXT,
    file_path TEXT,
    file_size INTEGER,
    duration INTEGER,
    is_uploaded BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    uploaded_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI檢測結果表
CREATE TABLE IF NOT EXISTS detection_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID NOT NULL REFERENCES call_recordings(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('abuse', 'sensitive', 'fraud', 'abnormal', 'spam')),
    confidence DECIMAL(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    is_violation BOOLEAN DEFAULT FALSE,
    violation_level TEXT CHECK (violation_level IN ('low', 'medium', 'high', 'critical')),
    detected_text TEXT,
    matched_keywords TEXT,
    timestamp INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. 信用分相關表
-- ============================================

-- 信用分表
CREATE TABLE IF NOT EXISTS credit_scores (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    score DECIMAL(3,2) DEFAULT 5.0 CHECK (score >= 0 AND score <= 5),
    total_ratings INTEGER DEFAULT 0,
    positive_ratings INTEGER DEFAULT 0,
    negative_ratings INTEGER DEFAULT 0,
    consecutive_good_ratings INTEGER DEFAULT 0,
    last_rating_at TIMESTAMPTZ,
    last_violation_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 評價記錄表
CREATE TABLE IF NOT EXISTS rating_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    call_id UUID NOT NULL,
    help_request_id UUID NOT NULL,
    from_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    tags TEXT[],
    is_seeker_to_volunteer BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 信用分變動記錄表
CREATE TABLE IF NOT EXISTS credit_score_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    change DECIMAL(3,2) NOT NULL,
    score_before DECIMAL(3,2) NOT NULL,
    score_after DECIMAL(3,2) NOT NULL,
    reason TEXT NOT NULL,
    related_id UUID,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. 舉報處理相關表
-- ============================================

-- 舉報記錄表
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    description TEXT,
    evidence_urls TEXT[],
    call_id UUID,
    help_request_id UUID,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'resolved')),
    decision TEXT CHECK (decision IN ('valid', 'invalid', 'uncertain')),
    reviewer_id UUID REFERENCES auth.users(id),
    review_note TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 黑名單表
CREATE TABLE IF NOT EXISTS blacklist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    level TEXT NOT NULL CHECK (level IN ('user', 'device', 'ip')),
    reason TEXT NOT NULL,
    evidence TEXT,
    device_fingerprint TEXT,
    ip_address TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 舉報統計表
CREATE TABLE IF NOT EXISTS report_statistics (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    total_reports_received INTEGER DEFAULT 0,
    valid_reports INTEGER DEFAULT 0,
    invalid_reports INTEGER DEFAULT 0,
    pending_reports INTEGER DEFAULT 0,
    last_report_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用戶限制表（臨時凍結等）
CREATE TABLE IF NOT EXISTS user_restrictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    reason TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用戶狀態變更記錄表
CREATE TABLE IF NOT EXISTS user_status_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    from_status TEXT NOT NULL,
    to_status TEXT NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. 緊急聯繫人相關表
-- ============================================

-- 緊急聯繫人表
CREATE TABLE IF NOT EXISTS emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    relationship TEXT,
    priority INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 緊急通知記錄表
CREATE TABLE IF NOT EXISTS emergency_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    contact_id UUID NOT NULL REFERENCES emergency_contacts(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    content TEXT NOT NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    delivered_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ
);

-- 用戶設備表（用於設備封禁）
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_fingerprint TEXT NOT NULL,
    device_info TEXT,
    fcm_token TEXT,
    last_used_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 創建索引
-- ============================================

-- 認證相關索引
CREATE INDEX IF NOT EXISTS idx_skill_certs_user_id ON skill_certifications(user_id);
CREATE INDEX IF NOT EXISTS idx_cert_apps_user_id ON certification_applications(user_id);
CREATE INDEX IF NOT EXISTS idx_cert_apps_status ON certification_applications(status);

-- 錄音相關索引
CREATE INDEX IF NOT EXISTS idx_recordings_call_id ON call_recordings(call_id);
CREATE INDEX IF NOT EXISTS idx_recordings_seeker_id ON call_recordings(seeker_id);
CREATE INDEX IF NOT EXISTS idx_recordings_expires ON call_recordings(expires_at) WHERE is_deleted = FALSE;
CREATE INDEX IF NOT EXISTS idx_detection_results_recording_id ON detection_results(recording_id);

-- 信用分相關索引
CREATE INDEX IF NOT EXISTS idx_rating_records_to_user ON rating_records(to_user_id);
CREATE INDEX IF NOT EXISTS idx_rating_records_call_id ON rating_records(call_id);
CREATE INDEX IF NOT EXISTS idx_credit_changes_user_id ON credit_score_changes(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_changes_created_at ON credit_score_changes(created_at);

-- 舉報相關索引
CREATE INDEX IF NOT EXISTS idx_reports_reported_id ON reports(reported_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_submitted_at ON reports(submitted_at);
CREATE INDEX IF NOT EXISTS idx_blacklist_user_id ON blacklist(user_id);
CREATE INDEX IF NOT EXISTS idx_blacklist_device ON blacklist(device_fingerprint) WHERE level = 'device';
CREATE INDEX IF NOT EXISTS idx_blacklist_expires ON blacklist(expires_at);

-- 緊急聯繫人相關索引
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_user_id ON emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_emergency_contacts_phone ON emergency_contacts(phone);
CREATE INDEX IF NOT EXISTS idx_emergency_notifications_user_id ON emergency_notifications(user_id);

-- 用戶設備索引
CREATE INDEX IF NOT EXISTS idx_user_devices_fingerprint ON user_devices(device_fingerprint);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);

-- ============================================
-- 創建RLS安全策略
-- ============================================

-- 啓用RLS
ALTER TABLE user_auth_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE skill_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE certification_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE call_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE detection_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE rating_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_score_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE blacklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_restrictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_status_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- 用戶認證狀態策略
CREATE POLICY "Users can view own auth status"
    ON user_auth_status FOR SELECT
    USING (user_id = auth.uid());

-- 技能認證策略
CREATE POLICY "Users can view own skill certs"
    ON skill_certifications FOR SELECT
    USING (user_id = auth.uid());

-- 認證申請策略
CREATE POLICY "Users can view own applications"
    ON certification_applications FOR SELECT
    USING (user_id = auth.uid());

-- 通話錄音策略
CREATE POLICY "Users can view own call recordings"
    ON call_recordings FOR SELECT
    USING (seeker_id = auth.uid() OR volunteer_id = auth.uid());

-- 信用分策略
CREATE POLICY "Users can view own credit score"
    ON credit_scores FOR SELECT
    USING (user_id = auth.uid());

-- 評價記錄策略
CREATE POLICY "Users can view ratings related to them"
    ON rating_records FOR SELECT
    USING (from_user_id = auth.uid() OR to_user_id = auth.uid());

-- 信用分變動策略
CREATE POLICY "Users can view own credit changes"
    ON credit_score_changes FOR SELECT
    USING (user_id = auth.uid());

-- 舉報記錄策略
CREATE POLICY "Users can view own reports"
    ON reports FOR SELECT
    USING (reporter_id = auth.uid() OR reported_id = auth.uid());

-- 緊急聯繫人策略
CREATE POLICY "Users can manage own emergency contacts"
    ON emergency_contacts FOR ALL
    USING (user_id = auth.uid());

-- 緊急通知策略
CREATE POLICY "Users can view own emergency notifications"
    ON emergency_notifications FOR SELECT
    USING (user_id = auth.uid());

-- 用戶設備策略
CREATE POLICY "Users can view own devices"
    ON user_devices FOR SELECT
    USING (user_id = auth.uid());

-- ============================================
-- 創建觸發器函數
-- ============================================

-- 自動更新 updated_at 字段
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 爲需要自動更新 updated_at 的表創建觸發器
CREATE TRIGGER update_user_auth_status_updated_at
    BEFORE UPDATE ON user_auth_status
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_skill_certs_updated_at
    BEFORE UPDATE ON skill_certifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credit_scores_updated_at
    BEFORE UPDATE ON credit_scores
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_contacts_updated_at
    BEFORE UPDATE ON emergency_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_statistics_updated_at
    BEFORE UPDATE ON report_statistics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 初始化新用戶信用分
CREATE OR REPLACE FUNCTION initialize_user_credit_score()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO credit_scores (user_id, score)
    VALUES (NEW.id, 5.0)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 爲新用戶自動創建信用分記錄
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION initialize_user_credit_score();

-- 清理過期錄音的定時任務函數
CREATE OR REPLACE FUNCTION cleanup_expired_recordings()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER := 0;
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT id FROM call_recordings
        WHERE expires_at < NOW() AND is_deleted = FALSE
    LOOP
        UPDATE call_recordings
        SET is_deleted = TRUE, deleted_at = NOW()
        WHERE id = rec.id;
        deleted_count := deleted_count + 1;
    END LOOP;

    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 添加表註釋
-- ============================================

COMMENT ON TABLE user_auth_status IS '用戶多級認證狀態';
COMMENT ON TABLE skill_certifications IS '技能認證記錄';
COMMENT ON TABLE certification_applications IS '認證申請記錄';
COMMENT ON TABLE call_recordings IS '通話錄音記錄';
COMMENT ON TABLE detection_results IS 'AI內容檢測結果';
COMMENT ON TABLE credit_scores IS '用戶信用分';
COMMENT ON TABLE rating_records IS '雙向評價記錄';
COMMENT ON TABLE credit_score_changes IS '信用分變動歷史';
COMMENT ON TABLE reports IS '舉報記錄';
COMMENT ON TABLE blacklist IS '黑名單';
COMMENT ON TABLE emergency_contacts IS '緊急聯繫人';
COMMENT ON TABLE emergency_notifications IS '緊急通知記錄';
COMMENT ON TABLE user_devices IS '用戶設備信息';
