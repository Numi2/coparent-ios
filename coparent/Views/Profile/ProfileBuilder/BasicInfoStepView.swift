import SwiftUI

struct BasicInfoStepView: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @State private var animateFields = false
    @State private var toast: ToastData?
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Personal Information Section
            sectionView(title: "Personal Information", icon: "person.fill") {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Name")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        TextField("Enter your full name", text: $profileBuilder.name)
                            .textFieldStyle(GlassTextFieldStyle())
                            .textContentType(.name)
                            .submitLabel(.next)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        TextField("Enter your email", text: $profileBuilder.email)
                            .textFieldStyle(GlassTextFieldStyle())
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .submitLabel(.next)
                            .overlay(alignment: .trailing) {
                                if !profileBuilder.email.isEmpty {
                                    Image(systemName: isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(isValidEmail ? .green : .red)
                                        .padding(.trailing, 12)
                                }
                            }
                    }
                    
                    // Phone Number Field (Optional)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Phone Number")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            
                            Text("(Optional)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextField("Enter your phone number", text: $profileBuilder.phoneNumber)
                            .textFieldStyle(GlassTextFieldStyle())
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .submitLabel(.next)
                    }
                    
                    // Date of Birth
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date of Birth")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        DatePicker("", selection: $profileBuilder.dateOfBirth, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DesignSystem.Layout.padding)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                    .fill(Color(.systemGray6).opacity(0.8))
                                    .background(.ultraThinMaterial)
                            )
                    }
                }
            }
            
            // User Type Section
            sectionView(title: "I am a...", icon: "figure.and.child.holdinghands") {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    ForEach(User.UserType.allCases, id: \.self) { userType in
                        UserTypeSelectionView(
                            userType: userType,
                            isSelected: profileBuilder.userType == userType
                        ) {
                            withAnimation(DesignSystem.Animation.spring) {
                                profileBuilder.userType = userType
                            }
                        }
                    }
                }
            }
            
            // Location Section
            sectionView(title: "Location", icon: "location.fill") {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    HStack(spacing: DesignSystem.Layout.spacing) {
                        // City
                        VStack(alignment: .leading, spacing: 8) {
                            Text("City")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            
                            TextField("City", text: $profileBuilder.city)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.addressCity)
                                .submitLabel(.next)
                        }
                        
                        // State
                        VStack(alignment: .leading, spacing: 8) {
                            Text("State")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            
                            TextField("State", text: $profileBuilder.state)
                                .textFieldStyle(GlassTextFieldStyle())
                                .textContentType(.addressState)
                                .submitLabel(.done)
                        }
                    }
                    
                    // Location Tips
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Your exact location is never shared. We only show your city and use location for distance calculations.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, DesignSystem.Layout.padding)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .background(.ultraThinMaterial)
                    .cornerRadius(DesignSystem.Layout.cornerRadius)
                }
            }
            
            // Completion Status
            if !profileBuilder.isBasicInfoComplete {
                incompleteFieldsView
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateFields = true
            }
        }
        .toast($toast)
    }
    
    // MARK: - Computed Properties
    
    private var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: profileBuilder.email)
    }
    
    private var incompleteFields: [String] {
        var fields: [String] = []
        
        if profileBuilder.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("Full Name")
        }
        if profileBuilder.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isValidEmail {
            fields.append("Valid Email")
        }
        if profileBuilder.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("City")
        }
        if profileBuilder.state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fields.append("State")
        }
        
        return fields
    }
    
    // MARK: - Supporting Views
    
    @ViewBuilder
    private func sectionView<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            // Section Content
            GlassCardView {
                content()
            }
        }
        .opacity(animateFields ? 1 : 0)
        .offset(y: animateFields ? 0 : 20)
        .animation(DesignSystem.Animation.spring, value: animateFields)
    }
    
    private var incompleteFieldsView: some View {
        GlassCardView {
            VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Missing Information")
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.semibold)
                }
                
                Text("Please complete the following fields to continue:")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(incompleteFields, id: \.self) { field in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.orange)
                            Text(field)
                                .font(DesignSystem.Typography.caption)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - User Type Selection View

struct UserTypeSelectionView: View {
    let userType: User.UserType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Layout.spacing) {
                // Icon
                Image(systemName: userType.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(userType.displayTitle)
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(userType.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(isSelected ? Color.white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .padding(DesignSystem.Layout.padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
}

// MARK: - User Type Extensions

extension User.UserType: CaseIterable {
    public static var allCases: [User.UserType] {
        return [.singleParent, .coParent, .potentialCoParent]
    }
    
    var displayTitle: String {
        switch self {
        case .singleParent:
            return "Single Parent"
        case .coParent:
            return "Co-Parent"
        case .potentialCoParent:
            return "Potential Co-Parent"
        }
    }
    
    var description: String {
        switch self {
        case .singleParent:
            return "I'm a single parent looking for someone special"
        case .coParent:
            return "I share parenting responsibilities with someone"
        case .potentialCoParent:
            return "I'm open to becoming a parent with the right person"
        }
    }
    
    var systemImage: String {
        switch self {
        case .singleParent:
            return "person.fill"
        case .coParent:
            return "person.2.fill"
        case .potentialCoParent:
            return "person.crop.circle.badge.plus"
        }
    }
}

#Preview {
    ScrollView {
        BasicInfoStepView()
            .padding()
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(ProfileBuilderViewModel())
}
