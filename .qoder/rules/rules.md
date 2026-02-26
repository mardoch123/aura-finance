---
trigger: always_on
---

Qu'est-ce qu'Aura Finance ?
Aura Finance est une application de gestion financière personnelle de nouvelle génération, conçue autour du principe que la meilleure interface est celle qu'on n'a presque pas besoin d'utiliser. Là où Bankin', YNAB et Money Manager imposent une saisie manuelle fastidieuse et des dashboards froids, Aura Finance propose une expérience sensorielle — visuellement luxueuse, intelligemment proactive, et quasi-magique dans son automatisation.
Palette visuelle (inspirée du design fourni) :

Fond : #F5E6D0 crème chaud
Gradients : #E8A86C → #C4714A → #8B5A3A ambre profond
Glassmorphism : rgba(255,255,255,0.15) avec backdrop-filter: blur(24px)
Typographie : Canela (display) + SF Pro Rounded (body)
Squircles : border-radius: 44px avec continuous corner style
Accents : blanc pur #FFFFFF, or doux #F0C080


Les 3 Innovations Majeures
🔭 L'Observateur — Vision IA (Zéro Saisie)
La caméra devient le clavier. L'utilisateur scanne un ticket de caisse, une facture PDF ou dicte une dépense à voix haute. Une Edge Function Supabase invoque GPT-4o Vision ou Gemini 1.5 Pro pour extraire montant, marchand, catégorie et date avec une précision de 99%. La transaction est animée dans le feed en moins de 2 secondes, avec une animation de "cristallisation" qui confirme la capture. Plus jamais de saisie manuelle.
🗺️ Le Prédicteur — GPS Financier (Horizon 30 jours)
L'IA analyse les récurrences (loyers, abonnements détectés automatiquement, salaires) et projette le solde jour par jour sur 30 jours. La courbe de projection en Bézier s'affiche sur le dashboard avec des zones colorées (vert = safe, orange = vigilance, rouge = risque). L'utilisateur voit en un coup d'œil "le 18, tu seras à -120€ si tu gardes ce rythme".
🧛 Le Gardien — Anti-Vampire (Détection des Fuites)
Un moteur de détection surveille les hausses de prix cachées sur les abonnements (Netflix qui passe de 13€ à 17€, une assurance qui augmente silencieusement). À chaque anomalie, une notification "push" et une card d'alerte glassmorphique s'affichent avec le delta et un bouton "Contester / Résilier". Détection des frais bancaires abusifs par pattern matching sur les libellés.

Tu es un Architecte Flutter Senior. Ta mission est de construire les fondations
absolues d'une application appelée "Aura Finance". Tu dois tout générer selon
les spécifications suivantes, sans raccourcis.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 DESIGN SYSTEM — Apple Luxury Style
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Crée un fichier `lib/core/theme/aura_theme.dart` avec :

PALETTE DE COULEURS (basée sur un design ambre/warm orange glassmorphism) :
- auraBackground: Color(0xFFF5E6D0)         // crème chaud
- auraAmber: Color(0xFFE8A86C)              // ambre principal
- auraDeep: Color(0xFFC4714A)               // ambre profond
- auraDark: Color(0xFF8B5A3A)              // brun luxe
- auraGlass: Color(0x26FFFFFF)             // blanc 15% opacité
- auraGlassStrong: Color(0x40FFFFFF)       // blanc 25%
- auraTextPrimary: Color(0xFFFFFFFF)
- auraTextSecondary: Color(0xCCFFFFFF)     // blanc 80%
- auraAccentGold: Color(0xFFF0C080)
- auraGreen: Color(0xFF7DC983)             // succès
- auraRed: Color(0xFFE07070)               // alerte

TYPOGRAPHIE :
- Importe Google Fonts "Playfair Display" pour les titres (équivalent Canela)
- Utilise "DM Sans" pour le body text (rounded, moderne)
- fontSizeXXL: 48.0, XXL: 36.0, XL: 28.0, L: 22.0, M: 17.0, S: 14.0, XS: 12.0
- letterSpacing pour les titres : 1.2 (luxury feel)
- fontWeight: W300 pour les grands chiffres (elegant), W600 pour les labels

