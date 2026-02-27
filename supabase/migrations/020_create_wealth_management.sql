-- ============================================================================
-- MIGRATION 020: Assurance Vie & Patrimoine
-- Suivi patrimoine, projection retraite, simulation succession
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: wealth_accounts
-- Comptes patrimoniaux (assurance vie, PEA, crypto, immobilier...)
-- ----------------------------------------------------------------------------
CREATE TABLE wealth_accounts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Identification
    name TEXT NOT NULL, -- "Assurance Vie BNP", "PEA Bourso", "Bitcoin"
    institution TEXT, -- BNP, BoursoBank, Ledger, etc.
    
    -- Type d'actif
    account_type TEXT NOT NULL CHECK(account_type IN (
        'life_insurance',    -- Assurance vie
        'pea',              -- Plan Épargne en Actions
        'pep',              -- Plan Épargne Populaire
        'crypto',           -- Cryptomonnaies
        'real_estate',      -- Immobilier
        'stocks',           -- Compte-titres
        'bonds',            -- Obligations
        'savings',          -- Livrets (A, LDD, etc.)
        'other'             -- Autre
    )),
    
    -- Valeurs
    current_value DECIMAL(15,2) NOT NULL DEFAULT 0,
    invested_amount DECIMAL(15,2) NOT NULL DEFAULT 0, -- Montant investi
    
    -- Performance
    performance_euro DECIMAL(15,2) GENERATED ALWAYS AS (current_value - invested_amount) STORED,
    performance_percent DECIMAL(8,4) GENERATED ALWAYS AS 
        (CASE WHEN invested_amount > 0 THEN (current_value - invested_amount) / invested_amount * 100 ELSE 0 END) STORED,
    
    -- Détails spécifiques au type
    details JSONB DEFAULT '{}'::jsonb,
    -- Assurance vie: {"contract_number": "...", "euro_fund": 60, "unit_linked": 40}
    -- Crypto: {"wallet_address": "...", "blockchain": "ethereum"}
    -- Immobilier: {"address": "...", "surface": 65, "acquisition_date": "..."}
    
    -- Objectif d'allocation
    target_allocation_percent INTEGER, -- % cible dans le portefeuille global
    
    -- Couleur pour l'UI
    color TEXT DEFAULT '#E8A86C',
    
    -- Ordre d'affichage
    display_order INTEGER DEFAULT 0,
    
    -- Actif
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wealth_accounts_user ON wealth_accounts(user_id);
CREATE INDEX idx_wealth_accounts_type ON wealth_accounts(account_type);
CREATE INDEX idx_wealth_accounts_active ON wealth_accounts(is_active) WHERE is_active = TRUE;

-- ----------------------------------------------------------------------------
-- TABLE: wealth_transactions
-- Mouvements sur les comptes patrimoniaux
-- ----------------------------------------------------------------------------
CREATE TABLE wealth_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    wealth_account_id UUID REFERENCES wealth_accounts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Type de transaction
    transaction_type TEXT NOT NULL CHECK(transaction_type IN (
        'deposit',      -- Versement
        'withdrawal',   -- Retrait
        'dividend',     -- Dividende
        'interest',     -- Intérêts
        'revaluation',  -- Réévaluation (immo)
        'fee',          -- Frais
        'transfer'      -- Transfert entre comptes
    )),
    
    -- Montant
    amount DECIMAL(15,2) NOT NULL,
    currency TEXT DEFAULT 'EUR',
    
    -- Date
    transaction_date DATE NOT NULL,
    
    -- Description
    description TEXT,
    
    -- Métadonnées
    metadata JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wealth_transactions_account ON wealth_transactions(wealth_account_id);
CREATE INDEX idx_wealth_transactions_date ON wealth_transactions(transaction_date);
CREATE INDEX idx_wealth_transactions_type ON wealth_transactions(transaction_type);

-- ----------------------------------------------------------------------------
-- TABLE: wealth_valuations
-- Historique des valorisations (pour graphiques)
-- ----------------------------------------------------------------------------
CREATE TABLE wealth_valuations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    wealth_account_id UUID REFERENCES wealth_accounts(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Valorisation
    value DECIMAL(15,2) NOT NULL,
    valuation_date DATE NOT NULL,
    
    -- Source
    source TEXT DEFAULT 'manual' CHECK(source IN ('manual', 'auto', 'import')),
    
    UNIQUE(wealth_account_id, valuation_date)
);

