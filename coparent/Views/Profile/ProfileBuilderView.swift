import SwiftUI
import PhotosUI

struct ProfileBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profileBuilder = ProfileBuilderViewModel()
    @State private var verificationService = VerificationService()
    @State private var currentStep: ProfileStep = .welcome
    @State private var toast: ToastData?
    
    enum ProfileStep: Int, CaseIterable {
        case welcome = 0
        case basicInfo = 1
        case photos = 2
        case aboutYou = 3
        case children = 4
        case interests = 5
        case preferences = 6
        case verification = 7
        case completion = 8
        
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .basicInfo: return "Basic Info"
            case .photos: return "Photos"
            case .aboutYou: return "About You"
            case .children: return "Children"
            case .interests: return "Interests"
            case .preferences: return "Preferences"
            case .verification: return "Verification"
            case .completion: return "Complete"
            }
        }
        
        var systemImage: String {
            switch self {
            case .welcome: return "hand.wave.fill"
            case .basicInfo: return "person.fill"
            case .photos: return "camera.fill"
            case .aboutYou: return "text.quote"
            case .children: return "figure.and.child.holdinghands"
            case .interests: return "heart.fill"
            case .preferences: return "slider.horizontal.3"
            case .verification: return "checkmark.shield.fill"
            case .completion: return "party.popper.fill"
            }
        }
        
        var description: String {
            switch self {
            case .welcome: return "Let's create your amazing profile"
            case .basicInfo: return "Tell us about yourself"
            case .photos: return "Show your best photos"
            case .aboutYou: return "Share your story"
            case .children: return "Tell us about your kids"
            case .interests: return "What do you love doing?"
            case .preferences: return "Who are you looking for?"
            case .verification: return "Verify your profile"
            case .completion: return "You're all set!"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    profileHeader
                    
                    // Content
                    TabView(selection: $currentStep) {
                        ForEach(ProfileStep.allCases, id: \.self) { step in
                            stepContent(for: step)
                                .tag(step)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(DesignSystem.Animation.spring, value: currentStep)
                    
                    // Navigation Controls
                    navigationControls
                }
            }
        }
        .toast($toast)
        .environment(profileBuilder)
        .environment(verificationService)
    }
    
    // MARK: - Header
    
    private var profileHeader: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Profile Setup")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Step indicator
                Text("\(currentStep.rawValue + 1) of \(ProfileStep.allCases.count)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            ProgressView(value: Double(currentStep.rawValue), total: Double(ProfileStep.allCases.count - 1))
                .progressViewStyle(GlassProgressViewStyle())
        }
        .padding(.horizontal, DesignSystem.Layout.padding)
        .padding(.top, DesignSystem.Layout.padding)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private func stepContent(for step: ProfileStep) -> some View {
        ScrollView {
            VStack(spacing: DesignSystem.Layout.spacing * 2) {
                stepHeader(for: step)
                
                switch step {
                case .welcome:
                    WelcomeStepView()
                case .basicInfo:
                    BasicInfoStepView()
                case .photos:
                    PhotosStepView()
                case .aboutYou:
                    AboutYouStepView()
                case .children:
                    ChildrenStepView()
                case .interests:
                    InterestsStepView()
                case .preferences:
                    PreferencesStepView()
                case .verification:
                    VerificationStepView()
                case .completion:
                    CompletionStepView()
                }
            }
            .padding(.horizontal, DesignSystem.Layout.padding)
            .padding(.bottom, 100) // Space for navigation controls
        }
    }
    
    private func stepHeader(for step: ProfileStep) -> some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Step Icon
            Image(systemName: step.systemImage)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .background(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
                .clipShape(Circle())
            
            VStack(spacing: 8) {
                Text(step.title)
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Text(step.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, DesignSystem.Layout.padding)
    }
    
    // MARK: - Navigation Controls
    
    private var navigationControls: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            Divider()
            
            HStack(spacing: DesignSystem.Layout.spacing) {
                // Back Button
                if currentStep != .welcome {
                    Button("Back") {
                        withAnimation(DesignSystem.Animation.spring) {
                            previousStep()
                        }
                    }
                    .buttonStyle(GlassSecondaryButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                
                // Next/Complete Button
                Button(nextButtonTitle) {
                    withAnimation(DesignSystem.Animation.spring) {
                        nextStep()
                    }
                }
                .buttonStyle(GlassPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(!canProceedToNextStep)
            }
            .padding(.horizontal, DesignSystem.Layout.padding)
        }
        .background(.ultraThinMaterial)
    }
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .completion:
            return "Complete Profile"
        case .verification:
            return "Finish Setup"
        default:
            return "Continue"
        }
    }
    
    private var canProceedToNextStep: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .basicInfo:
            return profileBuilder.isBasicInfoComplete
        case .photos:
            return profileBuilder.hasMainPhoto
        case .aboutYou:
            return profileBuilder.isAboutYouComplete
        case .children:
            return true // Optional step
        case .interests:
            return profileBuilder.hasSelectedInterests
        case .preferences:
            return profileBuilder.isPreferencesComplete
        case .verification:
            return true // Optional step
        case .completion:
            return true
        }
    }
    
    // MARK: - Navigation Methods
    
    private func nextStep() {
        if currentStep == .completion {
            completeProfileCreation()
        } else if let nextStep = ProfileStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }
    
    private func previousStep() {
        if let previousStep = ProfileStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previousStep
        }
    }
    
    private func completeProfileCreation() {
        Task {
            do {
                try await profileBuilder.createProfile()
                await MainActor.run {
                    toast = ToastData.success("Profile created successfully!")
                    // Navigate to main app or dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    toast = ToastData.error("Failed to create profile: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Glass Progress View Style

struct GlassProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
            .progressViewStyle(.linear)
            .scaleEffect(y: 2.0)
            .background(Color.gray.opacity(0.2))
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}

#Preview {
    ProfileBuilderView()
}
