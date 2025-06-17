import SwiftUI

struct TermsView: View {
    @Environment(AppState.self) private var appState
    @State private var acceptedTerms = false
    @State private var acceptedPrivacy = false

    private var canContinue: Bool {
        acceptedTerms && acceptedPrivacy
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Terms & Privacy")
                    .font(.title)
                    .bold()
                    .padding(.top, 32)

                VStack(alignment: .leading, spacing: 20) {
                    Toggle(isOn: $acceptedTerms) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Terms of Service")
                                .font(.headline)
                            Text("I agree to the Terms of Service")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $acceptedPrivacy) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy Policy")
                                .font(.headline)
                            Text("I agree to the Privacy Policy")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(
                        "By continuing, you agree to our Terms of Service and Privacy Policy. "
                        + "We take your privacy seriously and will never share your personal "
                        + "information with third parties without your consent."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: {
                    withAnimation {
                        appState.onboardingStep = .complete
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canContinue ? .blue : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    TermsView()
        .environment(AppState())
}
