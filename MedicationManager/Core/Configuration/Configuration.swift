import Foundation

enum AppEnvironment {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

struct Configuration {
    // MARK: - Firebase
    struct Firebase {
        static var projectId: String {
            switch AppEnvironment.current {
            case .development:
                return "medication-manager-dev"
            case .staging:
                return "medication-manager-staging"
            case .production:
                return "medication-manager-prod"
            }
        }
    }
    
    // MARK: - Vertex AI
    struct VertexAI {
        static var endpoint: String {
            return "https://us-central1-aiplatform.googleapis.com"
        }
        
        static var modelName: String {
            return "medgemma-27b"
        }
        
        static var projectId: String {
            switch AppEnvironment.current {
            case .development:
                return "medication-manager-ai-dev"
            case .staging:
                return "medication-manager-ai-staging"
            case .production:
                return "medication-manager-ai-prod"
            }
        }
    }
    
    // MARK: - Subscription
    struct Subscription {
        static let monthlyProductId = "com.medicationmanager.monthly"
        static let annualProductId = "com.medicationmanager.annual"
        static let trialDurationDays = 7
    }
    
    // MARK: - App Settings
    struct App {
        static let maxCaregivers = 3
        static let maxFamilyMembers = 2
        static let notificationsPerDay = 3
        static let conflictCacheExpiryHours = 24
        static let trialDurationDays = 7
        static let urlScheme: String = "mangohealth"
    }

}