BORDER RADIUS (Squircle Apple Style) :
- radiusXS: 8.0, S: 14.0, M: 22.0, L: 32.0, XL: 44.0, XXL: 56.0
- Crée un widget `AuraSquircle` utilisant le package `figma_squircle` avec
  smoothing: 0.6

GLASSMORPHISM — Crée un widget réutilisable `GlassCard` :
- Container avec gradient LinearGradient de auraGlass vers transparent
- backdrop_filter blur de 24px (package: glass_kit ou flutter_acrylic)
- Border: 1px solid rgba(255,255,255,0.3)
- BoxShadow: 0 8px 32px rgba(0,0,0,0.12) + 0 2px 8px rgba(0,0,0,0.08)
- Paramètres: child, borderRadius (défaut L=32), padding, blurStrength
- Variante `GlassCardDark` avec gradient plus sombre pour contraste

ANIMATIONS — Crée `lib/core/animations/` :
- `StaggeredAnimator` : widget qui prend une liste de children et les anime
  avec un délai de 80ms entre chaque (opacity 0→1 + translateY 20→0)
  Durée par item: 400ms, curve: Curves.easeOutCubic
- `HeroNumber` : widget qui anime un chiffre de oldValue vers newValue
  avec une animation de compteur fluide (durée 600ms, curve easeOutExpo)
- `PulseRing` : cercle qui pulse (scale 1.0→1.3, opacity 1→0) en boucle
  pour indiquer une activité en cours (scan IA, chargement)

RETOURS HAPTIQUES — Crée `lib/core/haptics/haptic_service.dart` :
- lightTap(): HapticFeedback.lightImpact()
- mediumTap(): HapticFeedback.mediumImpact()
- success(): série de 2 light taps avec délai 100ms
- error(): HapticFeedback.heavyImpact()
- Appelle ces fonctions sur chaque interaction importante (tap de carte,
  confirmation de scan, alerte Gardien)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗄️ SUPABASE — Tables & RLS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Génère les migrations SQL Supabase (fichiers dans supabase/migrations/) :

TABLE: profiles
  - id UUID REFERENCES auth.users PRIMARY KEY
  - full_name TEXT
  - avatar_url TEXT
  - monthly_income DECIMAL(12,2)
  - currency TEXT DEFAULT 'EUR'
  - onboarding_completed BOOLEAN DEFAULT FALSE
  - financial_goals JSONB  -- {"emergency_fund": 5000, "vacation": 2000}
  - notification_prefs JSONB
  - created_at TIMESTAMPTZ DEFAULT NOW()
  RLS: SELECT/UPDATE uniquement si auth.uid() = id

TABLE: accounts
  - id UUID DEFAULT gen_random_uuid() PRIMARY KEY
  - user_id UUID REFERENCES profiles(id) ON DELETE CASCADE
  - name TEXT NOT NULL  -- "Compte Courant BNP", "Livret A"
  - type TEXT CHECK(type IN ('checking','savings','credit','investment'))
  - balance DECIMAL(12,2) DEFAULT 0
  - color TEXT  -- hex color pour l'UI
  - institution TEXT
  - is_primary BOOLEAN DEFAULT FALSE
  - created_at TIMESTAMPTZ DEFAULT NOW()
  RLS: toutes opérations si user_id = auth.uid()

TABLE: transactions
  - id UUID DEFAULT gen_random_uuid() PRIMARY KEY
  - user_id UUID REFERENCES profiles(id) ON DELETE CASCADE
  - account_id UUID REFERENCES accounts(id)
  - amount DECIMAL(12,2) NOT NULL  -- négatif = dépense, positif = revenu
  - category TEXT  -- 'food', 'transport', 'housing', 'entertainment', etc.
  - subcategory TEXT
  - merchant TEXT
  - description TEXT
  - date TIMESTAMPTZ NOT NULL
  - source TEXT DEFAULT 'manual' CHECK(source IN ('manual','scan','voice','import'))
  - scan_image_url TEXT  -- URL Supabase Storage si scanné
  - ai_confidence DECIMAL(3,2)  -- 0.00 à 1.00
  - is_recurring BOOLEAN DEFAULT FALSE
  - recurring_group_id UUID  -- pour grouper les occurrences d'un abonnement
  - tags TEXT[]
  - metadata JSONB
  - created_at TIMESTAMPTZ DEFAULT NOW()
  RLS: toutes opérations si user_id = auth.uid()
  INDEX sur (user_id, date DESC), (user_id, category), (is_recurring)