CREATE INDEX idx_wealth_valuations_account_date ON wealth_valuations(wealth_account_id, valuation_date);

-- ----------------------------------------------------------------------------
-- TABLE: retirement_projections
-- Projections de retraite
-- ----------------------------------------------------------------------------
CREATE TABLE retirement_projections (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Paramètres de base
    current_age INTEGER NOT NULL,
    retirement_age INTEGER NOT NULL DEFAULT 65,
    life_expectancy INTEGER DEFAULT 90,
    
    -- Situation actuelle
    current_monthly_income DECIMAL(12,2),
    desired_monthly_pension DECIMAL(12,2),
    
    -- Patrimoine actuel
    current_wealth DECIMAL(15,2) DEFAULT 0,
    
    -- Hypothèses
    annual_return_rate DECIMAL(5,4) DEFAULT 0.04, -- 4% par défaut
    inflation_rate DECIMAL(5,4) DEFAULT 0.02,     -- 2% par défaut
    
    -- Projections calculées
    projected_wealth_at_retirement DECIMAL(15,2),
    projected_monthly_pension DECIMAL(12,2),
    pension_gap DECIMAL(12,2), -- Écart avec l'objectif
    
    -- Scénarios
    scenarios JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "optimistic": {"return_rate": 0.06, "projected_wealth": 850000},
    --   "realistic": {"return_rate": 0.04, "projected_wealth": 620000},
    --   "pessimistic": {"return_rate": 0.02, "projected_wealth": 450000}
    -- }
    
    -- Versements recommandés
    recommended_monthly_savings DECIMAL(12,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_retirement_projections_user ON retirement_projections(user_id);

-- ----------------------------------------------------------------------------
-- TABLE: succession_simulations
-- Simulations de succession
-- ----------------------------------------------------------------------------
CREATE TABLE succession_simulations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Nom de la simulation
    name TEXT NOT NULL,
    
    -- Situation
    marital_status TEXT CHECK(marital_status IN ('single', 'married', 'pacs', 'widowed')),
    has_children BOOLEAN DEFAULT FALSE,
    children_count INTEGER DEFAULT 0,
    
    -- Actifs
    total_assets DECIMAL(15,2) DEFAULT 0,
    assets_breakdown JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "real_estate": 450000,
    --   "financial": 280000,
    --   "life_insurance": 150000,
    --   "other": 50000
    -- }
    
    -- Passifs
    total_liabilities DECIMAL(15,2) DEFAULT 0,
    
    -- Résultats
    net_estate DECIMAL(15,2) GENERATED ALWAYS AS (total_assets - total_liabilities) STORED,
    estimated_duties DECIMAL(15,2), -- Droits de succession estimés
    net_heritage DECIMAL(15,2), -- Héritage net après impôts
    
    -- Répartition par héritier
    heirs_distribution JSONB DEFAULT '{}'::jsonb,
    -- [
    --   {"heir": "Conjoint", "share_percent": 50, "amount": 400000, "duties": 0},
    --   {"heir": "Enfant 1", "share_percent": 25, "amount": 200000, "duties": 35000}
    -- ]
    
    -- Optimisations suggérées
    suggested_optimizations JSONB DEFAULT '{}'::jsonb,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_succession_simulations_user ON succession_simulations(user_id);

-- ----------------------------------------------------------------------------
-- TABLE: portfolio_alerts
-- Alertes de rééquilibrage
-- ----------------------------------------------------------------------------
CREATE TABLE portfolio_alerts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Type d'alerte
    alert_type TEXT NOT NULL CHECK(alert_type IN (
        'rebalancing_needed',    -- Rééquilibrage nécessaire
        'underperforming',       -- Sous-performance
        'concentration_risk',    -- Risque de concentration
        'opportunity',           -- Opportunité d'investissement
        'milestone_reached'      -- Jalon atteint
    )),
    
    -- Sévérité
    severity TEXT DEFAULT 'info' CHECK(severity IN ('info', 'warning', 'critical')),
    
    -- Contenu
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    
    -- Données associées
    data JSONB DEFAULT '{}'::jsonb,
    -- {
    --   "account_id": "uuid",
    --   "current_allocation": 45,
    --   "target_allocation": 30,
    --   "difference": 15
    -- }
    
    -- Statut
    is_read BOOLEAN DEFAULT FALSE,
    is_dismissed BOOLEAN DEFAULT FALSE,
    dismissed_at TIMESTAMPTZ,
    
    -- Action
    action_taken TEXT,
    action_taken_at TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_portfolio_alerts_user ON portfolio_alerts(user_id);
