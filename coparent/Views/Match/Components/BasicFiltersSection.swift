import SwiftUI

struct BasicFiltersSection: View {
    @Binding var filters: FilterSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.primary)
                Text("Basic Filters")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            // Age Range
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Age Range")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(filters.ageRange.lowerBound)) - \(Int(filters.ageRange.upperBound)) years")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                }
                
                RangeSlider(
                    range: Binding(
                        get: { filters.ageRange },
                        set: { filters.ageRange = $0 }
                    ),
                    bounds: 18...65,
                    step: 1
                )
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Distance
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Maximum Distance")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(filters.maxDistance)) km")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $filters.maxDistance,
                    in: AppConfig.Filters.minFilterDistance...AppConfig.Filters.maxFilterDistance,
                    step: 5
                ) {
                    Text("Distance")
                } minimumValueLabel: {
                    Text("\(Int(AppConfig.Filters.minFilterDistance))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("\(Int(AppConfig.Filters.maxFilterDistance))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .tint(.blue)
            }
        }
        .glassCard()
    }
}

#Preview {
    BasicFiltersSection(filters: .constant(FilterSet()))
        .padding()
} 