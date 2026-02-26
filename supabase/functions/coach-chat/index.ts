import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Configuration DeepSeek (prioritaire)
const DEEPSEEK_API_URL = 'https://api.deepseek.com/v1/chat/completions';
const DEEPSEEK_MODEL = 'deepseek-chat'; // ou 'deepseek-reasoner' pour le modèle de raisonnement

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface Message {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

interface FinancialContext {
  currentBalance: number;
  monthlyIncome: number;
  monthlyExpenses: number;
  monthlyBudget?: number;
  topCategories: CategorySpending[];
  subscriptions: SubscriptionInfo[];
  vampires: VampireAlert[];
  goals: GoalInfo[];
  unreadInsights: string[];
}

interface CategorySpending {
  category: string;
  amount: number;
  percentage: number;
}

interface SubscriptionInfo {
  id: string;
  name: string;
  amount: number;
  billingCycle: string;
  isVampire: boolean;
}

interface VampireAlert {
  subscriptionId: string;
  name: string;
  oldAmount: number;
  newAmount: number;
}

interface GoalInfo {
  id: string;
  name: string;
  currentAmount: number;
  targetAmount: number;
  progressPercentage: number;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { userId, message, conversationId, conversationHistory } = await req.json();

    if (!userId || !message) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Récupération des clés API
    const deepseekApiKey = Deno.env.get('DEEPSEEK_API_KEY') ?? '';
    const openaiApiKey = Deno.env.get('OPENAI_API_KEY') ?? '';
    
    // Vérifier qu'au moins une clé est disponible
    if (!deepseekApiKey && !openaiApiKey) {
      return new Response(
        JSON.stringify({ error: 'No AI API key configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Fetch financial context
    const financialContext = await fetchFinancialContext(supabaseClient, userId);

    // Build system prompt
    const systemPrompt = buildSystemPrompt(financialContext);

    // Prepare messages
    const messages: Message[] = [
      { role: 'system', content: systemPrompt },
      ...conversationHistory.map((h: any) => ({
        role: h.role as 'user' | 'assistant',
        content: h.content,
      })),
      { role: 'user', content: message },
    ];

    // Essayer DeepSeek d'abord, fallback sur OpenAI
    let stream: ReadableStream;
    let usingFallback = false;
    
    try {
      if (deepseekApiKey) {
        console.log('Using DeepSeek API...');
        stream = await streamDeepSeek(deepseekApiKey, messages);
      } else {
        throw new Error('DeepSeek API key not available');
      }
    } catch (deepseekError) {
      console.warn('DeepSeek failed, falling back to OpenAI:', deepseekError);
      usingFallback = true;
      
      if (!openaiApiKey) {
        throw new Error('No fallback AI available');
      }
      
      stream = await streamOpenAI(openaiApiKey, messages);
    }

    // Create response stream
    const responseStream = new ReadableStream({
      async start(controller) {
        let fullContent = '';
        let actions: any[] = [];

        const reader = stream.getReader();
                
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
                  
          // Parser les données SSE
          const lines = new TextDecoder().decode(value).split('\n');
                  
          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const data = line.slice(6);
                      
              if (data === '[DONE]') continue;
                      
              try {
                const parsed = JSON.parse(data);
                const content = parsed.choices?.[0]?.delta?.content || 
                               parsed.choices?.[0]?.text || '';
                        
                if (content) {
                  fullContent += content;
                          
                  // Send token to client
                  controller.enqueue(
                    new TextEncoder().encode(
                      `data: ${JSON.stringify({ type: 'token', content })}\n\n`
                    )
                  );
                }
              } catch (e) {
                // Ignorer les lignes malformées
              }
            }
          }
        }

        // Parse actions from response
        const actionMatch = fullContent.match(/<action>(.+?)<\/action>/s);
        if (actionMatch) {
          try {
            const actionData = JSON.parse(actionMatch[1]);
            actions = Array.isArray(actionData) ? actionData : [actionData];
            
            // Send actions to client
            controller.enqueue(
              new TextEncoder().encode(
                `data: ${JSON.stringify({ type: 'actions', actions })}\n\n`
              )
            );
          } catch (e) {
            console.error('Error parsing actions:', e);
          }
        }

        // Clean content (remove action tags)
        const cleanContent = fullContent.replace(/<action>.+?<\/action>/s, '').trim();

        // Save message to database
        await saveMessage(supabaseClient, conversationId, userId, cleanContent, actions);

        // Envoyer info sur l'API utilisée
        if (usingFallback) {
          controller.enqueue(
            new TextEncoder().encode(
              `data: ${JSON.stringify({ type: 'metadata', usingFallback: true })}\n\n`
            )
          );
        }
        
        // Send completion signal
        controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'));
        controller.close();
      },
    });

    return new Response(responseStream, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });

  } catch (error) {
    console.error('Error in coach-chat:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function fetchFinancialContext(supabase: any, userId: string): Promise<FinancialContext> {
  // Get current balance
  const { data: accounts } = await supabase
    .from('accounts')
    .select('balance')
    .eq('user_id', userId);

  const currentBalance = accounts?.reduce((sum: number, acc: any) => sum + (acc.balance || 0), 0) || 0;

  // Get monthly income and expenses
  const startOfMonth = new Date();
  startOfMonth.setDate(1);
  startOfMonth.setHours(0, 0, 0, 0);

  const { data: transactions } = await supabase
    .from('transactions')
    .select('amount, category')
    .eq('user_id', userId)
    .gte('date', startOfMonth.toISOString());

  let monthlyIncome = 0;
  let monthlyExpenses = 0;
  const categoryMap = new Map<string, number>();

  transactions?.forEach((t: any) => {
    if (t.amount > 0) {
      monthlyIncome += t.amount;
    } else {
      monthlyExpenses += Math.abs(t.amount);
      const cat = t.category || 'Autre';
      categoryMap.set(cat, (categoryMap.get(cat) || 0) + Math.abs(t.amount));
    }
  });

  // Get top categories
  const topCategories = Array.from(categoryMap.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([category, amount]) => ({
      category,
      amount,
      percentage: monthlyExpenses > 0 ? (amount / monthlyExpenses) * 100 : 0,
    }));

  // Get subscriptions
  const { data: subscriptions } = await supabase
    .from('subscriptions')
    .select('*')
    .eq('user_id', userId);

  const subs = subscriptions?.map((s: any) => ({
    id: s.id,
    name: s.name,
    amount: s.amount,
    billingCycle: s.billing_cycle,
    isVampire: s.is_vampire,
  })) || [];

  // Get vampires
  const vampires = subs
    .filter((s: any) => s.isVampire)
    .map((s: any) => ({
      subscriptionId: s.id,
      name: s.name,
      oldAmount: s.previous_amount || s.amount,
      newAmount: s.amount,
    }));

  // Get goals
  const { data: goals } = await supabase
    .from('budget_goals')
    .select('*')
    .eq('user_id', userId);

  const goalsList = goals?.map((g: any) => ({
    id: g.id,
    name: g.name,
    currentAmount: g.current_amount || 0,
    targetAmount: g.target_amount || 1,
    progressPercentage: g.target_amount > 0 
      ? ((g.current_amount || 0) / g.target_amount) * 100 
      : 0,
  })) || [];

  // Get unread insights
  const { data: insights } = await supabase
    .from('ai_insights')
    .select('title')
    .eq('user_id', userId)
    .eq('is_read', false)
    .limit(5);

  return {
    currentBalance,
    monthlyIncome,
    monthlyExpenses,
    topCategories,
    subscriptions: subs,
    vampires,
    goals: goalsList,
    unreadInsights: insights?.map((i: any) => i.title) || [],
  };
}

function buildSystemPrompt(context: FinancialContext): string {
  const topCats = context.topCategories
    .map(c => `${c.category}: ${c.amount.toFixed(2)}€ (${c.percentage.toFixed(0)}%)`)
    .join(', ');

  const subs = context.subscriptions
    .map(s => `${s.name}: ${s.amount.toFixed(2)}€/${s.billingCycle}`)
    .join(', ');

  const goals = context.goals
    .map(g => `${g.name}: ${g.currentAmount.toFixed(0)}/${g.targetAmount.toFixed(0)}€ (${g.progressPercentage.toFixed(0)}%)`)
    .join(', ');

  return `Tu es Aura, un coach financier personnel chaleureux, bienveillant et expert.
Tu parles français avec un ton encourageant mais direct.
Tu n'es jamais condescendant. Tu utilises des emojis avec parcimonie.

CONTEXTE FINANCIER DE L'UTILISATEUR:
- Solde actuel: ${context.currentBalance.toFixed(2)}€
- Revenus mensuels: ${context.monthlyIncome.toFixed(2)}€
- Dépenses ce mois: ${context.monthlyExpenses.toFixed(2)}€
- Top dépenses: ${topCats || 'Aucune donnée'}
- Abonnements: ${subs || 'Aucun'}
${context.vampires.length > 0 ? `- Alertes vampires: ${context.vampires.map(v => `${v.name} (+${((v.newAmount - v.oldAmount) / v.oldAmount * 100).toFixed(0)}%)`).join(', ')}` : ''}
- Objectifs: ${goals || 'Aucun'}

Tu as accès à ces données. Réponds de manière personnalisée.
Si l'utilisateur demande des données précises, fournis-les depuis le contexte.
Si une action est possible (créer un objectif, marquer un abonnement, afficher un graphique), 
inclus dans ta réponse un tag action avec JSON structuré:
<action>{"type": "create_goal" | "mark_subscription" | "show_chart", "data": {...}}</action>

Sois concis mais utile. Maximum 3-4 phrases par réponse.`;
}

async function saveMessage(
  supabase: any,
  conversationId: string,
  userId: string,
  content: string,
  actions: any[]
) {
  try {
    // Save assistant message
    await supabase.from('coach_messages').insert({
      conversation_id: conversationId,
      role: 'coach',
      content,
      actions: actions.length > 0 ? actions : null,
    });

    // Update conversation last_message_at
    await supabase
      .from('coach_conversations')
      .update({ last_message_at: new Date().toISOString() })
      .eq('id', conversationId);

  } catch (error) {
    console.error('Error saving message:', error);
  }
}

// ═══════════════════════════════════════════════════════════
// FONCTIONS DE STREAMING
// ═══════════════════════════════════════════════════════════

/**
 * Stream avec DeepSeek API (prioritaire)
 */
async function streamDeepSeek(
  apiKey: string,
  messages: Message[]
): Promise<ReadableStream> {
  const response = await fetch(DEEPSEEK_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: DEEPSEEK_MODEL,
      messages,
      temperature: 0.7,
      max_tokens: 500,
      stream: true,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`DeepSeek API error: ${error}`);
  }

  if (!response.body) {
    throw new Error('DeepSeek response has no body');
  }

  return response.body;
}

/**
 * Stream avec OpenAI API (fallback)
 */
async function streamOpenAI(
  apiKey: string,
  messages: Message[]
): Promise<ReadableStream> {
  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o',
      messages,
      temperature: 0.7,
      max_tokens: 500,
      stream: true,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`OpenAI API error: ${error}`);
  }

  if (!response.body) {
    throw new Error('OpenAI response has no body');
  }

  return response.body;
}
