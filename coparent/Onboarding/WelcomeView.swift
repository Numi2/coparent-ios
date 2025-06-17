import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundStyle(.blue)

            Text("Welcome to Co-Parents")
                .font(.largeTitle)
                .bold()

            Text("Find your perfect co-parenting match")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    withAnimation {
                        appState.onboardingStep = .userType
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

                Button(action: {
                    // TODO: Implement sign in
                }) {
                    Text("I already have an account")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    WelcomeView()
        .environment(AppState())
}
