import SwiftUI

struct BasicInfoView: View {
    @Environment(AppState.self) private var appState
    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !phoneNumber.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Tell us about yourself")
                    .font(.title)
                    .bold()
                    .padding(.top, 32)
                
                VStack(spacing: 20) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    DatePicker(
                        "Date of Birth",
                        selection: $dateOfBirth,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    // Update user with basic info
                    appState.currentUser?.name = name
                    appState.currentUser?.email = email
                    appState.currentUser?.phoneNumber = phoneNumber
                    
                    withAnimation {
                        appState.onboardingStep = .terms
                    }
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? .blue : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isFormValid)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

#Preview {
    BasicInfoView()
        .environment(AppState())
} 
