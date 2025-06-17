import SwiftUI

struct PreferencesStepView: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @State private var animateContent = false
    @State private var newDealBreaker = ""
    @State private var toast: ToastData?
    @FocusState private var isDealBreakerFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Preferences Overview
            preferencesOverviewSection
            
            // Age Range Section
            ageRangeSection
            
            // Distance Section
            distanceSection
            
            // Parenting Styles Section
            parentingStylesSection
            
            // Deal Breakers Section
            dealBreakersSection
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animateContent = true
            }
        }
        .toast($toast)
    }
    
    // MARK: - Preferences Overview Section
    
    private var preferencesOverviewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Your Preferences")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Matching Preferences")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            
                            Text("Help us find your ideal matches")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "heart.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    
                    // Quick Stats
                    HStack {
                        PreferenceStatView(
                            title: "Age Range",
                            value: "\(profileBuilder.ageRange.lowerBound)-\(profileBuilder.ageRange.upperBound)",
                            icon: "person.2.fill",
                            color: .blue
                        )
                        
                        Divider()
                            .frame(height: 30)
                        
                        PreferenceStatView(
                            title: "Distance",
                            value: "\(profileBuilder.maxDistance) km",
                            icon: "location.fill",
                            color: .green
                        )
                        
                        Divider()
                            .frame(height: 30)
                        
                        PreferenceStatView(
                            title: "Styles",
                            value: "\(profileBuilder.preferredParentingStyles.count)",
                            icon: "heart.fill",
                            color: .pink
                        )
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring, value: animateContent)
    }
    
    // MARK: - Age Range Section
    
    private var ageRangeSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.blue)
                
                Text("Age Range")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    HStack {
                        Text("Looking for ages")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(profileBuilder.ageRange.lowerBound) - \(profileBuilder.ageRange.upperBound) years")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    // Custom Range Slider
                    RangeSliderView(
                        range: $profileBuilder.ageRange,
                        bounds: 18...65,
                        step: 1
                    )
                    
                    HStack {
                        Text("18")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("65")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.2), value: animateContent)
    }
    
    // MARK: - Distance Section
    
    private var distanceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                
                Text("Maximum Distance")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    HStack {
                        Text("Show me people within")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(profileBuilder.maxDistance) km")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(profileBuilder.maxDistance) },
                            set: { profileBuilder.maxDistance = Int($0) }
                        ),
                        in: 5...200,
                        step: 5
                    )
                    .accentColor(.green)
                    
                    HStack {
                        Text("5 km")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("200 km")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Distance quick selectors
                    HStack(spacing: 8) {
                        ForEach([25, 50, 100], id: \.self) { distance in
                            Button("\(distance) km") {
                                withAnimation(DesignSystem.Animation.spring) {
                                    profileBuilder.maxDistance = distance
                                }
                            }
                            .font(DesignSystem.Typography.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(profileBuilder.maxDistance == distance ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                            .foregroundColor(profileBuilder.maxDistance == distance ? .green : .secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.4), value: animateContent)
    }
    
    // MARK: - Parenting Styles Section
    
    private var parentingStylesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                
                Text("Preferred Parenting Styles")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    HStack {
                        Text("Select compatible styles")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(profileBuilder.preferredParentingStyles.count) selected")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(profileBuilder.preferredParentingStyles.isEmpty ? .orange : .green)
                    }
                    
                    if profileBuilder.preferredParentingStyles.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("Select at least one parenting style to continue")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    LazyVGrid(columns: parentingStyleColumns, spacing: DesignSystem.Layout.spacing) {
                        ForEach(User.ParentingStyle.allCases, id: \.self) { style in
                            ParentingStylePreferenceCard(
                                style: style,
                                isSelected: profileBuilder.preferredParentingStyles.contains(style)
                            ) {
                                toggleParentingStyle(style)
                            }
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.6), value: animateContent)
    }
    
    // MARK: - Deal Breakers Section
    
    private var dealBreakersSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                Text("Deal Breakers")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Text("(Optional)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            GlassCardView {
                VStack(spacing: DesignSystem.Layout.spacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add Deal Breakers")
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                        
                        Text("Things that are absolutely not compatible with you")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        TextField("Enter a deal breaker", text: $newDealBreaker)
                            .textFieldStyle(GlassTextFieldStyle())
                            .focused($isDealBreakerFocused)
                            .onSubmit {
                                addDealBreaker()
                            }
                        
                        Button("Add") {
                            addDealBreaker()
                        }
                        .buttonStyle(GlassPrimaryButtonStyle())
                        .disabled(newDealBreaker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    // Deal Breakers List
                    if !profileBuilder.dealBreakers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Deal Breakers")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            
                            ForEach(profileBuilder.dealBreakers.indices, id: \.self) { index in
                                DealBreakerRow(
                                    text: profileBuilder.dealBreakers[index],
                                    onRemove: {
                                        withAnimation(DesignSystem.Animation.spring) {
                                            profileBuilder.removeDealBreaker(at: index)
                                        }
                                        toast = ToastData.success("Deal breaker removed")
                                    }
                                )
                            }
                        }
                    }
                    
                    // Common Deal Breakers
                    if profileBuilder.dealBreakers.isEmpty {
                        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                            Text("Common Deal Breakers")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(commonDealBreakers, id: \.self) { dealBreaker in
                                    Button(dealBreaker) {
                                        profileBuilder.addDealBreaker(dealBreaker)
                                        toast = ToastData.success("Deal breaker added")
                                    }
                                    .font(DesignSystem.Typography.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .offset(y: animateContent ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.8), value: animateContent)
    }
    
    // MARK: - Computed Properties
    
    private let parentingStyleColumns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Layout.spacing), count: 2)
    
    private let commonDealBreakers = [
        "Smoking",
        "Heavy drinking",
        "No co-parenting",
        "Different religion",
        "Long distance",
        "No commitment",
        "Different values",
        "Incompatible schedules"
    ]
    
    // MARK: - Methods
    
    private func toggleParentingStyle(_ style: User.ParentingStyle) {
        withAnimation(DesignSystem.Animation.spring) {
            profileBuilder.toggleParentingStyle(style)
        }
    }
    
    private func addDealBreaker() {
        let trimmed = newDealBreaker.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            profileBuilder.addDealBreaker(trimmed)
            newDealBreaker = ""
            isDealBreakerFocused = false
            toast = ToastData.success("Deal breaker added")
        }
    }
}

// MARK: - Supporting Views

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
                                let clampedValue = max(bounds.lowerBound, min(newValue, range.upperBound - step))
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
                                let clampedValue = max(range.lowerBound + step, min(newValue, bounds.upperBound))
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
                            .stroke(isSelected ? Color.pink : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
}

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

#Preview {
    ScrollView {
        PreferencesStepView()
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