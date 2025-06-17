import SwiftUI

struct AdvancedFiltersSection: View {
    @Binding var filters: FilterSet
    let onToggleParentingStyle: (User.ParentingStyle) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundColor(.purple)
                Text("Advanced Filters")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            // Parenting Styles
            VStack(alignment: .leading, spacing: 12) {
                Text("Parenting Styles")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(User.ParentingStyle.allCases, id: \.self) { style in
                        FilterToggleCard(
                            title: style.rawValue.capitalized,
                            icon: parentingStyleIcon(style),
                            isSelected: filters.selectedParentingStyles.contains(style)
                        ) {
                            onToggleParentingStyle(style)
                        }
                    }
                }
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Interests
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Interests")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    NavigationLink {
                        InterestSelectionView(selectedInterests: $filters.selectedInterests)
                    } label: {
                        Text("Edit")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if filters.selectedInterests.isEmpty {
                    Text("No interests selected")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(filters.selectedInterests, id: \.self) { interest in
                            InterestTag(interest: interest)
                        }
                    }
                }
            }
        }
        .glassCard()
    }
    
    private func parentingStyleIcon(_ style: User.ParentingStyle) -> String {
        switch style {
        case .authoritative: return "person.2.fill"
        case .permissive: return "heart.fill"
        case .authoritarian: return "exclamationmark.triangle.fill"
        case .uninvolved: return "person.fill.questionmark"
        }
    }
}

struct InterestTag: View {
    let interest: String
    
    var body: some View {
        Text(interest)
            .font(DesignSystem.Typography.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.blue.opacity(0.1))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
}

#Preview {
    AdvancedFiltersSection(
        filters: .constant(FilterSet()),
        onToggleParentingStyle: { _ in }
    )
    .padding()
} 