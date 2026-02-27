-- ============================================================================
-- MIGRATION 016: Rapports PDF/Excel Personnalisés
-- Export fiscal, analytique et dossiers de prêt
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE: report_templates
-- Templates de rapports disponibles
-- ----------------------------------------------------------------------------
CREATE TABLE report_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Identification
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    
    -- Type de rapport
    type TEXT NOT NULL CHECK(type IN (
        'tax_declaration',     -- Déclaration fiscale
        'annual_analysis',     -- Analyse annuelle
        'loan_application',    -- Dossier de prêt
        'monthly_summary',     -- Résumé mensuel
        'category_breakdown',  -- Répartition par catégorie
        'custom'               -- Personnalisé
    )),
    
    -- Configuration du template
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- {
    --   "sections": ["summary", "charts", "transactions", "categories"],
    --   "default_period": "last_month",
    --   "include_charts": true,
    --   "include_receipts": false,
    --   "fiscal_categories": ["professional", "medical", "donation"]
    -- }
    
    -- Format de sortie
    available_formats TEXT[] DEFAULT ARRAY['pdf', 'excel'],
    
    -- Visuel
    icon TEXT DEFAULT 'description',
    color TEXT DEFAULT '#E8A86C',
    
    -- Accès
    is_pro_feature BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Ordre d'affichage
    display_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- TABLE: generated_reports
-- Rapports générés par les utilisateurs
-- ----------------------------------------------------------------------------
CREATE TABLE generated_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    template_id UUID REFERENCES report_templates(id) ON DELETE SET NULL,
    
    -- Informations du rapport
    name TEXT NOT NULL,
    description TEXT,
    
    -- Période couverte
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    
    -- Configuration utilisée
    config JSONB DEFAULT '{}'::jsonb,
    
    -- Fichiers générés
    pdf_url TEXT,
    excel_url TEXT,
    
    -- Statut
    status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'generating', 'completed', 'failed', 'expired')),
    
    -- Métadonnées
    file_size_bytes INTEGER,
    page_count INTEGER,
    transaction_count INTEGER,
    
    -- Envoi email
    email_sent_to TEXT,
    email_sent_at TIMESTAMPTZ,
    
    -- Téléchargements
    download_count INTEGER DEFAULT 0,
    last_downloaded_at TIMESTAMPTZ,
    
    -- Expiration (30 jours par défaut)
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_generated_reports_user ON generated_reports(user_id);
CREATE INDEX idx_generated_reports_status ON generated_reports(status);
CREATE INDEX idx_generated_reports_created ON generated_reports(created_at DESC);

-- ----------------------------------------------------------------------------
-- TABLE: scheduled_reports
-- Rapports programmés (envoi automatique)
-- ----------------------------------------------------------------------------
CREATE TABLE scheduled_reports (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    template_id UUID REFERENCES report_templates(id) ON DELETE CASCADE NOT NULL,
    
    -- Configuration
    name TEXT NOT NULL,
    frequency TEXT NOT NULL CHECK(frequency IN ('weekly', 'monthly', 'quarterly', 'yearly')),
    
    -- Options
    email_recipients TEXT[] DEFAULT ARRAY[]::TEXT[],
    include_pdf BOOLEAN DEFAULT TRUE,
    include_excel BOOLEAN DEFAULT FALSE,
    
    -- Prochain envoi
    next_send_at TIMESTAMPTZ NOT NULL,
    last_sent_at TIMESTAMPTZ,
    
    -- Statut
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_scheduled_reports_user ON scheduled_reports(user_id);
CREATE INDEX idx_scheduled_reports_next ON scheduled_reports(next_send_at) WHERE is_active = TRUE;

-- ----------------------------------------------------------------------------
-- TABLE: report_favorites
-- Rapports favoris de l'utilisateur
-- ----------------------------------------------------------------------------
CREATE TABLE report_favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    template_id UUID REFERENCES report_templates(id) ON DELETE CASCADE NOT NULL,
    
    -- Configuration personnalisée
    custom_config JSONB DEFAULT '{}'::jsonb,
    
    UNIQUE(user_id, template_id)
);

-- ----------------------------------------------------------------------------
-- FONCTIONS
-- ----------------------------------------------------------------------------

-- Mise à jour automatique de updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_generated_reports_updated_at
    BEFORE UPDATE ON generated_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_scheduled_reports_updated_at
    BEFORE UPDATE ON scheduled_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Nettoyage des rapports expirés