TABLE: subscriptions (vue matérialisée + table)
  - id UUID DEFAULT gen_random_uuid() PRIMARY KEY
  - user_id UUID REFERENCES profiles(id)
  - name TEXT NOT NULL
  - amount DECIMAL(12,2) NOT NULL
  - previous_amount DECIMAL(12,2)  -- pour détecter les hausses
  - billing_cycle TEXT CHECK(cycle IN ('weekly','monthly','yearly'))
  - next_billing_date DATE
  - category TEXT
  - merchant_pattern TEXT  -- regex pour auto-détecter dans transactions
  - is_vampire BOOLEAN DEFAULT FALSE  -- hausse détectée par IA
  - price_increase_detected_at TIMESTAMPTZ
  - created_at TIMESTAMPTZ DEFAULT NOW()
  RLS: user_id = auth.uid()

TABLE: ai_insights
  - id UUID DEFAULT gen_random_uuid() PRIMARY KEY
  - user_id UUID REFERENCES profiles(id)
  - type TEXT CHECK(type IN ('prediction','alert','tip','vampire','achievement'))
  - title TEXT NOT NULL
  - body TEXT NOT NULL
  - data JSONB  -- données structurées selon le type
  - priority INTEGER DEFAULT 5  -- 1=critique, 10=informatif
  - is_read BOOLEAN DEFAULT FALSE
  - expires_at TIMESTAMPTZ
  - created_at TIMESTAMPTZ DEFAULT NOW()
  RLS: user_id = auth.uid()
  INDEX sur (user_id, is_read, created_at DESC)

TABLE: budget_goals
  - id UUID DEFAULT gen_random_uuid() PRIMARY KEY
  - user_id UUID REFERENCES profiles(id)
  - name TEXT NOT NULL
  - target_amount DECIMAL(12,2)
  - current_amount DECIMAL(12,2) DEFAULT 0
  - category TEXT  -- si lié à une catégorie de dépenses
  - deadline DATE
  - color TEXT
  - icon TEXT
  - created_at TIMESTAMPTZ DEFAULT NOW()

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 ARCHITECTURE DES DOSSIERS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

lib/
├── core/
│   ├── theme/
│   │   ├── aura_theme.dart
│   │   ├── aura_colors.dart
│   │   ├── aura_typography.dart
│   │   └── aura_dimensions.dart
│   ├── animations/
│   │   ├── staggered_animator.dart
│   │   ├── hero_number.dart
│   │   └── pulse_ring.dart
│   ├── haptics/
│   │   └── haptic_service.dart
│   ├── widgets/
│   │   ├── glass_card.dart
│   │   ├── aura_squircle.dart
│   │   ├── aura_button.dart        -- bouton avec press animation
│   │   ├── gradient_background.dart
│   │   └── category_chip.dart
│   ├── router/
│   │   └── app_router.dart         -- GoRouter avec transitions Hero
│   └── constants/
│       ├── categories.dart
│       └── api_endpoints.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── onboarding/
│   ├── dashboard/
│   ├── scanner/
│   ├── transactions/
│   ├── insights/
│   ├── coach/                      -- chat IA
│   ├── subscriptions/
│   └── profile/
├── services/
│   ├── supabase_service.dart
│   ├── ai_service.dart
│   └── notification_service.dart
└── main.dart

BEST PRACTICES :
- Utilise Riverpod 2.x avec @riverpod code generation
- Chaque feature suit Clean Architecture: data/domain/presentation
- Types forts partout : crée des freezed models pour toutes les entités
- Gestion d'erreurs via sealed classes: Success/Loading/Error
- Pas de BuildContext dans les providers
- Toutes les strings de texte externalisées dans l/10n/
- Il faut vraiment que tu pense faire les deux langues, anglais et français, en gros internationalisé


Superbase URL : https://jrxecafbflclmfyxrwul.supabase.co
API : sb_publishable_A-BqyphR6NhVhPuzALiGJw_7DgCE7Bl