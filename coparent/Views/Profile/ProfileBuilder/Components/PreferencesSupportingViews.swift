import SwiftUI

// MARK: - Preference Stat View

struct PreferenceStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Range Slider View

struct RangeSliderView: View {
    @Binding var range: ClosedRange<Int>
    let bounds: ClosedRange<Int>
    let step: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(spacing: 4) {
                    Text("Min")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper(
                        value: Binding(
                            get: { range.lowerBound },
                            set: { newValue in
                                let clampedValue = max(
                                    bounds.lowerBound, 
                                    min(newValue, range.upperBound - step)
                                )
                                range = clampedValue...range.upperBound
                            }
                        ),
                        in: bounds,
                        step: step
                    ) {
                        Text("\(range.lowerBound)")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.semibold)
                            .frame(width: 40)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Max")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Stepper(
                        value: Binding(
                            get: { range.upperBound },
                            set: { newValue in
                                let clampedValue = max(
                                    range.lowerBound + step, 
                                    min(newValue, bounds.upperBound)
                                )
                                range = range.lowerBound...clampedValue
                            }
                        ),
                        in: bounds,
                        step: step
                    ) {
                        Text("\(range.upperBound)")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.semibold)
                            .frame(width: 40)
                    }
                }
            }
        }
    }
}

// MARK: - Parenting Style Preference Card

struct ParentingStylePreferenceCard: View {
    let style: User.ParentingStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: style.systemImage)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .pink)
                
                Text(style.displayName)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(isSelected ? Color.pink : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .stroke(
                                isSelected ? Color.pink : Color.gray.opacity(0.3), 
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
}

// MARK: - Deal Breaker Row

struct DealBreakerRow: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(text)
                .font(DesignSystem.Typography.callout)
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
