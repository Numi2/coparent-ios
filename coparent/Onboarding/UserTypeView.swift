import SwiftUI

struct UserTypeView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedType: User.UserType?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("I am a...")
                .font(.title)
                .bold()
                .padding(.top, 32)
            
            Text("Select your current parenting situation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 16) {
                UserTypeButton(
                    title: "Single Parent",
                    description: "Looking for a co-parent",
                    type: .singleParent,
                    isSelected: selectedType == .singleParent
                ) {
                    selectedType = .singleParent
                }
                
                UserTypeButton(
                    title: "Co-Parent",
                    description: "Already co-parenting",
                    type: .coParent,
                    isSelected: selectedType == .coParent
                ) {
                    selectedType = .coParent
                }
                
                UserTypeButton(
                    title: "Potential Co-Parent",
                    description: "Planning to co-parent",
                    type: .potentialCoParent,
                    isSelected: selectedType == .potentialCoParent
                ) {
                    selectedType = .potentialCoParent
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                if let type = selectedType {
                    // Create temporary user
                    appState.currentUser = User(
                        id: UUID().uuidString,
                        name: "",
                        userType: type
                    )
                    withAnimation {
                        appState.onboardingStep = .basicInfo
                    }
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(selectedType != nil ? .blue : .gray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedType == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct UserTypeButton: View {
    let title: String
    let description: String
    let type: User.UserType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? .blue : .gray.opacity(0.3),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UserTypeView()
        .environment(AppState())
} 