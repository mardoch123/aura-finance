import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'
import { crypto } from 'https://deno.land/std@0.168.0/crypto/mod.ts'

/**
 * RevenueCat Webhook Handler
 * 
 * Reçoit les événements d'abonnement depuis RevenueCat et met à jour
 * le statut Pro de l'utilisateur dans Supabase.
 * 
 * Événements gérés:
 * - INITIAL_PURCHASE: Nouvel abonnement
 * - RENEWAL: Renouvellement
 * - CANCELLATION: Annulation (fin de période)
 * - EXPIRATION: Expiration effective
 * - BILLING_ISSUE: Problème de paiement
 * 
 * URL: https://<project>.supabase.co/functions/v1/revenuecat-webhook
 */

// Configuration
const REVENUECAT_WEBHOOK_SECRET = Deno.env.get('REVENUECAT_WEBHOOK_SECRET')
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

// Types RevenueCat
interface RevenueCatEvent {
  event: {
    type: RevenueCatEventType
    app_user_id: string
    aliases: string[]
    product_id: string
    price: number
    currency: string
    store: 'APP_STORE' | 'PLAY_STORE' | 'STRIPE' | 'MAC_APP_STORE'
    takehome_percentage: number
    period_type: 'TRIAL' | 'INTRO' | 'NORMAL'
    expiration_at_ms?: number
    purchased_at_ms: number
    environment: 'SANDBOX' | 'PRODUCTION'
    transaction_id: string
    original_transaction_id: string
    is_family_share?: boolean
    transferred_from?: string[]
    transferred_to?: string[]
    cancel_reason?: 'UNSUBSCRIBE' | 'BILLING_ERROR' | 'REFUND' | 'UNKNOWN'
  }
}

type RevenueCatEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'CANCELLATION'
  | 'UNCANCELLATION'
  | 'NON_RENEWING_PURCHASE'
  | 'EXPIRATION'
  | 'BILLING_ISSUE'
  | 'PRODUCT_CHANGE'
  | 'SUBSCRIPTION_PAUSED'
  | 'TRANSFER'
  | 'SUBSCRIPTION_EXTENDED'

