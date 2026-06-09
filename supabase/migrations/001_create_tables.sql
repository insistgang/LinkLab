-- =====================================================
-- 共感 LinkAble 數據庫初始化腳本
-- 創建核心表結構
-- =====================================================

-- 啓用PostGIS擴展（用於地理座標）
CREATE EXTENSION IF NOT EXISTS postgis;

-- =====================================================
-- 1. users 用戶基礎表
-- =====================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone TEXT UNIQUE,                          -- 手機號登錄
    name TEXT,                                  -- 暱稱
    avatar_url TEXT,                            -- 頭像URL
    role TEXT[] DEFAULT '{}',                   -- ['seeker', 'volunteer'] 可雙角色
    disability_type TEXT[] DEFAULT '{}',        -- ['visual', 'hearing', 'physical', 'elderly', 'temporary']
    preferences JSONB DEFAULT '{}',             -- 無障礙偏好配置
    last_login_at TIMESTAMPTZ,                  -- 最後登錄時間
    is_deleted BOOLEAN DEFAULT FALSE,           -- 軟刪除標記
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE users IS '用戶基礎表';
COMMENT ON COLUMN users.role IS '用戶角色數組，支持seeker(求助者)和volunteer(志願者)雙角色';
COMMENT ON COLUMN users.disability_type IS '障礙類型：visual(視障), hearing(聽障), physical(肢體), elderly(老年), temporary(臨時)';
COMMENT ON COLUMN users.preferences IS '無障礙偏好配置，如字體大小、高對比度、語音速度等';

-- =====================================================
-- 2. volunteer_profiles 志願者擴展表
-- =====================================================
CREATE TABLE volunteer_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    skills TEXT[] DEFAULT '{}',                 -- 技能標籤數組
    level INT DEFAULT 1 CHECK (level >= 1 AND level <= 7),  -- 等級 1-7
    points INT DEFAULT 0,                       -- 積分
    credit_score DECIMAL(2,1) DEFAULT 5.0 CHECK (credit_score >= 1.0 AND credit_score <= 5.0),  -- 信用分 1-5
    is_verified BOOLEAN DEFAULT FALSE,          -- 實名認證
    available_schedule JSONB DEFAULT '{}',      -- 排班配置
    is_online BOOLEAN DEFAULT FALSE,            -- 在線狀態
    last_heartbeat_at TIMESTAMPTZ,              -- 最後心跳時間
    total_help_count INT DEFAULT 0,             -- 累計幫助次數
    location GEOGRAPHY(POINT,4326),             -- PostGIS地理座標(WGS84)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE volunteer_profiles IS '志願者擴展表';
COMMENT ON COLUMN volunteer_profiles.skills IS '技能標籤：medical(醫療), guide(導盲), tech(技術), sign(手語), elderly(敬老), child(兒童), daily(日常)';
COMMENT ON COLUMN volunteer_profiles.level IS '志願者等級1-7，根據積分自動計算';
COMMENT ON COLUMN volunteer_profiles.available_schedule IS '可服務時間段配置';
COMMENT ON COLUMN volunteer_profiles.location IS '實時位置座標，僅在匹配時對其他用戶可見';

-- =====================================================
-- 3. help_requests 求助記錄表
-- =====================================================
CREATE TABLE help_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seeker_id UUID NOT NULL REFERENCES users(id),
    type TEXT NOT NULL CHECK (type IN ('ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos')),
    intent TEXT,                                -- AI識別的意圖
    urgency TEXT DEFAULT 'normal' CHECK (urgency IN ('normal', 'important', 'urgent', 'emergency')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'ai_resolved', 'matching', 'matched', 'connected', 'completed', 'cancelled')),
    ai_response JSONB DEFAULT '{}',             -- AI處理結果緩存
    volunteer_id UUID REFERENCES users(id),     -- 匹配的志願者
    location GEOGRAPHY(POINT,4326),             -- 求助位置
    duration_seconds INT,                       -- 通話時長(秒)
    seeker_rating INT CHECK (seeker_rating >= 1 AND seeker_rating <= 5),
    volunteer_rating INT CHECK (volunteer_rating >= 1 AND volunteer_rating <= 5),
    seeker_feedback TEXT,                       -- 求助者評價內容
    volunteer_feedback TEXT,                    -- 志願者評價內容
    cancel_reason TEXT,                         -- 取消原因
    matched_at TIMESTAMPTZ,                     -- 匹配成功時間
    completed_at TIMESTAMPTZ,                   -- 完成時間
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE help_requests IS '求助記錄表';
COMMENT ON COLUMN help_requests.type IS '求助類型：ai_auto(AI自動), async(異步), realtime_voice(實時語音), realtime_video(實時視頻), sos(緊急)';
COMMENT ON COLUMN help_requests.urgency IS '緊急程度：normal(普通), important(重要), urgent(緊急), emergency(危急)';
COMMENT ON COLUMN help_requests.status IS '狀態：pending(待處理), ai_resolved(AI已解決), matching(匹配中), matched(已匹配), connected(通話中), completed(已完成), cancelled(已取消)';

