-- Migration: Création de la table budget_goals
-- Description: Table des objectifs budgétaires et d'épargne

-- ═══════════════════════════════════════════════════════════
-- TABLE: budget_goals
-- ═══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS budget_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    target_amount DECIMAL(12,2) NOT NULL,
    current_amount DECIMAL(12,2) DEFAULT 0,
    category TEXT,
    goal_type TEXT CHECK(goal_type IN ('savings', 'spending_limit', 'debt_reduction', 'income_target')) DEFAULT 'savings',
    deadline DATE,
    color TEXT DEFAULT '#E8A86C',
    icon TEXT DEFAULT 'savings',
    is_active BOOLEAN DEFAULT TRUE,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurring_period TEXT CHECK(recurring_period IN ('weekly', 'monthly', 'yearly')),
    alert_threshold DECIMAL(5,2), -- Pourcentage d'alerte (ex: 80%)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_budget_goals_user_id ON budget_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_budget_goals_active ON budget_goals(user_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_budget_goals_category ON budget_goals(user_id, category) WHERE category IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_budget_goals_deadline ON budget_goals(deadline) WHERE deadline IS NOT NULL;

-- ═══════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════

ALTER TABLE budget_goals ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres objectifs
CREATE POLICY "Users can view own budget goals"
ON budget_goals FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent créer leurs propres objectifs
CREATE POLICY "Users can create own budget goals"
ON budget_goals FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent modifier leurs propres objectifs
CREATE POLICY "Users can update own budget goals"
ON budget_goals FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Policy: Les utilisateurs peuvent supprimer leurs propres objectifs
CREATE POLICY "Users can delete own budget goals"
ON budget_goals FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════

CREATE TRIGGER update_budget_goals_updated_at
    BEFORE UPDATE ON budget_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════
-- FONCTIONS
-- ═══════════════════════════════════════════════════════════

-- Fonction pour calculer la progression d'un objectif
CREATE OR REPLACE FUNCTION get_goal_progress(goal_uuid UUID)
RETURNS DECIMAL AS $$
DECLARE
    progress DECIMAL;
    goal RECORD;
BEGIN
    SELECT target_amount, current_amount
    INTO goal
    FROM budget_goals
    WHERE id = goal_uuid;
    
    IF goal.target_amount = 0 THEN
        RETURN 0;
    END IF;
    
    progress := LEAST((goal.current_amount / goal.target_amount * 100), 100);
    RETURN ROUND(progress::numeric, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les objectifs proches de la date butoir
CREATE OR REPLACE FUNCTION get_upcoming_deadlines(
    user_uuid UUID,
    days_ahead INTEGER DEFAULT 30
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    target_amount DECIMAL,
    current_amount DECIMAL,
    progress DECIMAL,
    deadline DATE,
    days_remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bg.id,
        bg.name,
        bg.target_amount,
        bg.current_amount,
        get_goal_progress(bg.id) as progress,
        bg.deadline,
        (bg.deadline - CURRENT_DATE)::INTEGER as days_remaining
    FROM budget_goals bg
    WHERE bg.user_id = user_uuid
        AND bg.is_active = TRUE
        AND bg.deadline IS NOT NULL
        AND bg.deadline BETWEEN CURRENT_DATE AND CURRENT_DATE + days_ahead
    ORDER BY bg.deadline;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les objectifs en alerte (proche du seuil)
CREATE OR REPLACE FUNCTION get_budget_alerts(user_uuid UUID)
RETURNS TABLE (
    id UUID,
    name TEXT,
    type TEXT,
    current_amount DECIMAL,
    target_amount DECIMAL,
    percentage_used DECIMAL,
    alert_threshold DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bg.id,
        bg.name,
        bg.goal_type as type,
        bg.current_amount,
        bg.target_amount,
        CASE 
            WHEN bg.target_amount > 0 
            THEN ROUND((bg.current_amount / bg.target_amount * 100)::numeric, 2)
            ELSE 0
        END as percentage_used,
        bg.alert_threshold
    FROM budget_goals bg
    WHERE bg.user_id = user_uuid
        AND bg.is_active = TRUE
        AND bg.alert_threshold IS NOT NULL
        AND bg.target_amount > 0
        AND (bg.current_amount / bg.target_amount * 100) >= bg.alert_threshold
    ORDER BY (bg.current_amount / bg.target_amount) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════
-- VUES
-- ═══════════════════════════════════════════════════════════

-- Vue du résumé des objectifs
CREATE OR REPLACE VIEW budget_goals_summary AS
SELECT 
    bg.user_id,
    bg.goal_type,
    COUNT(*) as total_goals,
    COUNT(*) FILTER (WHERE bg.current_amount >= bg.target_amount) as completed_goals,
    SUM(bg.target_amount) as total_target,
    SUM(bg.current_amount) as total_current,
    CASE 
        WHEN SUM(bg.target_amount) > 0 
        THEN ROUND((SUM(bg.current_amount) / SUM(bg.target_amount) * 100)::numeric, 2)
        ELSE 0
    END as overall_progress
FROM budget_goals bg
WHERE bg.is_active = TRUE
GROUP BY bg.user_id, bg.goal_type;

-- ═══════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════

COMMENT ON TABLE budget_goals IS 'Objectifs budgétaires et d épargne';
COMMENT ON COLUMN budget_goals.goal_type IS 'Type: savings, spending_limit, debt_reduction, income_target';
COMMENT ON COLUMN budget_goals.alert_threshold IS 'Pourcentage d alerte (ex: 80 pour 80%)';
COMMENT ON COLUMN budget_goals.is_recurring IS 'TRUE si l objectif se répète (ex: budget mensuel)';
