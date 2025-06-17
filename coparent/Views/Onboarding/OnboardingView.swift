import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showLogin = false
    @State private var showSignUp = false
    
    let pages = [
        OnboardingPage(
            title: "Welcome to Co-Parent",
            description: "Find your perfect co-parenting match and build a supportive family environment.",
            imageName: "heart.circle.fill"
        ),
        OnboardingPage(
            title: "Connect with Like-Minded Parents",
            description: "Match with other parents who share your values and parenting style.",
            imageName: "person.2.circle.fill"
        ),
        OnboardingPage(
            title: "Safe and Secure",
            description: "Your privacy and security are our top priorities.",
            imageName: "lock.shield.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            DesignSystem.Glass.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Layout.spacing * 2) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: DesignSystem.Layout.spacing * 2) {
                            Image(systemName: pages[index].imageName)
                                .font(.system(size: 100))
                                .foregroundColor(DesignSystem.Colors.primary)
                                .padding()
                                .glassCard()
                            
                            Text(pages[index].title)
                                .font(DesignSystem.Typography.title)
                                .multilineTextAlignment(.center)
                            
                            Text(pages[index].description)
                                .font(DesignSystem.Typography.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Action buttons
                VStack(spacing: DesignSystem.Layout.spacing) {
                    Button(action: { showSignUp = true }) {
                        Text("Get Started")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignSystem.Layout.buttonHeight)
                            .background(DesignSystem.Colors.primary)
                            .cornerRadius(DesignSystem.Layout.cornerRadius)
                    }
                    .buttonStyle(GlassButtonStyle())
                    
                    Button(action: { showLogin = true }) {
                        Text("I already have an account")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .padding(.horizontal, DesignSystem.Layout.padding)
            }
            .padding(.vertical, DesignSystem.Layout.padding * 2)
        }
        .sheet(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

#Preview {
    OnboardingView()
}