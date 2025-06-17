import SwiftUI

struct ChildrenStepView: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @State private var animateContent = false
    @State private var showingAddChild = false
    @State private var toast: ToastData?
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Children Overview
            childrenOverviewSection
            
            // Add Children Section
            addChildrenSection
            
            // Children List
            if !profileBuilder.children.isEmpty {
                childrenListSection
            }
            
            // Privacy Information
            privacyInformationSection
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView { name, age, gender, interests in
                profileBuilder.addChild(name: name, age: age, gender: gender, interests: interests)
                showingAddChild = false
                toast = ToastData.success("Child added successfully!")
            }
        }
        .toast($toast)
    }
    
    // MARK: - Children Overview Section
    
    private var childrenOverviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "figure.and.child.holdinghands")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Your Children")
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
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Children Added")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            
                            Text(childrenCountText)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(profileBuilder.children.count)")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pink)
                    }
                    
                    if profileBuilder.children.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "heart")
                                .font(.title2)
                                .foregroundColor(.gray)
                            
                            Text("Sharing information about your children helps other co-parents understand your family dynamic")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, DesignSystem.Layout.padding)
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring, value: animateContent)
    }
    
    // MARK: - Add Children Section
    
    private var addChildrenSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                
                Text("Add a Child")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            Button(action: {
                showingAddChild = true
            }) {
                HStack {
                    Image(systemName: "plus")
                        .foregroundColor(.blue)
                    
                    Text("Add Child Information")
                        .font(DesignSystem.Typography.callout)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(DesignSystem.Layout.padding)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.2), value: animateContent)
    }
    
    // MARK: - Children List Section
    
    private var childrenListSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.green)
                
                Text("Your Children")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: DesignSystem.Layout.spacing) {
                ForEach(profileBuilder.children.indices, id: \.self) { index in
                    ChildCard(
                        child: profileBuilder.children[index],
                        onEdit: {
                            // In a real app, you'd show edit sheet
                            toast = ToastData.info("Edit functionality coming soon!")
                        },
                        onDelete: {
                            withAnimation(DesignSystem.Animation.spring) {
                                profileBuilder.removeChild(at: index)
                            }
                            toast = ToastData.success("Child information removed")
                        }
                    )
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.4), value: animateContent)
    }
    
    // MARK: - Privacy Information Section
    
    private var privacyInformationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                
                Text("Privacy & Safety")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    ForEach(privacyPoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(point)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.6), value: animateContent)
    }
    
    // MARK: - Computed Properties
    
    private var childrenCountText: String {
        switch profileBuilder.children.count {
        case 0:
            return "No children added yet"
        case 1:
            return "1 child added"
        default:
            return "\(profileBuilder.children.count) children added"
        }
    }
    
    private let privacyPoints = [
        "Children's faces can be hidden in photos",
        "Names and personal details are never shared publicly",
        "You control what information is visible to matches",
        "All data is encrypted and securely stored",
        "You can remove children information anytime"
    ]
}

// MARK: - Child Card View

struct ChildCard: View {
    let child: ChildData
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActionSheet = false
    
    var body: some View {
        GlassCardView {
            VStack(spacing: DesignSystem.Layout.spacing) {
                HStack {
                    // Child Avatar
                    ZStack {
                        Circle()
                            .fill(child.gender.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: child.gender.systemImage)
                            .foregroundColor(child.gender.color)
                            .font(.title2)
                    }
                    
                    // Child Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.semibold)
                        
                        Text("\(child.age) years old")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Text(child.gender.displayName)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(child.gender.color)
                    }
                    
                    Spacer()
                    
                    // Actions Button
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
                
                // Interests
                if !child.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Interests")
                                .font(DesignSystem.Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                            ForEach(child.interests, id: \.self) { interest in
                                Text(interest)
                                    .font(DesignSystem.Typography.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(child.gender.color.opacity(0.2))
                                    .foregroundColor(child.gender.color)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog("Child Options", isPresented: $showingActionSheet) {
            Button("Edit Information") {
                onEdit()
            }
            
            Button("Remove Child", role: .destructive) {
                onDelete()
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Add Child View

struct AddChildView: View {
    let onSave: (String, Int, User.Child.Gender, [String]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var age = 5
    @State private var selectedGender: User.Child.Gender = .preferNotToSay
    @State private var interests: [String] = []
    @State private var newInterest = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Child's name", text: $name)
                        .textContentType(.name)
                    
                    Picker("Age", selection: $age) {
                        ForEach(0...18, id: \.self) { age in
                            Text("\(age) years old").tag(age)
                        }
                    }
                    
                    Picker("Gender", selection: $selectedGender) {
                        ForEach(User.Child.Gender.allCases, id: \.self) { gender in
                            Label(gender.displayName, systemImage: gender.systemImage)
                                .tag(gender)
                        }
                    }
                }
                
                Section("Interests (Optional)") {
                    HStack {
                        TextField("Add interest", text: $newInterest)
                        
                        Button("Add") {
                            if !newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                interests.append(newInterest.trimmingCharacters(in: .whitespacesAndNewlines))
                                newInterest = ""
                            }
                        }
                        .disabled(newInterest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    ForEach(interests, id: \.self) { interest in
                        HStack {
                            Text(interest)
                            Spacer()
                            Button("Remove") {
                                interests.removeAll { $0 == interest }
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, age, selectedGender, interests)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Gender Extensions

extension User.Child.Gender: CaseIterable {
    public static var allCases: [User.Child.Gender] {
        return [.male, .female, .other, .preferNotToSay]
    }
    
    var displayName: String {
        switch self {
        case .male: return "Boy"
        case .female: return "Girl"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
    
    var systemImage: String {
        switch self {
        case .male: return "figure.child"
        case .female: return "figure.child"
        case .other: return "figure.child"
        case .preferNotToSay: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .male: return .blue
        case .female: return .pink
        case .other: return .purple
        case .preferNotToSay: return .gray
        }
    }
}

#Preview {
    ScrollView {
        ChildrenStepView()
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