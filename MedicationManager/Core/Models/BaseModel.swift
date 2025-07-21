import Foundation
import FirebaseFirestore

// MARK: - Base Protocols
protocol SyncableModel {
    var id: String { get }
    var updatedAt: Date { get set }
    var needsSync: Bool { get set }
    var isDeletedFlag: Bool { get set }
    mutating func markForSync()
    
}

protocol VoiceInputCapable {
    var voiceEntryUsed: Bool { get set }
}

protocol UserOwnedModel {
    var userId: String { get }
}

// MARK: - Common Model Extensions
extension SyncableModel {
    mutating func markForSync() {
        needsSync = true
        updatedAt = Date()
    }
    
    mutating func markSynced() {
        needsSync = false
    }
    
    mutating func markDeleted() {
        isDeletedFlag = true
        markForSync()
    }
}
