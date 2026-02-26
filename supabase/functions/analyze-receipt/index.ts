import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Configuration CORS
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Prompt pour l'extraction des informations du reçu
const PROMPT_EXTRACTION = `Tu es un expert en analyse de tickets de caisse et factures.
Analyse cette image et retourne UNIQUEMENT un JSON valide avec les champs suivants:
{
  "amount": number (montant total TTC, négatif pour une dépense, positif pour un remboursement),
  "merchant": string (nom du commerce/marchand),
  "date": string (ISO 8601, utilise la date du jour si non visible: ${new Date().toISOString()}),
  "category": string (une de: food/transport/housing/health/entertainment/shopping/subscription/restaurant/travel/utilities/other),
  "subcategory": string (sous-catégorie spécifique si identifiable),
  "description": string (courte description, max 50 caractères),
  "currency": string (EUR par défaut, ou devise détectée),
  "items": array (optionnel, liste des articles avec {name, amount, quantity} si lisible),
  "confidence": number (0.0 à 1.0, niveau de confiance dans l'extraction)
}

Règles:
- Le montant doit être négatif pour une dépense, positif pour un remboursement
- La catégorie doit être choisie parmi la liste fournie
- Si ce n'est pas un reçu ou une facture, retourne {"error": "not_a_receipt"}
- Si l'image est floue ou illisible, retourne {"error": "image_not_clear"}
- Toujours retourner un JSON valide, même en cas d'erreur`;

// Prompt pour l'analyse vocale
const PROMPT_VOICE = (transcript: string) => `Tu es un expert en extraction d'informations financières.
Analyse ce texte et retourne UNIQUEMENT un JSON valide:
"${transcript}"

Retourne:
{
  "amount": number (montant, négatif pour dépense),
  "merchant": string (nom du commerce si mentionné),
  "category": string (food/transport/housing/health/entertainment/shopping/subscription/restaurant/travel/utilities/other),
  "description": string (description courte),
  "confidence": number (0.0 à 1.0)
}

Exemples:
- "J'ai dépensé 25 euros au McDo" → {"amount": -25, "merchant": "McDonald's", "category": "food", "description": "Repas McDo", "confidence": 0.95}
- "Essence 60€ Total" → {"amount": -60, "merchant": "Total", "category": "transport", "description": "Essence", "confidence": 0.9}`;

interface RequestBody {
  imageUrl?: string;
  imageBase64?: string;
  transcript?: string;
  userId: string;
}

