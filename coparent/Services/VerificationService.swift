import Foundation
import Vision
import UIKit
import MessageUI

@Observable
class VerificationService {
    private(set) var isProcessing = false
    private(set) var verificationResults: [VerificationType: VerificationResult] = [:]
    private(set) var error: Error?
    
    enum VerificationType: String, CaseIterable {
        case phoneNumber = "phone"
        case email = "email"
        case photoVerification = "photo"
        case governmentID = "id"
        case socialMedia = "social"
        
        var displayName: String {
            switch self {
            case .phoneNumber: return "Phone Number"
            case .email: return "Email Address"
            case .photoVerification: return "Photo Verification"
            case .governmentID: return "Government ID"
            case .socialMedia: return "Social Media"
            }
        }
        
        var systemImage: String {
            switch self {
            case .phoneNumber: return "phone.fill"
            case .email: return "envelope.fill"
            case .photoVerification: return "camera.fill"
            case .governmentID: return "doc.text.fill"
            case .socialMedia: return "globe"
            }
        }
    }
    
    enum VerificationResult: String, Codable {
        case pending = "pending"
        case verified = "verified"
        case failed = "failed"
        case notStarted = "not_started"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .verified: return "Verified"
            case .failed: return "Failed"
            case .notStarted: return "Not Started"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .verified: return .green
            case .failed: return .red
            case .notStarted: return .gray
            }
        }
    }
    
    // MARK: - Phone Verification
    
    func sendPhoneVerificationCode(to phoneNumber: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Simulate SMS sending - in real app, integrate with Firebase Auth or similar
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                verificationResults[.phoneNumber] = .pending
            }
        } catch {
            await MainActor.run {
                self.error = error
                verificationResults[.phoneNumber] = .failed
            }
            throw error
        }
    }
    
    func verifyPhoneCode(_ code: String) async throws -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Simulate code verification
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let isValid = code == "123456" // Simulate verification
            
            await MainActor.run {
                verificationResults[.phoneNumber] = isValid ? .verified : .failed
            }
            
            return isValid
        } catch {
            await MainActor.run {
                self.error = error
                verificationResults[.phoneNumber] = .failed
            }
            throw error
        }
    }
    
    // MARK: - Email Verification
    
    func sendEmailVerification(to email: String) async throws {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Simulate email sending - in real app, integrate with email service
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                verificationResults[.email] = .pending
            }
        } catch {
            await MainActor.run {
                self.error = error
                verificationResults[.email] = .failed
            }
            throw error
        }
    }
    
    func verifyEmailToken(_ token: String) async throws -> Bool {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Simulate token verification
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let isValid = !token.isEmpty && token.count >= 6
            
            await MainActor.run {
                verificationResults[.email] = isValid ? .verified : .failed
            }
            
            return isValid
        } catch {
            await MainActor.run {
                self.error = error
                verificationResults[.email] = .failed
            }
            throw error
        }
    }
    
    // MARK: - Photo Verification
    
    func verifyPhoto(_ image: UIImage) async throws -> PhotoVerificationResult {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result = try await performFaceDetection(on: image)
            
            await MainActor.run {
                verificationResults[.photoVerification] = result.isValid ? .verified : .failed
            }
            
            return result
        } catch {
            await MainActor.run {
                self.error = error
                verificationResults[.photoVerification] = .failed
            }
            throw error
        }
    }
    
    private func performFaceDetection(on image: UIImage) async throws -> PhotoVerificationResult {
        guard let cgImage = image.cgImage else {
            throw VerificationError.invalidImage
        }
        
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)
        
        try handler.perform([request])
        
        guard let results = request.results, !results.isEmpty else {
            return PhotoVerificationResult(
                isValid: false,
                confidence: 0.0,
                message: "No face detected in the image"
            )
        }
        
        let face = results[0]
        let confidence = Double(face.confidence)
        
        // Check for good quality face detection
        let isValid = confidence > 0.8
        let message = isValid ? "Face verified successfully" : "Face detection confidence too low"
        
        return PhotoVerificationResult(
            isValid: isValid,
            confidence: confidence,
            message: message
        )
    }
    
    // MARK: - Government ID Verification
    
    func verifyGovernmentID(_ frontImage: UIImage, backImage: UIImage? = nil) async throws -> IDVerificationResult {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Simulate ID verification process
            try await Task.sleep(nanoseconds: 3_000_000_000)
            
            let result = IDVerificationResult(
                isValid: true,
                extractedInfo: [:],
                message: "ID verification submitted for review"
            )
            
            await MainActor.run {
                verificationResults[.governmentID] = .pending
            }
            
            return result
        } catch {
            await MainActor.run {
                self.error = error
                verificationResults[.governmentID] = .failed
            }
            throw error
        }
    }
    
    // MARK: - Verification Status
    
    func getVerificationStatus(for type: VerificationType) -> VerificationResult {
        return verificationResults[type] ?? .notStarted
    }
    
    func getOverallVerificationScore() -> Double {
        let completedVerifications = verificationResults.values.filter { $0 == .verified }.count
        let totalVerifications = VerificationType.allCases.count
        return Double(completedVerifications) / Double(totalVerifications)
    }
    
    func resetVerification(for type: VerificationType) {
        verificationResults[type] = .notStarted
        error = nil
    }
    
    func clearAllVerifications() {
        verificationResults.removeAll()
        error = nil
    }
}

// MARK: - Supporting Types

struct PhotoVerificationResult {
    let isValid: Bool
    let confidence: Double
    let message: String
}

struct IDVerificationResult {
    let isValid: Bool
    let extractedInfo: [String: String]
    let message: String
}

enum VerificationError: LocalizedError {
    case invalidImage
    case networkError
    case invalidCode
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .networkError:
            return "Network connection error"
        case .invalidCode:
            return "Invalid verification code"
        case .verificationFailed:
            return "Verification failed"
        }
    }
}

import SwiftUI
