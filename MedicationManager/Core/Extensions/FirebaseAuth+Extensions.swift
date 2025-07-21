import Foundation
import FirebaseAuth

// MARK: - Firebase Auth Extensions
/// Extensions for Firebase Auth to provide async/await APIs and handle concurrency safely
extension FirebaseAuth.User {
    
    /// Updates the user's display name using async/await
    /// - Parameter displayName: The new display name to set
    /// - Throws: An error if the update fails
    @MainActor
    func updateDisplayName(to displayName: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let changeRequest = self.createProfileChangeRequest()
            changeRequest.displayName = displayName
            changeRequest.commitChanges { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Updates the user's photo URL using async/await
    /// - Parameter photoURL: The new photo URL to set
    /// - Throws: An error if the update fails
    @MainActor
    func updatePhotoURL(to photoURL: URL?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let changeRequest = self.createProfileChangeRequest()
            changeRequest.photoURL = photoURL
            changeRequest.commitChanges { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Updates both display name and photo URL using async/await
    /// - Parameters:
    ///   - displayName: The new display name to set (optional)
    ///   - photoURL: The new photo URL to set (optional)
    /// - Throws: An error if the update fails
    @MainActor
    func updateProfile(displayName: String? = nil, photoURL: URL? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let changeRequest = self.createProfileChangeRequest()
            
            if let displayName = displayName {
                changeRequest.displayName = displayName
            }
            
            if let photoURL = photoURL {
                changeRequest.photoURL = photoURL
            }
            
            changeRequest.commitChanges { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}