-- Table pour les conversations avec le coach IA
CREATE TABLE IF NOT EXISTS coach_conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Titre généré automatiquement ou défini par l'utilisateur
    title TEXT DEFAULT 'Nouvelle conversation',
    
    -- Résumé de la conversation (pour compression de mémoire quand >20 messages)
    summary TEXT,
    
    -- Langue de la conversation
    language TEXT DEFAULT 'fr' CHECK (language IN ('fr', 'en')),
    
    -- Nombre de messages
    message_count INTEGER DEFAULT 0,
    
    -- Dates
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Métadonnées (modèle utilisé, etc.)
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_coach_conversations_user_id 
    ON coach_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_coach_conversations_last_message_at 
    ON coach_conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_coach_conversations_user_recent 
    ON coach_conversations(user_id, last_message_at DESC);

-- Table pour les messages individuels
CREATE TABLE IF NOT EXISTS coach_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID REFERENCES coach_conversations(id) ON DELETE CASCADE NOT NULL,
    
    -- Rôle du message
    role TEXT NOT NULL CHECK (role IN ('user', 'coach', 'system')),
    
    -- Contenu texte
    content TEXT NOT NULL,
    
    -- Contenu enrichi (cartes contextuelles)
    rich_content JSONB,
    
    -- Actions suggérées
    actions JSONB,
    
    -- Date de création
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Métadonnées (tokens utilisés, temps de réponse, etc.)
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_coach_messages_conversation_id 
    ON coach_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_coach_messages_created_at 
    ON coach_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_coach_messages_conversation_created 
    ON coach_messages(conversation_id, created_at ASC);

-- Table pour le suivi des limites d'utilisation (rate limiting)
CREATE TABLE IF NOT EXISTS coach_usage_limits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Date du jour
    date DATE DEFAULT CURRENT_DATE NOT NULL,
    
    -- Nombre de messages envoyés ce jour
    message_count INTEGER DEFAULT 0,
    
    -- Limite quotidienne
    daily_limit INTEGER DEFAULT 100,
    
    -- Date de mise à jour
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, date)
);

-- Index pour les performances
CREATE INDEX IF NOT EXISTS idx_coach_usage_limits_user_date 
    ON coach_usage_limits(user_id, date);

-- Fonction pour incrémenter le compteur de messages
CREATE OR REPLACE FUNCTION increment_coach_usage(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_count INTEGER;
    v_limit INTEGER;
BEGIN
    -- Insérer ou mettre à jour l'entrée du jour
    INSERT INTO coach_usage_limits (user_id, date, message_count)
    VALUES (p_user_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, date)
    DO UPDATE SET 
        message_count = coach_usage_limits.message_count + 1,
        updated_at = NOW()
    RETURNING message_count, daily_limit INTO v_count, v_limit;
    
    -- Retourner true si sous la limite
    RETURN v_count <= v_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour mettre à jour le compteur de messages dans la conversation
CREATE OR REPLACE FUNCTION update_conversation_message_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE coach_conversations
        SET message_count = message_count + 1,
            last_message_at = NEW.created_at
        WHERE id = NEW.conversation_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE coach_conversations
        SET message_count = message_count - 1
        WHERE id = OLD.conversation_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour automatiquement le compteur
DROP TRIGGER IF EXISTS trg_update_message_count ON coach_messages;
CREATE TRIGGER trg_update_message_count
    AFTER INSERT OR DELETE ON coach_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_message_count();

-- Fonction pour générer un résumé quand il y a trop de messages
CREATE OR REPLACE FUNCTION maybe_summarize_conversation(p_conversation_id UUID)
RETURNS VOID AS $$
DECLARE
    v_message_count INTEGER;
    v_summary TEXT;
BEGIN
    -- Compter les messages
    SELECT COUNT(*) INTO v_message_count
    FROM coach_messages
    WHERE conversation_id = p_conversation_id;
    
    -- Si plus de 20 messages, marquer pour résumé
    IF v_message_count > 20 THEN
        -- Mettre à jour la conversation pour indiquer qu'un résumé est nécessaire
        UPDATE coach_conversations
        SET metadata = jsonb_set(
            COALESCE(metadata, '{}'::jsonb),
            '{needs_summary}',
            'true'::jsonb
        )
        WHERE id = p_conversation_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies

-- Enable RLS
ALTER TABLE coach_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE coach_usage_limits ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own conversations
CREATE POLICY "Users can view own conversations"
    ON coach_conversations
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can only insert their own conversations
CREATE POLICY "Users can insert own conversations"
    ON coach_conversations
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own conversations
CREATE POLICY "Users can update own conversations"
    ON coach_conversations
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Users can only delete their own conversations
CREATE POLICY "Users can delete own conversations"
    ON coach_conversations
    FOR DELETE
    USING (auth.uid() = user_id);

-- Policy: Users can only see messages from their conversations
CREATE POLICY "Users can view messages from own conversations"
    ON coach_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM coach_conversations
            WHERE id = coach_messages.conversation_id
            AND user_id = auth.uid()
        )
    );

-- Policy: Users can only insert messages in their conversations
CREATE POLICY "Users can insert messages in own conversations"
    ON coach_messages
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM coach_conversations
            WHERE id = coach_messages.conversation_id
            AND user_id = auth.uid()
        )
    );

-- Policy: Users can only delete messages from their conversations
CREATE POLICY "Users can delete messages from own conversations"
    ON coach_messages
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM coach_conversations
            WHERE id = coach_messages.conversation_id
            AND user_id = auth.uid()
        )
    );

-- Policy: Users can only see their own usage limits
CREATE POLICY "Users can view own usage limits"
    ON coach_usage_limits
    FOR SELECT
    USING (auth.uid() = user_id);

-- Commentaires
COMMENT ON TABLE coach_conversations IS 'Conversations entre utilisateurs et le coach IA';
COMMENT ON TABLE coach_messages IS 'Messages individuels dans les conversations';
COMMENT ON TABLE coach_usage_limits IS 'Suivi des limites d utilisation quotidiennes';
