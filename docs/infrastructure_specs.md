# Infrastructure.md - Deployment & Infrastructure Architecture

## Infrastructure Overview

The Medication Management App utilizes a hybrid cloud-native and iOS-native architecture to optimize performance, security, and user experience while maintaining scalability.

## 1. Core Infrastructure Stack

### Primary Services
- **Frontend**: iOS 18 Native App (SwiftUI)
- **Authentication**: Firebase Authentication
- **Database**: Firebase Firestore (Primary) + iOS Core Data (Local Cache)
- **AI Processing**: Google Vertex AI (Medgemma 27B)
- **Payments**: Apple Pay + Stripe
- **Notifications**: Apple Push Notification Service (APNs)
- **Analytics**: Firebase Analytics + Crashlytics
- **Storage**: Firebase Storage (minimal) + iOS local storage

### Architecture Decision: Firebase vs iOS-Native

**Recommended Approach: Hybrid Architecture**

#### Primary Data Storage: Firebase Firestore
**Rationale:**
- Cross-device synchronization capability
- Real-time data sync for caregiver access
- Robust security rules for multi-user access
- Automatic scaling and backup
- Easier caregiver invitation management
- Future Android compatibility preparation

#### Local Cache: iOS Core Data
**Rationale:**
- Offline functionality
- Faster app performance
- Reduced API calls
- Privacy-first approach for sensitive data
- Apple ecosystem optimization

## 2. Firebase Infrastructure Setup

### Firebase Project Configuration
```json
{
  "projectId": "medication-manager-prod",
  "region": "us-central1",
  "services": {
    "authentication": {
      "providers": ["google", "email"],
      "settings": {
        "enableEmailVerification": true,
        "passwordPolicy": "strong"
      }
    },
    "firestore": {
      "locationId": "us-central1",
      "rules": "production",
      "backupEnabled": true
    },
    "storage": {
      "bucket": "medication-manager-prod.appspot.com",
      "rules": "authenticated-only"
    }
  }
}
```

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Nested collections inherit parent permissions
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Caregiver access rules
    match /users/{userId}/caregiverAccess/{caregiverId} {
      allow read: if request.auth != null && 
        (request.auth.uid == userId || request.auth.uid == caregiverId);
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shared caregiver data (read-only)
    match /users/{userId}/medications/{medicationId} {
      allow read: if request.auth != null && 
        (request.auth.uid == userId || 
         exists(/databases/$(database)/documents/users/$(userId)/caregiverAccess/$(request.auth.uid)));
    }
  }
}
```

## 3. Google Cloud Platform (Vertex AI)

### Vertex AI Configuration
```yaml
# vertex-ai-config.yaml
project: medication-manager-ai
region: us-central1
model: medgemma-27b
endpoints:
  - name: conflict-detection
    model: medgemma-27b
    scaling:
      minNodes: 1
      maxNodes: 10
      targetUtilization: 70
  
authentication:
  serviceAccount: medgemma-api@medication-manager-ai.iam.gserviceaccount.com
  scopes:
    - https://www.googleapis.com/auth/cloud-platform
```

### API Rate Limiting & Cost Management
```json
{
  "rateLimiting": {
    "requestsPerMinute": 60,
    "requestsPerHour": 1000,
    "requestsPerDay": 10000
  },
  "costControls": {
    "maxMonthlySpend": 5000,
    "alertThresholds": [1000, 2500, 4000],
    "autoShutoff": true
  }
}
```

## 4. Apple Services Integration

### App Store Connect Configuration
```json
{
  "appIdentifier": "com.medicationmanager.ios",
  "bundleVersion": "1.0.0",
  "capabilities": [
    "aps-environment",
    "com.apple.developer.siri",
    "com.apple.developer.healthkit",
    "com.apple.security.app-groups"
  ],
  "subscriptions": {
    "monthly": {
      "productId": "com.medicationmanager.monthly",
      "price": 9.99,
      "currency": "USD"
    },
    "annual": {
      "productId": "com.medicationmanager.annual", 
      "price": 89.99,
      "currency": "USD"
    }
  }
}
```

### Push Notification Setup
```json
{
  "apns": {
    "environment": "production",
    "authKey": "AuthKey_XXXXXXXXXX.p8",
    "keyId": "XXXXXXXXXX",
    "teamId": "XXXXXXXXXX",
    "bundleId": "com.medicationmanager.ios"
  },
  "categories": [
    "medication-reminder",
    "conflict-alert",
    "caregiver-notification"
  ]
}
```

## 5. Payment Infrastructure

### Stripe Configuration
```json
{
  "stripe": {
    "publishableKey": "pk_live_...",
    "secretKey": "sk_live_...",
    "webhookSecret": "whsec_...",
    "products": {
      "monthly": "price_monthly_9_99",
      "annual": "price_annual_89_99"
    }
  },
  "applePay": {
    "merchantId": "merchant.com.medicationmanager",
    "supportedNetworks": ["visa", "masterCard", "amex"],
    "merchantCapabilities": ["threeDSecure", "debit", "credit"]
  }
}
```

### Webhook Handling
```javascript
// Stripe webhook endpoint
POST /webhooks/stripe
{
  "events": [
    "customer.subscription.created",
    "customer.subscription.updated", 
    "customer.subscription.deleted",
    "invoice.payment_succeeded",
    "invoice.payment_failed"
  ]
}
```

## 6. Monitoring & Analytics

### Firebase Analytics Events
```javascript
// Custom Events Tracking
const analyticsEvents = {
  "medication_added": {
    "method": "voice|text",
    "category": "medication|supplement|diet"
  },
  "conflict_detected": {
    "severity": "low|medium|high|critical",
    "medications_count": "number"
  },
  "caregiver_invited": {
    "access_level": "readonly",
    "invitation_method": "qr_code"
  },
  "subscription_converted": {
    "plan": "monthly|annual",
    "trial_duration": "days"
  }
}
```

### Performance Monitoring
```yaml
# Cloud Monitoring Configuration
monitoring:
  metrics:
    - name: api_response_time
      threshold: 2000ms
      alert: email
    - name: conflict_detection_accuracy
      threshold: 95%
      alert: slack
    - name: app_crash_rate
      threshold: 0.1%
      alert: pagerduty
  