serve(async (req) => {
  try {
    // Vérifier la méthode
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    // Vérifier la signature RevenueCat
    const signature = req.headers.get('X-RevenueCat-Signature')
    if (!signature) {
      console.error('Missing X-RevenueCat-Signature header')
      return new Response('Unauthorized', { status: 401 })
    }

    // Lire le body
    const body = await req.text()

    // Vérifier la signature HMAC (en production)
    if (REVENUECAT_WEBHOOK_SECRET) {
      const isValid = await verifySignature(body, signature, REVENUECAT_WEBHOOK_SECRET)
      if (!isValid) {
        console.error('Invalid signature')
        return new Response('Unauthorized', { status: 401 })
      }
    }

    // Parser l'événement
    const event: RevenueCatEvent = JSON.parse(body)
    console.log('RevenueCat event received:', event.event.type)

    // Initialiser Supabase client
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    })

    // Traiter l'événement
    const result = await handleRevenueCatEvent(event, supabase)

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('Webhook error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/**
 * Vérifie la signature HMAC du webhook
 */
async function verifySignature(
  body: string,
  signature: string,
  secret: string
): Promise<boolean> {
  try {
    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )

    const signatureBuffer = await crypto.subtle.sign(
      'HMAC',
      key,
      encoder.encode(body)
    )

    const computedSignature = Array.from(new Uint8Array(signatureBuffer))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')

    return computedSignature === signature
  } catch (error) {
    console.error('Signature verification error:', error)
    return false
  }
}

/**
 * Traite un événement RevenueCat
 */
async function handleRevenueCatEvent(
  event: RevenueCatEvent,
  supabase: any
): Promise<{ success: boolean; message: string }> {
  const { event: eventData } = event
  const userId = eventData.app_user_id
  const eventType = eventData.type

  console.log(`Processing ${eventType} for user ${userId}`)

  switch (eventType) {
    case 'INITIAL_PURCHASE':
      return await handleInitialPurchase(eventData, supabase)

    case 'RENEWAL':
      return await handleRenewal(eventData, supabase)

    case 'CANCELLATION':
      return await handleCancellation(eventData, supabase)

    case 'EXPIRATION':
      return await handleExpiration(eventData, supabase)

    case 'BILLING_ISSUE':
      return await handleBillingIssue(eventData, supabase)

    case 'TRANSFER':
      return await handleTransfer(eventData, supabase)

    default:
      console.log(`Event type ${eventType} not handled`)
      return { success: true, message: 'Event ignored' }
  }
}

/**
 * Gère un nouvel achat
 */
async function handleInitialPurchase(
  eventData: any,
  supabase: any
): Promise<{ success: boolean; message: string }> {
  const userId = eventData.app_user_id
  const productId = eventData.product_id
  const expirationAt = eventData.expiration_at_ms
    ? new Date(eventData.expiration_at_ms).toISOString()
    : null

  const planType = getPlanType(productId)

  // Mettre à jour le profil
  const { error } = await supabase
    .from('profiles')
    .update({
      is_pro: true,
      pro_plan: planType,
      pro_expires_at: expirationAt,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId)

  if (error) {
    console.error('Error updating profile:', error)
    throw error
  }

  // Logger l'événement
  await logAnalyticsEvent(supabase, {
    event_name: 'purchase_completed',
    user_id: userId,
    plan_id: productId,
    revenue: eventData.price,
    currency: eventData.currency,
    period_type: eventData.period_type,
    store: eventData.store,
  })

  console.log(`User ${userId} upgraded to Pro (${planType})`)
  return { success: true, message: 'Purchase processed' }
}

/**
 * Gère un renouvellement
 */
async function handleRenewal(
  eventData: any,
  supabase: any
): Promise<{ success: boolean; message: string }> {
  const userId = eventData.app_user_id
  const productId = eventData.product_id
  const expirationAt = eventData.expiration_at_ms
    ? new Date(eventData.expiration_at_ms).toISOString()
    : null

  const planType = getPlanType(productId)

  // Mettre à jour le profil
  const { error } = await supabase
    .from('profiles')
    .update({
      is_pro: true,
      pro_plan: planType,
      pro_expires_at: expirationAt,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId)

  if (error) {
    console.error('Error updating profile:', error)
    throw error
  }

  // Logger l'événement
  await logAnalyticsEvent(supabase, {
    event_name: 'subscription_renewed',
    user_id: userId,
    plan_id: productId,
    revenue: eventData.price,
    currency: eventData.currency,
  })

  console.log(`User ${userId} renewed Pro subscription`)
  return { success: true, message: 'Renewal processed' }
}

/**
 * Gère une annulation (la fin de période n'est pas encore atteinte)
 */
async function handleCancellation(
  eventData: any,
  supabase: any
): Promise<{ success: boolean; message: string }> {
  const userId = eventData.app_user_id
  const cancelReason = eventData.cancel_reason || 'UNKNOWN'

  // Logger l'annulation (l'utilisateur garde l'accès jusqu'à expiration)
  await logAnalyticsEvent(supabase, {
    event_name: 'subscription_cancelled',
    user_id: userId,
    plan_id: eventData.product_id,
    cancel_reason: cancelReason,
    will_expire_at: eventData.expiration_at_ms
      ? new Date(eventData.expiration_at_ms).toISOString()
      : null,
  })

  console.log(`User ${userId} cancelled subscription (reason: ${cancelReason})`)
  return { success: true, message: 'Cancellation logged' }
}

/**
 * Gère une expiration effective
 */
async function handleExpiration(
  eventData: any,
  supabase: any
): Promise<{ success: boolean; message: string }> {
  const userId = eventData.app_user_id

  // Révoquer l'accès Pro
  const { error } = await supabase
    .from('profiles')
    .update({
      is_pro: false,
      pro_expires_at: null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', userId)

  if (error) {
    console.error('Error updating profile:', error)
    throw error
  }

  // Logger l'événement
  await logAnalyticsEvent(supabase, {
    event_name: 'subscription_expired',
    user_id: userId,
    plan_id: eventData.product_id,
  })

  console.log(`User ${userId} Pro subscription expired`)
  return { success: true, message: 'Expiration processed' }
}

/**
 * Gère un problème de facturation
 */
async function handleBillingIssue(
  eventData: any,
  supabase: any
): Promise<{ success: boolean; message: string }> {
  const userId = eventData.app_user_id

  // Logger le problème
  await logAnalyticsEvent(supabase, {
    event_name: 'billing_issue',
    user_id: userId,
    plan_id: eventData.product_id,
    grace_period_expires_at: eventData.expiration_at_ms
      ? new Date(eventData.expiration_at_ms).toISOString()
      : null,
  })

  console.log(`Billing issue for user ${userId}`)
  return { success: true, message: 'Billing issue logged' }
}

/**
 * Gère un transfert d'abonnement
 */
async function handleTransfer(
  eventData: any,
  supabase: any
): Promise<{ success: boolean; message: string }> {
  const fromUserIds = eventData.transferred_from || []
  const toUserIds = eventData.transferred_to || []

  // Révoquer l'accès pour les anciens utilisateurs
  for (const fromUserId of fromUserIds) {
    await supabase
      .from('profiles')
      .update({
        is_pro: false,
        pro_expires_at: null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', fromUserId)
  }

  // Accorder l'accès pour le nouvel utilisateur
  for (const toUserId of toUserIds) {
    await supabase
      .from('profiles')
      .update({
        is_pro: true,
        pro_plan: getPlanType(eventData.product_id),
        pro_expires_at: eventData.expiration_at_ms
          ? new Date(eventData.expiration_at_ms).toISOString()
          : null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', toUserId)
  }

  console.log(`Subscription transferred from ${fromUserIds} to ${toUserIds}`)
  return { success: true, message: 'Transfer processed' }
}

/**
 * Détermine le type de plan à partir du product_id
 */
function getPlanType(productId: string): string {
  if (productId.includes('annual') || productId.includes('year')) {
    return 'annual'
  }
  if (productId.includes('weekly') || productId.includes('week')) {
    return 'weekly'
  }
  if (productId.includes('monthly') || productId.includes('month')) {
    return 'monthly'
  }
  return 'unknown'
}

/**
 * Log un événement analytics
 */
async function logAnalyticsEvent(
  supabase: any,
  eventData: any
): Promise<void> {
  try {
    await supabase.from('analytics_events').insert({
      ...eventData,
      timestamp: new Date().toISOString(),
      platform: 'revenuecat_webhook',
    })
  } catch (error) {
    console.error('Error logging analytics:', error)
    // Ne pas bloquer le webhook si l'analytics échoue
  }
}
