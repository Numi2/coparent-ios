import Foundation
#if false // TODO: Re-enable when Firebase is added
import FirebaseStorage
#endif
import UIKit

class StorageService {
    #if false // TODO: Re-enable when Firebase is added
    private let storage = Storage.storage()
    #endif
    
    func uploadImage(_ image: UIImage, path: String) async throws -> String {
        #if false // TODO: Re-enable when Firebase is added
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
        #else
        // Mock implementation for testing
        let mockURL = "https://mock-storage.example.com/\(path)"
        return mockURL
        #endif
    }
    
    func deleteImage(at path: String) async throws {
        #if false // TODO: Re-enable when Firebase is added
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
        #endif
        // Mock implementation - no-op for testing
    }
} 