dashboards:
  - user_engagement
  - api_performance
  - revenue_tracking
  - error_rates
```

## 7. Security Infrastructure

### Network Security
```yaml
# Security Configuration
security:
  networking:
    tls: 1.3
    certificatePinning: true
    requestSigning: true
  
  dataProtection:
    encryptionAtRest: true
    encryptionInTransit: true
    keyRotation: 90days
  
  compliance:
    dataRetention: 7years
    gdprCompliant: true
    coppaCompliant: true
```

### API Security
```json
{
  "apiSecurity": {
    "authentication": "Bearer token",
    "rateLimiting": "100 requests/minute",
    "ipWhitelisting": false,
    "requestValidation": true,
    "responseFiltering": true
  }
}
```

## 8. Backup & Disaster Recovery

### Firebase Backup Strategy
```yaml
backup:
  firestore:
    frequency: daily
    retention: 30days
    location: us-central1
    encryption: true
  
  authentication:
    export: weekly
    retention: 90days
  
  storage:
    replication: multi-region
    versioning: enabled
```

### Disaster Recovery Plan
```yaml
disaster_recovery:
  rto: 4hours  # Recovery Time Objective
  rpo: 1hour   # Recovery Point Objective
  
  procedures:
    - automated_failover: true
    - backup_restoration: automated
    - health_checks: continuous
    - alert_escalation: 15minutes
```

## 9. Environment Management

### Development Environments
```yaml
environments:
  development:
    firebase_project: medication-manager-dev
    vertex_ai_project: medication-manager-ai-dev
    apple_bundle_id: com.medicationmanager.ios.dev
  
  staging:
    firebase_project: medication-manager-staging
    vertex_ai_project: medication-manager-ai-staging
    apple_bundle_id: com.medicationmanager.ios.staging
  
  production:
    firebase_project: medication-manager-prod
    vertex_ai_project: medication-manager-ai-prod
    apple_bundle_id: com.medicationmanager.ios
```

## 10. Cost Optimization

### Monthly Cost Estimates
```yaml
cost_breakdown:
  firebase:
    firestore_reads: $20  # 1M reads
    firestore_writes: $60  # 1M writes
    authentication: $15   # 10K users
    hosting: $0          # Free tier
  
  vertex_ai:
    medgemma_api_calls: $200  # 100K requests
    compute_costs: $150      # Processing time
  
  apple_services:
    developer_account: $8.25  # $99/year
    app_store_fees: 30%      # Revenue share
  
  stripe:
    transaction_fees: 2.9%   # Per transaction
  
  total_estimated: $450/month  # Excluding revenue share
```

### Optimization Strategies
- Implement intelligent caching to reduce Firestore reads
- Batch API requests to Vertex AI
- Use iOS local storage for frequently accessed data
- Optimize image assets and reduce app size
- Implement lazy loading for large datasets

## 11. Deployment Pipeline

### CI/CD Configuration
```yaml
# GitHub Actions / Xcode Cloud
deployment:
  trigger: push to main
  
  steps:
    - code_checkout
    - dependency_installation
    - unit_tests
    - ui_tests
    - security_scanning
    - build_app
    - app_store_upload
    - firebase_deployment
  
  environments:
    - development: automatic
    - staging: automatic
    - production: manual_approval
```

### Release Management
```yaml
release_process:
  versioning: semantic (major.minor.patch)
  testing_phases:
    - internal_testing: 7days
    - beta_testing: 14days
    - app_store_review: 7days
  
  rollback_strategy:
    - automatic_rollback: critical_errors
    - manual_rollback: performance_issues
    - canary_releases: 10%_users_first
```

## 12. Scalability Planning

### Growth Projections
```yaml
scalability:
  user_growth:
    year_1: 10000_users
    year_2: 50000_users
    year_3: 200000_users
  
  infrastructure_scaling:
    firestore: auto_scaling
    vertex_ai: horizontal_scaling
    cdn: global_distribution
  
  performance_targets:
    app_load_time: <2seconds
    api_response_time: <500ms
    offline_capability: full_functionality
```

## Recommendation: Go with Firebase + iOS Hybrid

**Why this approach minimizes Claude Code errors:**

1. **Clear separation of concerns**: Firebase for sync/sharing, Core Data for local performance
2. **Well-documented APIs**: Both Firebase and iOS frameworks have extensive documentation
3. **Proven architecture patterns**: Many successful apps use this hybrid approach
4. **Incremental complexity**: Start with Firebase, add Core Data caching later
5. **Error isolation**: Network issues don't break local functionality
6. **Testing simplicity**: Each layer can be tested independently

This architecture provides the best balance of functionality, performance, and maintainability while setting up the app for future growth and feature additions.