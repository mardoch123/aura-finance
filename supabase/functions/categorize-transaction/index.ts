import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Edge Function pour catégoriser les transactions avec IA
// Utilise GPT-4 pour les cas complexes

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CategorizationRequest {
  description: string
  merchant_name?: string
  amount?: number
  user_id?: string
}

interface CategorizationResult {
  category: string
  subcategory: string
  confidence: number
  keywords: string[]
  merchant_logo?: string
  ai_used: boolean
}

// Base de connaissances locale (fallback si l'IA échoue)
const keywordCategories: Record<string, { category: string; subcategory: string; confidence: number }> = {
  // Alimentation
  'restaurant': { category: 'food', subcategory: 'restaurant', confidence: 0.9 },
  'mcdo': { category: 'food', subcategory: 'fast_food', confidence: 0.95 },
  'kfc': { category: 'food', subcategory: 'fast_food', confidence: 0.95 },
  'burger': { category: 'food', subcategory: 'fast_food', confidence: 0.85 },
  'pizza': { category: 'food', subcategory: 'restaurant', confidence: 0.85 },
  'sushi': { category: 'food', subcategory: 'restaurant', confidence: 0.85 },
  'supermarche': { category: 'food', subcategory: 'groceries', confidence: 0.9 },
  'carrefour': { category: 'food', subcategory: 'groceries', confidence: 0.95 },
  'auchan': { category: 'food', subcategory: 'groceries', confidence: 0.95 },
  'leclerc': { category: 'food', subcategory: 'groceries', confidence: 0.95 },
  'lidl': { category: 'food', subcategory: 'groceries', confidence: 0.95 },
  'monoprix': { category: 'food', subcategory: 'groceries', confidence: 0.95 },
  'franprix': { category: 'food', subcategory: 'groceries', confidence: 0.95 },
  
  // Transport
  'uber': { category: 'transport', subcategory: 'taxi', confidence: 0.95 },
  'bolt': { category: 'transport', subcategory: 'taxi', confidence: 0.95 },
  'taxi': { category: 'transport', subcategory: 'taxi', confidence: 0.9 },
  'sncf': { category: 'transport', subcategory: 'train', confidence: 0.95 },
  'train': { category: 'transport', subcategory: 'train', confidence: 0.9 },
  'metro': { category: 'transport', subcategory: 'public', confidence: 0.9 },
  'bus': { category: 'transport', subcategory: 'public', confidence: 0.9 },
  'total': { category: 'transport', subcategory: 'fuel', confidence: 0.9 },
  'shell': { category: 'transport', subcategory: 'fuel', confidence: 0.9 },
  'essence': { category: 'transport', subcategory: 'fuel', confidence: 0.9 },
  'parking': { category: 'transport', subcategory: 'parking', confidence: 0.9 },
  
  // Shopping
  'amazon': { category: 'shopping', subcategory: 'online', confidence: 0.95 },
  'fnac': { category: 'shopping', subcategory: 'electronics', confidence: 0.9 },
  'darty': { category: 'shopping', subcategory: 'electronics', confidence: 0.9 },
  'boulanger': { category: 'shopping', subcategory: 'electronics', confidence: 0.9 },
  'zara': { category: 'shopping', subcategory: 'clothing', confidence: 0.9 },
  'h&m': { category: 'shopping', subcategory: 'clothing', confidence: 0.9 },
  'uniqlo': { category: 'shopping', subcategory: 'clothing', confidence: 0.9 },
  'nike': { category: 'shopping', subcategory: 'clothing', confidence: 0.9 },
  'decathlon': { category: 'shopping', subcategory: 'sports', confidence: 0.95 },
  
  // Logement
  'edf': { category: 'housing', subcategory: 'energy', confidence: 0.95 },
  'engie': { category: 'housing', subcategory: 'energy', confidence: 0.95 },
  'loyer': { category: 'housing', subcategory: 'rent', confidence: 0.95 },
  
  // Abonnements
  'netflix': { category: 'subscriptions', subcategory: 'streaming', confidence: 0.95 },
  'spotify': { category: 'subscriptions', subcategory: 'music', confidence: 0.95 },
  'disney': { category: 'subscriptions', subcategory: 'streaming', confidence: 0.95 },
  'prime': { category: 'subscriptions', subcategory: 'streaming', confidence: 0.9 },
  'youtube': { category: 'subscriptions', subcategory: 'streaming', confidence: 0.9 },
  'canal': { category: 'subscriptions', subcategory: 'tv', confidence: 0.95 },
  'orange': { category: 'subscriptions', subcategory: 'telecom', confidence: 0.9 },
  'sfr': { category: 'subscriptions', subcategory: 'telecom', confidence: 0.9 },
  'bouygues': { category: 'subscriptions', subcategory: 'telecom', confidence: 0.9 },
  'free': { category: 'subscriptions', subcategory: 'telecom', confidence: 0.9 },
  
  // Santé
  'pharmacie': { category: 'health', subcategory: 'pharmacy', confidence: 0.95 },
  'doctolib': { category: 'health', subcategory: 'medical', confidence: 0.9 },
  
  // Loisirs
  'cinema': { category: 'entertainment', subcategory: 'cinema', confidence: 0.95 },
  'booking': { category: 'entertainment', subcategory: 'travel', confidence: 0.9 },
  'airbnb': { category: 'entertainment', subcategory: 'travel', confidence: 0.95 },
  
  // Revenus
  'salaire': { category: 'income', subcategory: 'salary', confidence: 0.95 },
  'virement': { category: 'income', subcategory: 'transfer', confidence: 0.7 },
}

serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { description, merchant_name, amount, user_id } = await req.json() as CategorizationRequest

    if (!description) {
      return new Response(
        JSON.stringify({ error: 'Description is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 1. Essayer la catégorisation par mots-clés (rapide et gratuit)
    const keywordResult = categorizeByKeywords(description, merchant_name)
    if (keywordResult.confidence > 0.8) {
      return new Response(
        JSON.stringify({ ...keywordResult, ai_used: false }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Essayer la catégorisation par IA (GPT-4) si disponible
    try {
      const aiResult = await categorizeWithAI(description, merchant_name, amount)
      return new Response(
        JSON.stringify({ ...aiResult, ai_used: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } catch (aiError) {
      // Fallback sur le résultat des mots-clés
      return new Response(
        JSON.stringify({ ...keywordResult, ai_used: false }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

function categorizeByKeywords(description: string, merchantName?: string): CategorizationResult {
  const normalizedDesc = normalizeText(description)
  const normalizedMerchant = merchantName ? normalizeText(merchantName) : ''
  const words = [...normalizedDesc.split(' '), ...normalizedMerchant.split(' ')]
  
  let bestMatch: { category: string; subcategory: string; confidence: number; keyword: string } | null = null
  
  for (const word of words) {
    const match = keywordCategories[word]
    if (match && (!bestMatch || match.confidence > bestMatch.confidence)) {
      bestMatch = { ...match, keyword: word }
    }
  }
  
  if (bestMatch) {
    return {
      category: bestMatch.category,
      subcategory: bestMatch.subcategory,
      confidence: bestMatch.confidence,
      keywords: [bestMatch.keyword],
      ai_used: false
    }
  }
  
  // Catégorisation par défaut basée sur le montant
  if (amount && amount > 0) {
    return {
      category: 'income',
      subcategory: 'other',
      confidence: 0.5,
      keywords: [],
      ai_used: false
    }
  }
  
  return {
    category: 'other',
    subcategory: 'unknown',
    confidence: 0.3,
    keywords: [],
    ai_used: false
  }
}

async function categorizeWithAI(
  description: string,
  merchantName?: string,
  amount?: number
): Promise<CategorizationResult> {
  const apiKey = Deno.env.get('OPENAI_API_KEY')
  
  if (!apiKey) {
    throw new Error('OpenAI API key not configured')
  }
  
  const prompt = `Analyse cette transaction bancaire et catégorise-la.

Description: ${description}
${merchantName ? `Marchand: ${merchantName}` : ''}
${amount ? `Montant: ${amount}€` : ''}

Réponds UNIQUEMENT en JSON avec ce format:
{
  "category": "food|transport|shopping|housing|subscriptions|health|entertainment|income|other",
  "subcategory": "sous-catégorie spécifique",
  "confidence": 0.85,
  "keywords": ["mot1", "mot2"]
}

Catégories possibles:
- food: restaurant, fast_food, groceries, coffee, delivery
- transport: taxi, train, public, fuel, parking
- shopping: online, electronics, clothing, sports
- housing: rent, energy, insurance, maintenance
- subscriptions: streaming, music, telecom, gym
- health: pharmacy, medical, dental, vision
- entertainment: cinema, travel, events, games
- income: salary, freelance, refund, gift
- other: unknown, fees, transfer`

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'Tu es un assistant de catégorisation de transactions bancaires. Réponds uniquement en JSON.' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
      max_tokens: 200,
    }),
  })
  
  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status}`)
  }
  
  const data = await response.json()
  const content = data.choices[0]?.message?.content
  
  if (!content) {
    throw new Error('Empty response from OpenAI')
  }
  
  // Extraire le JSON de la réponse
  const jsonMatch = content.match(/\{[\s\S]*\}/)
  if (!jsonMatch) {
    throw new Error('Invalid JSON response from OpenAI')
  }
  
  const result = JSON.parse(jsonMatch[0])
  
  return {
    category: result.category || 'other',
    subcategory: result.subcategory || 'unknown',
    confidence: result.confidence || 0.7,
    keywords: result.keywords || [],
    ai_used: true
  }
}

function normalizeText(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '') // Enlever les accents
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
}
