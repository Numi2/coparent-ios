import SwiftUI
import PhotosUI

struct VerificationStepView: View {
    @Environment(VerificationService.self) private var verificationService
    @State private var animateContent = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var verificationImage: UIImage?
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var email = ""
    @State private var emailToken = ""
    @State private var showingImagePicker = false
    @State private var toast: ToastData?
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Verification Overview
            verificationOverviewSection
            
            // Phone Verification
            phoneVerificationSection
            
            // Email Verification
            emailVerificationSection
            
            // Photo Verification
            photoVerificationSection
            
            // Verification Benefits
            verificationBenefitsSection
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateContent = true
            }
        }
        .task(id: selectedPhoto) {
            await loadSelectedPhoto()
        }
        .toast($toast)
    }
    
    // MARK: - Verification Overview Section
    
    private var verificationOverviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Verify Your Profile")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Optional")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    HStack {
                        Text("Verification Score")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(verificationService.getOverallVerificationScore() * 100))%")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.bold)
                            .foregroundColor(verificationScoreColor)
                    }
                    
                    ProgressView(value: verificationService.getOverallVerificationScore(), total: 1.0)
                        .progressViewStyle(GlassProgressViewStyle())
                        .scaleEffect(y: 2.0)
                    
                    Text("Verified profiles get 3x more matches and higher trust scores")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring, value: animateContent)
    }
    
    // MARK: - Phone Verification Section
    
    private var phoneVerificationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            VerificationSectionHeader(
                title: "Phone Number",
                icon: "phone.fill",
                status: verificationService.getVerificationStatus(for: .phoneNumber)
            )
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    if verificationService.getVerificationStatus(for: .phoneNumber) == .notStarted {
                        VStack(spacing: DesignSystem.Layout.spacing) {
                            TextField("Enter your phone number", text: $phoneNumber)
                                .textFieldStyle(GlassTextFieldStyle())
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                            
                            Button("Send Verification Code") {
                                sendPhoneVerification()
                            }
                            .buttonStyle(GlassPrimaryButtonStyle())
                            .disabled(phoneNumber.isEmpty || verificationService.isProcessing)
                        }
                    } else if verificationService.getVerificationStatus(for: .phoneNumber) == .pending {
                        VStack(spacing: DesignSystem.Layout.spacing) {
                            Text("Enter the 6-digit code sent to your phone")
                                .font(DesignSystem.Typography.callout)
                                .multilineTextAlignment(.center)
                            
                            TextField("Verification code", text: $verificationCode)
                                .textFieldStyle(GlassTextFieldStyle())
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                            
                            HStack(spacing: DesignSystem.Layout.spacing) {
                                Button("Verify Code") {
                                    verifyPhoneCode()
                                }
                                .buttonStyle(GlassPrimaryButtonStyle())
                                .disabled(verificationCode.isEmpty || verificationService.isProcessing)
                                
                                Button("Resend Code") {
                                    sendPhoneVerification()
                                }
                                .buttonStyle(GlassSecondaryButtonStyle())
                                .disabled(verificationService.isProcessing)
                            }
                        }
                    } else {
                        VerificationStatusView(
                            status: verificationService.getVerificationStatus(for: .phoneNumber),
                            message: verificationStatusMessage(for: .phoneNumber)
                        )
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.2), value: animateContent)
    }
    
    // MARK: - Email Verification Section
    
    private var emailVerificationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            VerificationSectionHeader(
                title: "Email Address",
                icon: "envelope.fill",
                status: verificationService.getVerificationStatus(for: .email)
            )
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    if verificationService.getVerificationStatus(for: .email) == .notStarted {
                        VStack(spacing: DesignSystem.Layout.spacing) {
                            TextField("Enter your email address", text: $email)
                                .textFieldStyle(GlassTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                            
                            Button("Send Verification Email") {
                                sendEmailVerification()
                            }
                            .buttonStyle(GlassPrimaryButtonStyle())
                            .disabled(email.isEmpty || !isValidEmail(email) || verificationService.isProcessing)
                        }
                    } else if verificationService.getVerificationStatus(for: .email) == .pending {
                        VStack(spacing: DesignSystem.Layout.spacing) {
                            Text("Check your email for the verification link")
                                .font(DesignSystem.Typography.callout)
                                .multilineTextAlignment(.center)
                            
                            TextField("Verification token", text: $emailToken)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.oneTimeCode)
                            
                            HStack(spacing: DesignSystem.Layout.spacing) {
                                Button("Verify Email") {
                                    verifyEmailToken()
                                }
                                .buttonStyle(GlassPrimaryButtonStyle())
                                .disabled(emailToken.isEmpty || verificationService.isProcessing)
                                
                                Button("Resend Email") {
                                    sendEmailVerification()
                                }
                                .buttonStyle(GlassSecondaryButtonStyle())
                                .disabled(verificationService.isProcessing)
                            }
                        }
                    } else {
                        VerificationStatusView(
                            status: verificationService.getVerificationStatus(for: .email),
                            message: verificationStatusMessage(for: .email)
                        )
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.4), value: animateContent)
    }
    
    // MARK: - Photo Verification Section
    
    private var photoVerificationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            VerificationSectionHeader(
                title: "Photo Verification",
                icon: "camera.fill",
                status: verificationService.getVerificationStatus(for: .photoVerification)
            )
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    if verificationService.getVerificationStatus(for: .photoVerification) == .notStarted {
                        VStack(spacing: DesignSystem.Layout.spacing) {
                            if let verificationImage = verificationImage {
                                Image(uiImage: verificationImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                            }
                            
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images
                            ) {
                                Label("Select Photo for Verification", systemImage: "camera.fill")
                            }
                            .buttonStyle(GlassSecondaryButtonStyle())
                            
                            if verificationImage != nil {
                                Button("Verify Photo") {
                                    verifyPhoto()
                                }
                                .buttonStyle(GlassPrimaryButtonStyle())
                                .disabled(verificationService.isProcessing)
                            }
                            
                            Text("Take a clear photo of your face for identity verification")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        VerificationStatusView(
                            status: verificationService.getVerificationStatus(for: .photoVerification),
                            message: verificationStatusMessage(for: .photoVerification)
                        )
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.6), value: animateContent)
    }
    
    // MARK: - Verification Benefits Section
    
    private var verificationBenefitsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                
                Text("Verification Benefits")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    ForEach(verificationBenefits, id: \.title) { benefit in
                        BenefitRowView(benefit: benefit)
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.8), value: animateContent)
    }
    
    // MARK: - Computed Properties
    
    private var verificationScoreColor: Color {
        let score = verificationService.getOverallVerificationScore()
        if score >= 0.8 { return .green }
        else if score >= 0.5 { return .orange }
        else { return .red }
    }
    
    private let verificationBenefits = [
        VerificationBenefit(
            icon: "star.fill",
            title: "Higher Match Quality",
            description: "Get matched with other verified users"
        ),
        VerificationBenefit(
            icon: "shield.checkered",
            title: "Trust Badge",
            description: "Display verified badge on your profile"
        ),
        VerificationBenefit(
            icon: "eye.fill",
            title: "Priority Visibility",
            description: "Appear higher in search results"
        ),
        VerificationBenefit(
            icon: "heart.fill",
            title: "More Matches",
            description: "3x more likes from other users"
        )
    ]
    
    // MARK: - Methods
    
    private func sendPhoneVerification() {
        Task {
            do {
                try await verificationService.sendPhoneVerificationCode(to: phoneNumber)
                await MainActor.run {
                    toast = ToastData.success("Verification code sent!")
                }
            } catch {
                await MainActor.run {
                    toast = ToastData.error("Failed to send code: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func verifyPhoneCode() {
        Task {
            do {
                let success = try await verificationService.verifyPhoneCode(verificationCode)
                await MainActor.run {
                    if success {
                        toast = ToastData.success("Phone verified successfully!")
                        verificationCode = ""
                    } else {
                        toast = ToastData.error("Invalid verification code")
                    }
                }
            } catch {
                await MainActor.run {
                    toast = ToastData.error("Verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func sendEmailVerification() {
        Task {
            do {
                try await verificationService.sendEmailVerification(to: email)
                await MainActor.run {
                    toast = ToastData.success("Verification email sent!")
                }
            } catch {
                await MainActor.run {
                    toast = ToastData.error("Failed to send email: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func verifyEmailToken() {
        Task {
            do {
                let success = try await verificationService.verifyEmailToken(emailToken)
                await MainActor.run {
                    if success {
                        toast = ToastData.success("Email verified successfully!")
                        emailToken = ""
                    } else {
                        toast = ToastData.error("Invalid verification token")
                    }
                }
            } catch {
                await MainActor.run {
                    toast = ToastData.error("Verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func verifyPhoto() {
        guard let image = verificationImage else { return }
        
        Task {
            do {
                let result = try await verificationService.verifyPhoto(image)
                await MainActor.run {
                    if result.isValid {
                        toast = ToastData.success("Photo verified successfully!")
                    } else {
                        toast = ToastData.error(result.message)
                    }
                }
            } catch {
                await MainActor.run {
                    toast = ToastData.error("Photo verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadSelectedPhoto() async {
        guard let selectedPhoto = selectedPhoto else { return }
        
        do {
            if let data = try await selectedPhoto.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.verificationImage = image
                }
            }
        } catch {
            await MainActor.run {
                toast = ToastData.error("Failed to load image")
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func verificationStatusMessage(for type: VerificationService.VerificationType) -> String {
        switch verificationService.getVerificationStatus(for: type) {
        case .pending:
            return "Verification in progress..."
        case .verified:
            return "Successfully verified!"
        case .failed:
            return "Verification failed. Please try again."
        case .notStarted:
            return "Not started"
        }
    }
}

// MARK: - Supporting Views

struct VerificationSectionHeader: View {
    let title: String
    let icon: String
    let status: VerificationService.VerificationResult
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            StatusBadge(status: status)
        }
    }
}

struct StatusBadge: View {
    let status: VerificationService.VerificationResult
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption)
            Text(status.displayName)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .cornerRadius(8)
    }
}

struct VerificationStatusView: View {
    let status: VerificationService.VerificationResult
    let message: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            Image(systemName: status.systemImage)
                .font(.system(size: 40))
                .foregroundColor(status.color)
            
            Text(message)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(status.color)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DesignSystem.Layout.padding)
    }
}

struct BenefitRowView: View {
    let benefit: VerificationBenefit
    
    var body: some View {
        HStack(spacing: DesignSystem.Layout.spacing) {
            Image(systemName: benefit.icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                
                Text(benefit.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Types

struct VerificationBenefit {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Extensions

extension VerificationService.VerificationResult {
    var systemImage: String {
        switch self {
        case .pending: return "clock.fill"
        case .verified: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .notStarted: return "circle"
        }
    }
}

#Preview {
    ScrollView {
        VerificationStepView()
            .padding()
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(VerificationService())
}