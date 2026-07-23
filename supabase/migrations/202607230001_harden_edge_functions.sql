-- LinkAble Edge Function hardening.
-- Points are awarded exactly once per business record and only through a
-- service-role-only database function.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'point_transactions_source_record_unique'
          AND conrelid = 'public.point_transactions'::regclass
    ) THEN
        ALTER TABLE public.point_transactions
            ADD CONSTRAINT point_transactions_source_record_unique
            UNIQUE (source, source_id);
    END IF;
END
$$;

CREATE OR REPLACE FUNCTION public.award_volunteer_points_once(
    p_user_id UUID,
    p_points INT,
    p_source TEXT,
    p_source_id UUID,
    p_description TEXT,
    p_increment_help_count BOOLEAN DEFAULT FALSE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    current_points INT;
    current_level INT;
    next_points INT;
    next_level INT;
    transaction_id UUID;
BEGIN
    IF p_points <= 0 OR p_source_id IS NULL THEN
        RETURN FALSE;
    END IF;

    SELECT points, level
    INTO current_points, current_level
    FROM public.volunteer_profiles
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    next_points := current_points + p_points;
    next_level := CASE
        WHEN next_points >= 1200 THEN 7
        WHEN next_points >= 800 THEN 6
        WHEN next_points >= 500 THEN 5
        WHEN next_points >= 300 THEN 4
        WHEN next_points >= 150 THEN 3
        WHEN next_points >= 50 THEN 2
        ELSE 1
    END;

    INSERT INTO public.point_transactions (
        user_id,
        type,
        amount,
        balance,
        source,
        source_id,
        description
    )
    VALUES (
        p_user_id,
        'earn',
        p_points,
        next_points,
        p_source,
        p_source_id,
        p_description
    )
    ON CONFLICT ON CONSTRAINT point_transactions_source_record_unique
    DO NOTHING
    RETURNING id INTO transaction_id;

    IF transaction_id IS NULL THEN
        RETURN FALSE;
    END IF;

    UPDATE public.volunteer_profiles
    SET
        points = next_points,
        level = GREATEST(current_level, next_level),
        total_help_count = total_help_count
            + CASE WHEN p_increment_help_count THEN 1 ELSE 0 END
    WHERE user_id = p_user_id;

    IF next_level > current_level THEN
        INSERT INTO public.notifications (
            user_id,
            type,
            title,
            content,
            data
        )
        VALUES (
            p_user_id,
            'level_up',
            '等级提升！',
            '恭喜您升级到等级 ' || next_level || '！',
            jsonb_build_object(
                'newLevel', next_level,
                'newPoints', next_points
            )
        );
    END IF;

    RETURN TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.award_volunteer_points_once(
    UUID,
    INT,
    TEXT,
    UUID,
    TEXT,
    BOOLEAN
) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.award_volunteer_points_once(
    UUID,
    INT,
    TEXT,
    UUID,
    TEXT,
    BOOLEAN
) TO service_role;
