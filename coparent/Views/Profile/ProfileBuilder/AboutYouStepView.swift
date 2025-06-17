import SwiftUI

struct AboutYouStepView: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @State private var animateContent = false
    @State private var bioCharacterCount = 0
    @State private var showingSuggestions = false
    @FocusState private var isBioFocused: Bool

    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Bio Section
            bioSection

            // Parenting Style Section
            parentingStyleSection

            // Professional Information Section (Optional)
            professionalSection

            // Bio Tips Section
            bioTipsSection
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateContent = true
            }
            updateCharacterCount()
        }
        .onChange(of: profileBuilder.bio) { _, _ in
            updateCharacterCount()
        }
    }

    // MARK: - Bio Section

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "text.quote")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Tell Your Story")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Suggestions") {
                    showingSuggestions.toggle()
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.blue)
            }

            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("About You")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)

                            Spacer()

                            Text("\(bioCharacterCount)/500")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(bioCharacterCountColor)
                        }

                        TextField(
                            "Share what makes you unique, your interests, what you're looking for...",
                            text: $profileBuilder.bio,
                            axis: .vertical
                        )
                        .lineLimit(8...15)
                        .textFieldStyle(GlassTextFieldStyle())
                        .focused($isBioFocused)
                    }

                    // Character count progress
                    ProgressView(value: Double(bioCharacterCount), total: 500.0)
                        .progressViewStyle(GlassProgressViewStyle())
                        .scaleEffect(y: 0.5)

                    if bioCharacterCount < 50 {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("Write at least 50 characters to help others get to know you better")
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
        .sheet(isPresented: $showingSuggestions) {
            BioSuggestionsView(
                onSelectSuggestion: { suggestion in
                    profileBuilder.bio += (profileBuilder.bio.isEmpty ? "" : " ") + suggestion
                    showingSuggestions = false
                }
            )
        }
    }

    // MARK: - Parenting Style Section

    private var parentingStyleSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pink, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Parenting Style")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }

            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    Text("How would you describe your approach to parenting?")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    LazyVGrid(columns: parentingStyleColumns, spacing: DesignSystem.Layout.spacing) {
                        ForEach(User.ParentingStyle.allCases, id: \.self) { style in
                            ParentingStyleCard(
                                style: style,
                                isSelected: profileBuilder.parentingStyle == style
                            ) {
                                withAnimation(DesignSystem.Animation.spring) {
                                    profileBuilder.parentingStyle = style
                                }
                            }
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.2), value: animateContent)
    }

    // MARK: - Professional Section

    private var professionalSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Professional Info")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)

                Text("(Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }

            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profession")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)

                        TextField("What do you do for work?", text: $profileBuilder.profession)
                            .textFieldStyle(GlassTextFieldStyle())
                            .textContentType(.jobTitle)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Education")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)

                        TextField("Your educational background", text: $profileBuilder.education)
                            .textFieldStyle(GlassTextFieldStyle())
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.4), value: animateContent)
    }

    // MARK: - Bio Tips Section

    private var bioTipsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)

                Text("Writing Tips")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }

            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    ForEach(bioTips, id: \.title) { tip in
                        BioTipView(tip: tip)
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.6), value: animateContent)
    }

    // MARK: - Computed Properties

    private var bioCharacterCountColor: Color {
        if bioCharacterCount < 50 {
            return .orange
        } else if bioCharacterCount > 450 {
            return .red
        } else {
            return .green
        }
    }

    private let parentingStyleColumns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Layout.spacing), count: 2)

    private let bioTips = [
        BioTip(
            icon: "heart.fill",
            title: "Be authentic",
            description: "Share what genuinely matters to you and your family"
        ),
        BioTip(
            icon: "target",
            title: "Be specific",
            description: "Mention specific hobbies, values, or interests"
        ),
        BioTip(
            icon: "person.2.fill",
            title: "Include family",
            description: "Share what you love about being a parent"
        ),
        BioTip(
            icon: "eye.fill",
            title: "Future-focused",
            description: "Mention what you're looking for in a partner"
        )
    ]

    // MARK: - Helper Methods

    private func updateCharacterCount() {
        bioCharacterCount = profileBuilder.bio.count
    }
}

// MARK: - Parenting Style Card

struct ParentingStyleCard: View {
    let style: User.ParentingStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: style.systemImage)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(style.displayName)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Layout.padding)
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
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
}

// MARK: - Bio Tip View

struct BioTipView: View {
    let tip: BioTip

    var body: some View {
        HStack(spacing: DesignSystem.Layout.spacing) {
            Image(systemName: tip.icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)

                Text(tip.description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Bio Suggestions View

struct BioSuggestionsView: View {
    let onSelectSuggestion: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private let suggestions = [
        "I love spending quality time with my kids",
        "Family adventures are my favorite weekends",
        "Looking for someone who values family as much as I do",
        "Balancing work and family life with grace",
        "Passionate about creating a loving home environment",
        "Seeking a partner to share life's journey with",
        "My children are my world and my greatest joy",
        "Believer in open communication and mutual respect",
        "Love exploring new places with my little ones",
        "Always up for a good laugh and meaningful conversations"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: DesignSystem.Layout.spacing) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            onSelectSuggestion(suggestion)
                        }) {
                            HStack {
                                Text(suggestion)
                                    .font(DesignSystem.Typography.callout)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .padding(DesignSystem.Layout.padding)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(DesignSystem.Layout.padding)
            }
            .navigationTitle("Bio Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Supporting Types

struct BioTip {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Parenting Style Extensions

extension User.ParentingStyle {
    var displayName: String {
        switch self {
        case .authoritative: return "Authoritative"
        case .permissive: return "Permissive"
        case .authoritarian: return "Authoritarian"
        case .uninvolved: return "Uninvolved"
        case .attachment: return "Attachment"
        case .gentle: return "Gentle"
        case .freeRange: return "Free Range"
        case .traditional: return "Traditional"
        case .modern: return "Modern"
        case .eclectic: return "Eclectic"
        }
    }

    var systemImage: String {
        switch self {
        case .authoritative: return "scale.3d"
        case .permissive: return "heart.circle"
        case .authoritarian: return "shield"
        case .uninvolved: return "circle.dashed"
        case .attachment: return "figure.and.child.holdinghands"
        case .gentle: return "leaf"
        case .freeRange: return "bird"
        case .traditional: return "house"
        case .modern: return "iphone"
        case .eclectic: return "paintbrush"
        }
    }
}

#Preview {
    ScrollView {
        AboutYouStepView()
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
