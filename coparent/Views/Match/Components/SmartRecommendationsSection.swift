import SwiftUI

struct SmartRecommendationsSection: View {
    let recommendations: [SmartRecommendation]
    let onApply: (SmartRecommendation) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("Smart Recommendations")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("AI Powered")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            ForEach(recommendations) { recommendation in
                SmartRecommendationCard(
                    recommendation: recommendation,
                    onApply: { onApply(recommendation) }
                )
            }
        }
        .glassCard()
    }
}

struct SmartRecommendationCard: View {
    let recommendation: SmartRecommendation
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recommendation.icon)
                    .foregroundColor(.blue)
                Text(recommendation.title)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: onApply) {
                    Text("Apply")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            Text(recommendation.description)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(Color(.systemBackground).opacity(0.5))
        .cornerRadius(12)
    }
}

#Preview {
    SmartRecommendationsSection(
        recommendations: [
            SmartRecommendation(
                id: "1",
                title: "Similar Parenting Style",
                description: "Find matches with similar parenting approaches",
                icon: "person.2.fill",
                filters: FilterSet()
            )
        ],
        onApply: { _ in }
    )
    .padding()
} 
