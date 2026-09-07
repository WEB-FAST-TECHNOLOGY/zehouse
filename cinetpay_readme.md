# 🔗 Guide Intégration CinetPay — ZEHOUSE Flutter
**API :** Aurore v1 | **Base URL :** `https://api.cinetpay.net/v1`  
**Compte :** Cameroun (CM) — Devise : **XAF**  
**Mode :** Sandbox (`sk_test_...`) → Production (`sk_live_...`)

---

## 📋 Credentials configurés dans `lib/env.dart`

| Variable | Valeur |
|---|---|
| `cinetpayApiKey` | `ss` |
| `cinetpayApiPassword` | `ss` |
| `cinetpaySiteId` | `682641` |
| `cinetpayCurrency` | `XAF` (forcé — compte Cameroun) |

> ⚠️ **Sécurité :** Ne commitez jamais le mot de passe dans un dépôt public. En production, utilisez des variables d'environnement serveur ou Supabase Vault.

---

## 🔐 Authentification — OAuth2 (Étape obligatoire)

L'API Aurore nécessite un **Bearer token** avant tout appel. Durée de validité : **24h**.

```
POST /v1/oauth/login
Content-Type: application/json
```
```json
{
  "api_key": "s44",
  "api_password": "444"
}
```
**Réponse ✅ :**
```json
{
  "code": 200,
  "status": "OK",
  "access_token": "eyJ0eXAiOiJKV1Qi...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user_email": "webfasttechnologysarl@gmail.com"
}
```

> ⚠️ **IP Whitelist requise !** Votre IP doit être autorisée dans le dashboard CinetPay → **API & Sécurité → Whitelist IP**.  
> IP actuelle whitelistée : `129.0.189.24` (MAXYM)  
> En production, whitelist l'IP de votre serveur (Supabase Edge Function).

---

## 💳 Initier un Paiement

```
POST /v1/payment
Content-Type: application/json
Authorization: Bearer {access_token}
```
```json
{
  "site_id": "682641",
  "merchant_transaction_id": "ZHS1234567890",
  "amount": 6000,
  "currency": "XAF",
  "designation": "Frais de publication - ZEHOUSE",
  "notify_url": "https://iigudvprhfjpulneisad.supabase.co/functions/v1/cinetpay-notify",
  "success_url": "https://zehouse2471.builtwithrocket.new",
  "failed_url": "https://zehouse2471.builtwithrocket.new",
  "channels": "ALL",
  "lang": "fr"
}
```

