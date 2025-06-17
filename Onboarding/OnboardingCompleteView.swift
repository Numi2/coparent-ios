import SwiftUI

struct OnboardingCompleteView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.green)
            
            Text("Welcome to Co-Parents!")
                .font(.largeTitle)
                .bold()
            
            Text("Your profile has been created successfully. You're now ready to start your co-parenting journey.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                Task {
                    await appState.connectToSendbird()
                    withAnimation {
                        appState.isOnboarded = true
                    }
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    OnboardingCompleteView()
        .environment(AppState())
} 