serve(async (req) => {
  // Gérer les requêtes OPTIONS (CORS preflight)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Vérifier l'authentification
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Créer le client Supabase
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // Vérifier le JWT
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser(jwt);
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Parser le body
    const body: RequestBody = await req.json();
    const { imageUrl, imageBase64, transcript, userId } = body;

    // Vérifier que l'userId correspond à l'utilisateur authentifié
    if (userId !== user.id) {
      return new Response(
        JSON.stringify({ error: 'User ID mismatch' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    let result: any;

    // Mode dictée vocale
    if (transcript) {
      result = await analyzeVoice(transcript);
    }
    // Mode scan d'image
    else if (imageUrl || imageBase64) {
      result = await analyzeReceipt(imageUrl, imageBase64);
    }
    else {
      return new Response(
        JSON.stringify({ error: 'Missing imageUrl, imageBase64, or transcript' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Si l'analyse a réussi et n'est pas une erreur, insérer dans la base
    if (!result.error && result.amount !== undefined) {
      const { error: insertError } = await supabaseClient
        .from('transactions')
        .insert({
          user_id: userId,
          amount: result.amount,
          merchant: result.merchant,
          category: result.category,
          subcategory: result.subcategory,
          description: result.description,
          date: result.date || new Date().toISOString(),
          currency: result.currency || 'EUR',
          source: transcript ? 'voice' : 'scan',
          scan_image_url: imageUrl,
          ai_confidence: result.confidence || 0,
          metadata: {
            items: result.items || [],
            raw_analysis: result,
          },
        });

      if (insertError) {
        console.error('Error inserting transaction:', insertError);
        return new Response(
          JSON.stringify({ error: 'Failed to save transaction', details: insertError }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }
    }

    return new Response(
      JSON.stringify(result),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('Error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

/**
 * Analyse une image de reçu avec OpenAI GPT-4 Vision
 */
async function analyzeReceipt(imageUrl?: string, imageBase64?: string): Promise<any> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
  
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured');
  }

  // Préparer le contenu de l'image
  let imageContent: any;
  if (imageBase64) {
    imageContent = {
      type: 'image_url',
      image_url: {
        url: `data:image/jpeg;base64,${imageBase64}`,
        detail: 'high',
      },
    };
  } else if (imageUrl) {
    imageContent = {
      type: 'image_url',
      image_url: {
        url: imageUrl,
        detail: 'high',
      },
    };
  } else {
    throw new Error('No image provided');
  }

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          {
            role: 'system',
            content: 'Tu es un assistant qui analyse des tickets de caisse et retourne uniquement du JSON valide.',
          },
          {
            role: 'user',
            content: [
              imageContent,
              { type: 'text', text: PROMPT_EXTRACTION },
            ],
          },
        ],
        max_tokens: 1000,
        temperature: 0.2,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('OpenAI API error:', error);
      
      // Fallback vers Gemini si OpenAI échoue
      return await analyzeReceiptWithGemini(imageUrl, imageBase64);
    }

    const data = await response.json();
    const content = data.choices[0]?.message?.content;

    if (!content) {
      throw new Error('Empty response from OpenAI');
    }

    // Parser le JSON de la réponse
    return parseJsonResponse(content);

  } catch (error) {
    console.error('Error calling OpenAI:', error);
    // Fallback vers Gemini
    return await analyzeReceiptWithGemini(imageUrl, imageBase64);
  }
}

/**
 * Fallback: Analyse avec Google Gemini
 */
async function analyzeReceiptWithGemini(imageUrl?: string, imageBase64?: string): Promise<any> {
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
  
  if (!geminiApiKey) {
    return { error: 'AI service unavailable', message: 'No API keys configured' };
  }

  try {
    // Note: Gemini API nécessite un format différent pour les images
    // Cette implémentation est simplifiée
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: PROMPT_EXTRACTION },
                imageBase64
                  ? {
                      inlineData: {
                        mimeType: 'image/jpeg',
                        data: imageBase64,
                      },
                    }
                  : { text: `Analyze this receipt image: ${imageUrl}` },
              ],
            },
          ],
        }),
      }
    );

    if (!response.ok) {
      const error = await response.text();
      console.error('Gemini API error:', error);
      return { error: 'AI analysis failed', message: error };
    }

    const data = await response.json();
    const content = data.candidates[0]?.content?.parts[0]?.text;

    if (!content) {
      return { error: 'Empty response from Gemini' };
    }

    return parseJsonResponse(content);

  } catch (error) {
    console.error('Error calling Gemini:', error);
    return { error: 'AI analysis failed', message: error.message };
  }
}

/**
 * Analyse une transcription vocale
 */
async function analyzeVoice(transcript: string): Promise<any> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY');
  
  if (!openaiApiKey) {
    return { error: 'AI service unavailable' };
  }

  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'user',
            content: PROMPT_VOICE(transcript),
          },
        ],
        max_tokens: 500,
        temperature: 0.2,
        response_format: { type: 'json_object' },
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      console.error('OpenAI API error:', error);
      return { error: 'Voice analysis failed', message: error };
    }

    const data = await response.json();
    const content = data.choices[0]?.message?.content;

    if (!content) {
      return { error: 'Empty response from AI' };
    }

    return JSON.parse(content);

  } catch (error) {
    console.error('Error analyzing voice:', error);
    return { error: 'Voice analysis failed', message: error.message };
  }
}

/**
 * Parse la réponse JSON de l'IA
 */
function parseJsonResponse(content: string): any {
  try {
    // Nettoyer la réponse (enlever les balises markdown si présentes)
    let cleanContent = content.trim();
    
    if (cleanContent.startsWith('```json')) {
      cleanContent = cleanContent.replace(/```json\n?/, '').replace(/```$/, '');
    } else if (cleanContent.startsWith('```')) {
      cleanContent = cleanContent.replace(/```\n?/, '').replace(/```$/, '');
    }

    return JSON.parse(cleanContent);
  } catch (error) {
    console.error('Error parsing JSON:', error, 'Content:', content);
    return { error: 'Invalid JSON response', raw: content };
  }
}