> ⚠️ **Noms de champs critiques Aurore v1** (différents de l'ancienne API) :
> - `merchant_transaction_id` ← (pas `transaction_id`)
> - `designation` ← (pas `description`)
> - `success_url` ← (pas `return_url`)
> - `failed_url` ← champ obligatoire

**Réponse ✅ :**
```json
{
  "code": 200,
  "status": "OK",
  "payment_url": "https://secure.cinetpay.net/checkout/...",
  "payment_token": "1f1a86f17f9...",
  "merchant_transaction_id": "ZHS1234567890",
  "details": {
    "code": 2001,
    "status": "INITIATED",
    "message": "Veuillez cliquer sur le lien pour continuer le paiement",
    "must_be_redirected": true
  }
}
```

> Le `payment_url` est à la **racine** de la réponse (pas dans `data`).

---

## 🔍 Vérifier le statut d'un paiement

```
GET /v1/payment/{merchant_transaction_id}
Authorization: Bearer {access_token}
```

**Réponse — statuts possibles :**

| Statut | Signification |
|---|---|
| `INITIATED` | En attente de paiement |
| `SUCCESS` | Paiement réussi ✅ |
| `FAILED` | Paiement échoué ❌ |
| `REFUSED` | Refusé par le réseau |
| `PENDING` | En cours de traitement |
| `INSUFFICIENT_BALANCE` | Solde insuffisant |

---

## 🏦 Cartes bancaires de test (Sandbox)

CinetPay ne publie pas de numéros de carte propriétaires fixes. Dans la popup de paiement sandbox, vous pouvez utiliser ces numéros standards :

| Type | Numéro | Expiry | CVV | Résultat |
|---|---|---|---|---|
| Visa (succès) | `4111 1111 1111 1111` | `12/26` | `123` | SUCCESS |
| Visa (succès) | `4242 4242 4242 4242` | `12/26` | `123` | SUCCESS |
| Mastercard | `5500 0000 0000 0004` | `12/26` | `123` | SUCCESS |
| Visa (refus) | `4000 0000 0000 0002` | `12/26` | `123` | REFUSED |

> ℹ️ Ces numéros sont des standards de test industrie (algorithme Luhn valide). Si la page CinetPay sandbox les accepte, vous pouvez simuler le flux complet. Sinon, utilisez les numéros de test éventuellement fournis dans votre Back-Office CinetPay.

---

## 🏗️ Architecture Flutter — Fichiers clés

```
lib/
├── env.dart                          ← Credentials (API Key, Password, Site ID)
├── services/
│   ├── cinetpay_api_service.dart     ← Service REST OAuth2 + Payment
│   ├── cinetpay_io.dart              ← Widget checkout (mobile)
│   └── cinetpay_web.dart             ← Widget checkout (web)
└── presentation/
    ├── subscription_plans_screen/    ← Abonnements CinetPay
    └── publish_listing_screen/
        └── widgets/
            └── listing_payment_gate_widget.dart  ← Frais de publication
```

### Flux d'appel dans `cinetpay_api_service.dart`

```dart
// 1. Login → token
final token = await _getToken(apiKey: apiKey, apiPassword: apiPassword);

// 2. Payment → payment_url
final url = await initiatePayment(
  apiKey: Env.cinetpayApiKey,
  apiPassword: Env.cinetpayApiPassword,
  siteId: Env.cinetpaySiteId,
  transactionId: 'ZHS${uuid}',
  amount: 6000,
  currency: 'XAF',        // Toujours XAF pour le compte Cameroun
  ...
);

// 3. Ouvrir le lien dans un navigateur in-app
launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
```

---

## 🌐 Webhook / Notify URL

La `notify_url` est appelée par CinetPay à chaque changement de statut.

**URL actuelle :** `https://iigudvprhfjpulneisad.supabase.co/functions/v1/cinetpay-notify`

> ⚠️ **Règle de sécurité CRITIQUE :** Ne JAMAIS valider une transaction sur la base du statut reçu dans le webhook. Toujours re-vérifier via `GET /v1/payment/{merchant_transaction_id}` avant de débloquer un service.

---

## ❌ Erreurs fréquentes & Solutions

| Code | Statut | Cause | Solution |
|---|---|---|---|
| `1002` | `INVALID_TOKEN` | Mauvais noms de champs login | Utiliser `api_key` + `api_password` |
| `1004` | `INVALID_PARAMS` | Champ manquant ou mal nommé | Vérifier `merchant_transaction_id`, `designation`, `success_url`, `failed_url` |
| `1005` | `INVALID_CREDENTIALS` | Mauvais mot de passe | Vérifier `api_password` |
| `2010` | `CURRENCY_NOT_ALLOWED` | Devise non supportée | Utiliser `XAF` pour le compte Cameroun |
| `2011` | `NOT_ALLOWED` | IP non whitelistée | Ajouter l'IP dans Dashboard CinetPay |
| `SOCKET_ERROR` | — | DNS non résolu | Vérifier la connexion réseau / redémarrer émulateur |

---

## 🔄 Ancienne API vs Nouvelle API (Aurore)

| Aspect | Ancienne (`api-checkout.cinetpay.com/v2`) | Nouvelle Aurore (`api.cinetpay.net/v1`) |
|---|---|---|
| Statut | 🔴 HORS LIGNE (DNS mort) | ✅ Active |
| Auth | Pas d'OAuth | OAuth2 obligatoire |
| `transaction_id` | `transaction_id` | `merchant_transaction_id` |
| `description` | `description` | `designation` |
| `return_url` | `return_url` | `success_url` + `failed_url` |
| `payment_url` | Dans `data.payment_url` | À la racine |
| Whitelist IP | Non requise | ✅ Requise |

---

## ✅ Checklist Mise en Production

- [ ] Remplacer `sk_test_...` → `sk_live_...` dans `env.dart`
- [ ] Mettre à jour le `cinetpaySiteId` production
- [ ] Whitelist l'IP du serveur de production (Supabase Edge Function)
- [ ] Déployer la Supabase Edge Function `cinetpay-notify`
- [ ] Configurer la `notify_url` dans le dashboard CinetPay
- [ ] Tester le flux complet en staging avant production