-- =====================================================
-- 4. async_tasks 異步任務表
-- =====================================================
CREATE TABLE async_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES help_requests(id) ON DELETE CASCADE,
    seeker_id UUID NOT NULL REFERENCES users(id),
    volunteer_id UUID REFERENCES users(id),     -- 接單的志願者
    title TEXT NOT NULL,                        -- 任務標題
    description TEXT,                           -- 任務描述
    type TEXT NOT NULL CHECK (type IN ('ocr', 'scene_desc', 'translation', 'guidance', 'other')),
    attachments JSONB DEFAULT '[]',             -- 附件列表(圖片等)
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'processing', 'completed', 'cancelled', 'expired')),
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    result TEXT,                                -- 處理結果
    result_attachments JSONB DEFAULT '[]',      -- 結果附件
    deadline_at TIMESTAMPTZ,                    -- 截止時間
    accepted_at TIMESTAMPTZ,                    -- 接單時間
    completed_at TIMESTAMPTZ,                   -- 完成時間
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE async_tasks IS '異步任務表';
COMMENT ON COLUMN async_tasks.type IS '任務類型：ocr(文字識別), scene_desc(場景描述), translation(翻譯), guidance(導航指引), other(其他)';
COMMENT ON COLUMN async_tasks.status IS '狀態：pending(待接單), accepted(已接單), processing(處理中), completed(已完成), cancelled(已取消), expired(已過期)';

-- =====================================================
-- 5. point_transactions 積分流水錶
-- =====================================================
CREATE TABLE point_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type TEXT NOT NULL CHECK (type IN ('earn', 'spend', 'bonus', 'penalty')),
    amount INT NOT NULL,                        -- 積分變化量(正數增加，負數減少)
    balance INT NOT NULL,                       -- 變動後餘額
    source TEXT NOT NULL,                       -- 來源：help_complete, task_complete, sign_in, exchange等
    source_id UUID,                             -- 關聯記錄ID
    description TEXT,                           -- 描述
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE point_transactions IS '積分流水錶';
COMMENT ON COLUMN point_transactions.type IS '類型：earn(獲得), spend(消耗), bonus(獎勵), penalty(扣除)';
COMMENT ON COLUMN point_transactions.source IS '積分來源：help_complete(幫助完成), task_complete(任務完成), sign_in(簽到), exchange(兌換), system(系統)等';

-- =====================================================
-- 6. emergency_contacts 緊急聯繫人表
-- =====================================================
CREATE TABLE emergency_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,                         -- 聯繫人姓名
    phone TEXT NOT NULL,                        -- 聯繫人電話
    relationship TEXT,                          -- 關係
    priority INT DEFAULT 1,                     -- 優先級(1最高)
    is_active BOOLEAN DEFAULT TRUE,             -- 是否啓用
    notify_on_sos BOOLEAN DEFAULT TRUE,         -- SOS時是否通知
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE emergency_contacts IS '緊急聯繫人表';

-- =====================================================
-- 7. ai_response_cache AI響應緩存表
-- =====================================================
CREATE TABLE ai_response_cache (
    query_hash TEXT PRIMARY KEY,                -- 查詢內容哈希
    query_type TEXT NOT NULL,                   -- 查詢類型
    response JSONB NOT NULL,                    -- 緩存結果
    hit_count INT DEFAULT 1,                    -- 命中次數
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL             -- 過期時間
);

COMMENT ON TABLE ai_response_cache IS 'AI響應緩存表，用於降低API調用成本';

-- =====================================================
-- 8. reports 舉報表
-- =====================================================
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id),
    reported_id UUID NOT NULL REFERENCES users(id),
    target_type TEXT NOT NULL CHECK (target_type IN ('user', 'help_request', 'task')),
    target_id UUID NOT NULL,                    -- 被舉報對象ID
    reason TEXT NOT NULL,                       -- 舉報原因
    description TEXT,                           -- 詳細描述
    evidence JSONB DEFAULT '[]',                -- 證據附件
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'resolved', 'rejected')),
    result TEXT,                                -- 處理結果
    handled_by UUID REFERENCES users(id),       -- 處理人
    handled_at TIMESTAMPTZ,                     -- 處理時間
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE reports IS '舉報表';
COMMENT ON COLUMN reports.target_type IS '舉報對象類型：user(用戶), help_request(求助), task(任務)';

-- =====================================================
-- 9. call_records 通話記錄表(用於WebRTC信令和記錄)
-- =====================================================
CREATE TABLE call_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID NOT NULL REFERENCES help_requests(id),
    seeker_id UUID NOT NULL REFERENCES users(id),
    volunteer_id UUID NOT NULL REFERENCES users(id),
    call_type TEXT NOT NULL CHECK (call_type IN ('voice', 'video')),
    status TEXT DEFAULT 'initiating' CHECK (status IN ('initiating', 'ringing', 'connected', 'ended', 'failed')),
    started_at TIMESTAMPTZ,                     -- 通話開始時間
    ended_at TIMESTAMPTZ,                       -- 通話結束時間
    duration_seconds INT,                       -- 通話時長
    end_reason TEXT,                            -- 結束原因
    ice_candidate_count INT,                    -- ICE候選數量(用於質量分析)
    quality_score INT CHECK (quality_score >= 1 AND quality_score <= 5),  -- 通話質量評分
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE call_records IS '通話記錄表';

-- =====================================================
-- 創建更新時間觸發器函數
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 爲需要自動更新updated_at的表創建觸發器
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