CREATE OR REPLACE FUNCTION cleanup_expired_reports()
RETURNS void AS $$
BEGIN
    UPDATE generated_reports
    SET status = 'expired'
    WHERE status = 'completed'
    AND expires_at < NOW();
END;
$$ language 'plpgsql';

-- ----------------------------------------------------------------------------
-- POLITIQUES RLS
-- ----------------------------------------------------------------------------

ALTER TABLE report_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE generated_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_favorites ENABLE ROW LEVEL SECURITY;

-- Templates: tout le monde peut voir les actifs
CREATE POLICY report_templates_select ON report_templates
    FOR SELECT USING (is_active = TRUE);

-- Generated reports: utilisateur voit ses propres rapports
CREATE POLICY generated_reports_select ON generated_reports
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY generated_reports_insert ON generated_reports
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY generated_reports_update ON generated_reports
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY generated_reports_delete ON generated_reports
    FOR DELETE USING (user_id = auth.uid());

-- Scheduled reports: utilisateur gère ses propres rapports programmés
CREATE POLICY scheduled_reports_select ON scheduled_reports
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY scheduled_reports_insert ON scheduled_reports
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY scheduled_reports_update ON scheduled_reports
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY scheduled_reports_delete ON scheduled_reports
    FOR DELETE USING (user_id = auth.uid());

-- Report favorites: utilisateur gère ses favoris
CREATE POLICY report_favorites_select ON report_favorites
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY report_favorites_insert ON report_favorites
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY report_favorites_delete ON report_favorites
    FOR DELETE USING (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- DONNÉES DE DÉMONSTRATION
-- ----------------------------------------------------------------------------

INSERT INTO report_templates (code, name, description, type, config, available_formats, icon, color, is_pro_feature, display_order) VALUES
(
    'tax_declaration_2042',
    'Déclaration Fiscale 2042',
    'Rapport complet pour votre déclaration d\'impôts avec catégorisation automatique des déductions',
    'tax_declaration',
    '{
        "sections": ["summary", "deductions", "professional_expenses", "donations", "medical_expenses"],
        "default_period": "last_year",
        "include_charts": true,
        "fiscal_categories": ["professional", "medical", "donation", "childcare", "real_estate"]
    }'::jsonb,
    ARRAY['pdf', 'excel'],
    'account_balance',
    '#7DC983',
    TRUE,
    1
),
(
    'annual_analysis',
    'Analyse Annuelle',
    'Vue d\'ensemble complète de votre année financière avec tendances et insights',
    'annual_analysis',
    '{
        "sections": ["executive_summary", "income_analysis", "expense_breakdown", "savings_rate", "goals_progress", "predictions"],
        "default_period": "last_year",
        "include_charts": true,
        "include_predictions": true
    }'::jsonb,
    ARRAY['pdf', 'excel'],
    'analytics',
    '#E8A86C',
    FALSE,
    2
),
(
    'loan_application',
    'Dossier de Prêt',
    'Document professionnel pour votre demande de prêt immobilier ou consommation',
    'loan_application',
    '{
        "sections": ["financial_summary", "income_verification", "expense_analysis", "debt_ratio", "savings_capacity"],
        "default_period": "last_3_months",
        "include_charts": true,
        "bank_format": true
    }'::jsonb,
    ARRAY['pdf'],
    'home',
    '#6B8DD6',
    TRUE,
    3
),
(
    'monthly_summary',
    'Résumé Mensuel',
    'Rapport mensuel détaillé de vos revenus et dépenses',
    'monthly_summary',
    '{
        "sections": ["summary", "transactions", "category_breakdown", "budget_variance"],
        "default_period": "last_month",
        "include_charts": true
    }'::jsonb,
    ARRAY['pdf', 'excel'],
    'calendar_month',
    '#C4714A',
    FALSE,
    4
),
(
    'category_breakdown',
    'Répartition par Catégorie',
    'Analyse détaillée de vos dépenses par catégorie',
    'category_breakdown',
    '{
        "sections": ["category_totals", "trends", "comparison"],
        "default_period": "last_month",
        "include_charts": true,
        "include_trends": true
    }'::jsonb,
    ARRAY['pdf', 'excel'],
    'pie_chart',
    '#9B7ED8',
    FALSE,
    5
);
