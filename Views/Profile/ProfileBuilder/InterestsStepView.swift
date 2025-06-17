import SwiftUI

struct InterestsStepView: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @State private var animateContent = false
    @State private var searchText = ""
    @State private var showingSuggestions = false
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Selection Progress
            selectionProgressSection
            
            // Search Section
            searchSection
            
            // Suggested Interests
            if !suggestedInterests.isEmpty {
                suggestedInterestsSection
            }
            
            // All Interests Grid
            allInterestsSection
            
            // Selection Requirements
            selectionRequirementsSection
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Selection Progress Section
    
    private var selectionProgressSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Your Interests")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(profileBuilder.selectedInterests.count)/\(User.Interest.allCases.count)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    HStack {
                        Text("Selected: \(profileBuilder.selectedInterests.count)")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("Minimum: 3")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(profileBuilder.selectedInterests.count >= 3 ? .green : .orange)
                    }
                    
                    // Progress Bar
                    ProgressView(value: Double(profileBuilder.selectedInterests.count), total: Double(min(6, User.Interest.allCases.count)))
                        .progressViewStyle(GlassProgressViewStyle())
                        .scaleEffect(y: 2.0)
                    
                    if profileBuilder.selectedInterests.count < 3 {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("Select at least 3 interests to help us find better matches")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring, value: animateContent)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                Text("Find Interests")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                TextField("Search interests...", text: $searchText)
                    .textFieldStyle(GlassTextFieldStyle())
                    .autocapitalization(.none)
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.2), value: animateContent)
    }
    
    // MARK: - Suggested Interests Section
    
    private var suggestedInterestsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                
                Text("Suggested for You")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    // This would trigger new suggestions in a real app
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.purple)
            }
            
            GlassCardView {
                LazyVGrid(columns: interestColumns, spacing: DesignSystem.Layout.spacing) {
                    ForEach(suggestedInterests, id: \.self) { interest in
                        InterestChip(
                            interest: interest,
                            isSelected: profileBuilder.selectedInterests.contains(interest),
                            style: .suggested
                        ) {
                            toggleInterest(interest)
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.4), value: animateContent)
    }
    
    // MARK: - All Interests Section
    
    private var allInterestsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "grid.circle.fill")
                    .foregroundColor(.blue)
                
                Text("All Interests")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                LazyVGrid(columns: interestColumns, spacing: DesignSystem.Layout.spacing) {
                    ForEach(filteredInterests, id: \.self) { interest in
                        InterestChip(
                            interest: interest,
                            isSelected: profileBuilder.selectedInterests.contains(interest),
                            style: .normal
                        ) {
                            toggleInterest(interest)
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.6), value: animateContent)
    }
    
    // MARK: - Selection Requirements Section
    
    private var selectionRequirementsSection: some View {
        if profileBuilder.selectedInterests.count >= 3 {
            GlassCardView {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Great selection!")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.semibold)
                        
                        Text("You've selected enough interests to find great matches")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(DesignSystem.Animation.spring.delay(0.8), value: animateContent)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredInterests: [User.Interest] {
        if searchText.isEmpty {
            return User.Interest.allCases
        } else {
            return User.Interest.allCases.filter { interest in
                interest.displayName.localizedCaseInsensitiveContains(searchText) ||
                interest.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private var suggestedInterests: [User.Interest] {
        profileBuilder.getInterestSuggestions()
    }
    
    private let interestColumns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Layout.spacing), count: 2)
    
    // MARK: - Methods
    
    private func toggleInterest(_ interest: User.Interest) {
        withAnimation(DesignSystem.Animation.spring) {
            profileBuilder.toggleInterest(interest)
        }
    }
}

// MARK: - Interest Chip

struct InterestChip: View {
    let interest: User.Interest
    let isSelected: Bool
    let style: ChipStyle
    let action: () -> Void
    
    enum ChipStyle {
        case normal
        case suggested
        
        var backgroundColor: Color {
            switch self {
            case .normal: return .clear
            case .suggested: return .purple.opacity(0.1)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .normal: return .gray.opacity(0.3)
            case .suggested: return .purple.opacity(0.5)
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Interest Icon
                Image(systemName: interest.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : iconColor)
                
                // Interest Name
                Text(interest.displayName)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : style.backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.blue : style.borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
    
    private var iconColor: Color {
        switch style {
        case .normal: return .blue
        case .suggested: return .purple
        }
    }
}

// MARK: - Interest Extensions

extension User.Interest {
    var displayName: String {
        switch self {
        case .outdoorActivities: return "Outdoor Activities"
        case .artsAndCrafts: return "Arts & Crafts"
        case .sports: return "Sports"
        case .music: return "Music"
        case .reading: return "Reading"
        case .cooking: return "Cooking"
        case .travel: return "Travel"
        case .technology: return "Technology"
        case .nature: return "Nature"
        case .communityService: return "Community Service"
        case .education: return "Education"
        case .healthAndFitness: return "Health & Fitness"
        }
    }
    
    var systemImage: String {
        switch self {
        case .outdoorActivities: return "figure.hiking"
        case .artsAndCrafts: return "paintbrush.fill"
        case .sports: return "sportscourt.fill"
        case .music: return "music.note"
        case .reading: return "book.fill"
        case .cooking: return "fork.knife"
        case .travel: return "airplane"
        case .technology: return "laptopcomputer"
        case .nature: return "leaf.fill"
        case .communityService: return "heart.fill"
        case .education: return "graduationcap.fill"
        case .healthAndFitness: return "figure.run"
        }
    }
    
    var keywords: [String] {
        switch self {
        case .outdoorActivities: return ["hiking", "camping", "adventure", "outdoors", "nature"]
        case .artsAndCrafts: return ["art", "creative", "painting", "drawing", "crafts"]
        case .sports: return ["exercise", "fitness", "games", "athletic", "competition"]
        case .music: return ["songs", "instruments", "concerts", "dancing", "singing"]
        case .reading: return ["books", "literature", "stories", "learning", "knowledge"]
        case .cooking: return ["food", "recipes", "baking", "culinary", "kitchen"]
        case .travel: return ["vacation", "adventure", "explore", "destinations", "culture"]
        case .technology: return ["computers", "gadgets", "innovation", "digital", "tech"]
        case .nature: return ["environment", "wildlife", "outdoors", "conservation", "green"]
        case .communityService: return ["volunteering", "helping", "charity", "giving", "service"]
        case .education: return ["learning", "teaching", "school", "knowledge", "development"]
        case .healthAndFitness: return ["wellness", "exercise", "healthy", "gym", "nutrition"]
        }
    }
}

#Preview {
    ScrollView {
        InterestsStepView()
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