CREATE INDEX idx_portfolio_alerts_unread ON portfolio_alerts(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_portfolio_alerts_type ON portfolio_alerts(alert_type);

-- ----------------------------------------------------------------------------
-- TABLE: investment_goals
-- Objectifs d'investissement
-- ----------------------------------------------------------------------------
CREATE TABLE investment_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Objectif
    name TEXT NOT NULL, -- "Achat résidence principale", "Retraite confortable"
    goal_type TEXT NOT NULL CHECK(goal_type IN (
        'retirement',
        'property',
        'education',
        'travel',
        'inheritance',
        'other'
    )),
    
    -- Montants
    target_amount DECIMAL(15,2) NOT NULL,
    current_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Horizon
    target_date DATE,
    
    -- Progression
    progress_percent DECIMAL(5,2) GENERATED ALWAYS AS 
        (CASE WHEN target_amount > 0 THEN LEAST(current_amount / target_amount * 100, 100) ELSE 0 END) STORED,
    
    -- Stratégie
    strategy TEXT, -- "Prudent", "Équilibré", "Dynamique"
    
    -- Couleur
    color TEXT DEFAULT '#E8A86C',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_investment_goals_user ON investment_goals(user_id);
CREATE INDEX idx_investment_goals_type ON investment_goals(goal_type);

-- ----------------------------------------------------------------------------
-- FONCTION: Calculer la projection de retraite
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_retirement_projection(p_user_id UUID)
RETURNS TABLE (
    scenario TEXT,
    projected_wealth DECIMAL,
    monthly_pension DECIMAL,
    gap DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_wealth DECIMAL;
    v_current_age INTEGER;
    v_years_to_retirement INTEGER;
    v_monthly_savings DECIMAL;
    v_desired_pension DECIMAL;
BEGIN
    -- Récupérer les données utilisateur
    SELECT 
        COALESCE(SUM(current_value), 0),
        EXTRACT(YEAR FROM AGE(NOW(), p.birth_date))::INTEGER
    INTO v_current_wealth, v_current_age
    FROM profiles p
    LEFT JOIN wealth_accounts wa ON wa.user_id = p.id AND wa.is_active = TRUE
    WHERE p.id = p_user_id
    GROUP BY p.id, p.birth_date;
    
    -- Hypothèses
    v_years_to_retirement := GREATEST(65 - v_current_age, 0);
    v_monthly_savings := 500; -- À personnaliser
    v_desired_pension := 3000;
    
    -- Scénarios
    RETURN QUERY
    SELECT * FROM (VALUES
        ('optimiste', 
         v_current_wealth * POWER(1.06, v_years_to_retirement) + 
         v_monthly_savings * 12 * ((POWER(1.06, v_years_to_retirement) - 1) / 0.06),
         (v_current_wealth * POWER(1.06, v_years_to_retirement)) * 0.04 / 12,
         v_desired_pension - (v_current_wealth * POWER(1.06, v_years_to_retirement)) * 0.04 / 12
        ),
        ('réaliste',
         v_current_wealth * POWER(1.04, v_years_to_retirement) +
         v_monthly_savings * 12 * ((POWER(1.04, v_years_to_retirement) - 1) / 0.04),
         (v_current_wealth * POWER(1.04, v_years_to_retirement)) * 0.04 / 12,
         v_desired_pension - (v_current_wealth * POWER(1.04, v_years_to_retirement)) * 0.04 / 12
        ),
        ('prudent',
         v_current_wealth * POWER(1.02, v_years_to_retirement) +
         v_monthly_savings * 12 * ((POWER(1.02, v_years_to_retirement) - 1) / 0.02),
         (v_current_wealth * POWER(1.02, v_years_to_retirement)) * 0.04 / 12,
         v_desired_pension - (v_current_wealth * POWER(1.02, v_years_to_retirement)) * 0.04 / 12
        )
    ) AS t(scenario, projected_wealth, monthly_pension, gap);
END;
$$;

-- ----------------------------------------------------------------------------
-- FONCTION: Vérifier le rééquilibrage nécessaire
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_rebalancing_needed(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_total_wealth DECIMAL;
    v_account RECORD;
BEGIN
    -- Calculer le patrimoine total
    SELECT COALESCE(SUM(current_value), 0) INTO v_total_wealth
    FROM wealth_accounts
    WHERE user_id = p_user_id AND is_active = TRUE;
    
    -- Vérifier chaque compte
    FOR v_account IN 
        SELECT * FROM wealth_accounts 
        WHERE user_id = p_user_id 
          AND is_active = TRUE 
          AND target_allocation_percent IS NOT NULL
    LOOP
        DECLARE
            v_current_allocation DECIMAL;
            v_difference DECIMAL;
        BEGIN
            v_current_allocation := (v_account.current_value / v_total_wealth) * 100;
            v_difference := ABS(v_current_allocation - v_account.target_allocation_percent);
            
            -- Si écart > 5%, créer une alerte
            IF v_difference > 5 THEN
                INSERT INTO portfolio_alerts (
                    user_id, alert_type, severity, title, description, data
                ) VALUES (
                    p_user_id,
                    'rebalancing_needed',
                    CASE WHEN v_difference > 10 THEN 'critical' ELSE 'warning' END,
                    'Rééquilibrage nécessaire : ' || v_account.name,
                    'L''allocation actuelle (' || ROUND(v_current_allocation, 1) || 
                    '%) s''écarte de l''objectif (' || v_account.target_allocation_percent || '%)',
                    jsonb_build_object(
                        'account_id', v_account.id,
                        'current_allocation', v_current_allocation,
                        'target_allocation', v_account.target_allocation_percent,
                        'difference', v_difference
                    )
                )
                ON CONFLICT DO NOTHING;
            END IF;
        END;
    END LOOP;
END;
$$;

-- ----------------------------------------------------------------------------
-- TRIGGER: Mettre à jour updated_at
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_wealth_accounts_updated_at
    BEFORE UPDATE ON wealth_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_retirement_projections_updated_at
    BEFORE UPDATE ON retirement_projections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_succession_simulations_updated_at
    BEFORE UPDATE ON succession_simulations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_investment_goals_updated_at
    BEFORE UPDATE ON investment_goals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- RLS POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE wealth_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE wealth_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE wealth_valuations ENABLE ROW LEVEL SECURITY;
ALTER TABLE retirement_projections ENABLE ROW LEVEL SECURITY;
ALTER TABLE succession_simulations ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE investment_goals ENABLE ROW LEVEL SECURITY;

-- Wealth accounts
CREATE POLICY "Users can manage own wealth accounts"
    ON wealth_accounts FOR ALL
    USING (user_id = auth.uid());

-- Wealth transactions
CREATE POLICY "Users can manage own wealth transactions"
    ON wealth_transactions FOR ALL
    USING (user_id = auth.uid());

-- Wealth valuations
CREATE POLICY "Users can manage own wealth valuations"
    ON wealth_valuations FOR ALL
    USING (user_id = auth.uid());

-- Retirement projections
CREATE POLICY "Users can manage own retirement projections"
    ON retirement_projections FOR ALL
    USING (user_id = auth.uid());

-- Succession simulations
CREATE POLICY "Users can manage own succession simulations"
    ON succession_simulations FOR ALL
    USING (user_id = auth.uid());

-- Portfolio alerts
CREATE POLICY "Users can view own portfolio alerts"
    ON portfolio_alerts FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can update own portfolio alerts"
    ON portfolio_alerts FOR UPDATE
    USING (user_id = auth.uid());

-- Investment goals
CREATE POLICY "Users can manage own investment goals"
    ON investment_goals FOR ALL
    USING (user_id = auth.uid());