import SwiftUI
import MapKit

struct AdvancedFiltersView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var filtersService = SmartFiltersService.shared
    @State private var showingLocationPicker = false
    @State private var showingSaveDialog = false
    @State private var showingPresets = false
    @State private var filterName = ""
    @State private var searchText = ""
    @State private var showingToast = false
    @State private var toastMessage = ""
    
    // Local filter state for editing
    @State private var localFilters = FilterSet()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Smart Recommendations
                        if !filtersService.smartRecommendations.isEmpty {
                            smartRecommendationsSection
                        }
                        
                        // Basic Filters
                        basicFiltersSection
                        
                        // Advanced Filters
                        advancedFiltersSection
                        
                        // Deal Breakers
                        dealBreakersSection
                        
                        // Location & Travel
                        locationSection
                        
                        // Saved Filter Sets
                        savedFiltersSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Space for action buttons
                }
                
                // Action buttons overlay
                actionButtonsOverlay
            }
            .navigationTitle("Advanced Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        withAnimation(.spring()) {
                            localFilters = FilterSet()
                        }
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applyFilters()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                localFilters = filtersService.currentFilters
                filtersService.requestLocationPermission()
            }
            .alert("Save Filter Set", isPresented: $showingSaveDialog) {
                TextField("Filter name", text: $filterName)
                Button("Save") {
                    saveCurrentFilters()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give this filter set a name to save it for later")
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(selectedLocation: .constant(filtersService.currentLocation))
            }
            .sheet(isPresented: $showingPresets) {
                FilterPresetsView()
            }
        }
        .toast(message: toastMessage, isShowing: $showingToast)
    }
    
    // MARK: - Smart Recommendations Section
    
    @ViewBuilder
    private var smartRecommendationsSection: some View {
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
            
            ForEach(filtersService.smartRecommendations) { recommendation in
                SmartRecommendationCard(
                    recommendation: recommendation,
                    onApply: { applyRecommendation(recommendation) }
                )
            }
        }
        .glassCard()
    }
    
    // MARK: - Basic Filters Section
    
    @ViewBuilder
    private var basicFiltersSection: some View {
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
                    
                    Text("\(Int(localFilters.ageRange.lowerBound)) - \(Int(localFilters.ageRange.upperBound)) years")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                }
                
                RangeSlider(
                    range: Binding(
                        get: { localFilters.ageRange },
                        set: { localFilters.ageRange = $0 }
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
                    
                    Text("\(Int(localFilters.maxDistance)) km")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $localFilters.maxDistance,
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
    
    // MARK: - Advanced Filters Section
    
    @ViewBuilder
    private var advancedFiltersSection: some View {
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
                            isSelected: localFilters.selectedParentingStyles.contains(style)
                        ) {
                            toggleParentingStyle(style)
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
                    
                    Button("Search Interests") {
                        // TODO: Implement interest search
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.blue)
                }
                
                if localFilters.selectedInterests.isEmpty {
                    Text("Select interests to find people with similar hobbies")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(Array(localFilters.selectedInterests), id: \.self) { interest in
                            InterestTag(
                                interest: interest,
                                isSelected: true
                            ) {
                                localFilters.selectedInterests.remove(interest)
                            }
                        }
                    }
                }
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Quality Filters
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile Quality")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                
                FilterToggleRow(
                    title: "Verified Profiles Only",
                    icon: "checkmark.seal",
                    isOn: $localFilters.isVerifiedOnly
                )
                
                FilterToggleRow(
                    title: "Must Have Photos",
                    icon: "photo",
                    isOn: $localFilters.hasPhotosOnly
                )
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Compatibility Score
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Minimum Compatibility")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(localFilters.minimumCompatibilityScore * 100))%")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                }
                
                Slider(
                    value: $localFilters.minimumCompatibilityScore,
                    in: 0.0...1.0,
                    step: 0.1
                ) {
                    Text("Compatibility")
                } minimumValueLabel: {
                    Text("0%")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("100%")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .tint(.green)
            }
        }
        .glassCard()
    }
    
    // MARK: - Deal Breakers Section
    
    @ViewBuilder
    private var dealBreakersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                Text("Deal Breakers")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Optional")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Automatically filter out profiles that don't meet your requirements")
                .font(DesignSystem.Typography.callout)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(DealBreaker.allCases, id: \.self) { dealBreaker in
                    FilterToggleCard(
                        title: dealBreakerTitle(dealBreaker),
                        icon: dealBreakerIcon(dealBreaker),
                        isSelected: localFilters.dealBreakers.contains(dealBreaker),
                        color: .red
                    ) {
                        toggleDealBreaker(dealBreaker)
                    }
                }
            }
        }
        .glassCard()
    }
    
    // MARK: - Location Section
    
    @ViewBuilder
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.green)
                Text("Location & Travel")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            // Current Location
            if filtersService.isLocationEnabled {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Location")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Location services enabled")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingLocationPicker = true
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.blue)
                }
            } else {
                Button(action: {
                    filtersService.requestLocationPermission()
                }) {
                    HStack {
                        Image(systemName: "location.slash")
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Location Services")
                                .font(DesignSystem.Typography.subheadline)
                                .fontWeight(.medium)
                            
                            Text("For location-based matching")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
            }
            
            // Travel Mode
            if let travelMode = localFilters.travelMode {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundColor(.orange)
                        
                        Text("Travel Mode Active")
                            .font(DesignSystem.Typography.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("Disable") {
                            localFilters.travelMode = nil
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.red)
                    }
                    
                    Text("Searching within \(Int(travelMode.radius))km of travel location")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Until \(travelMode.endDate, style: .date)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Button("Enable Travel Mode") {
                    // TODO: Show travel mode setup
                }
                .font(DesignSystem.Typography.callout)
                .foregroundColor(.blue)
            }
        }
        .glassCard()
    }
    
    // MARK: - Saved Filters Section
    
    @ViewBuilder
    private var savedFiltersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bookmark")
                    .foregroundColor(.indigo)
                Text("Saved Filter Sets")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingPresets = true
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.blue)
            }
            
            if filtersService.savedFilterSets.isEmpty {
                VStack(spacing: 8) {
                    Text("No saved filter sets")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                    
                    Text("Save your current filters to quickly apply them later")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filtersService.savedFilterSets.prefix(3)) { filterSet in
                            SavedFilterCard(filterSet: filterSet) {
                                loadFilterSet(filterSet)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .glassCard()
    }
    
    // MARK: - Action Buttons Overlay
    
    @ViewBuilder
    private var actionButtonsOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                Button("Save Filters") {
                    showingSaveDialog = true
                }
                .buttonStyle(GlassSecondaryButtonStyle())
                .disabled(filtersService.savedFilterSets.count >= AppConfig.Filters.maxSavedFilterSets)
                
                Button("Apply Filters") {
                    applyFilters()
                }
                .buttonStyle(GlassPrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Safe area bottom
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleParentingStyle(_ style: User.ParentingStyle) {
        if localFilters.selectedParentingStyles.contains(style) {
            localFilters.selectedParentingStyles.remove(style)
        } else {
            localFilters.selectedParentingStyles.insert(style)
        }
    }
    
    private func toggleDealBreaker(_ dealBreaker: DealBreaker) {
        if localFilters.dealBreakers.contains(dealBreaker) {
            localFilters.dealBreakers.remove(dealBreaker)
        } else {
            localFilters.dealBreakers.insert(dealBreaker)
        }
    }
    
    private func applyRecommendation(_ recommendation: SmartRecommendation) {
        switch recommendation.type {
        case .ageRange:
            if let range = recommendation.suggestedValue as? ClosedRange<Double> {
                localFilters.ageRange = range
            }
        case .distance:
            if let distance = recommendation.suggestedValue as? Double {
                localFilters.maxDistance = distance
            }
        case .interests:
            if let interests = recommendation.suggestedValue as? [String] {
                localFilters.selectedInterests.formUnion(Set(interests.prefix(3)))
            }
        default:
            break
        }
        
        showToast("Applied recommendation: \(recommendation.title)")
    }
    
    private func applyFilters() {
        Task { @MainActor in
            filtersService.updateFilter(localFilters)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func saveCurrentFilters() {
        Task { @MainActor in
            do {
                try filtersService.saveFilterSet(name: filterName)
                showToast("Filter set saved successfully")
                filterName = ""
            } catch {
                showToast("Failed to save filter set: \(error.localizedDescription)")
            }
        }
    }
    
    private func loadFilterSet(_ filterSet: FilterSet) {
        localFilters = filterSet
        showToast("Loaded filter set: \(filterSet.name ?? "Unnamed")")
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        showingToast = true
    }
    
    // MARK: - Icon Helpers
    
    private func parentingStyleIcon(_ style: User.ParentingStyle) -> String {
        switch style {
        case .authoritative: return "heart.fill"
        case .permissive: return "hands.and.sparkles"
        case .authoritarian: return "exclamationmark.triangle"
        case .uninvolved: return "questionmark.circle"
        }
    }
    
    private func dealBreakerIcon(_ dealBreaker: DealBreaker) -> String {
        switch dealBreaker {
        case .smoking: return "smoke"
        case .drinking: return "wineglass"
        case .pets: return "pawprint"
        case .religion: return "building.columns"
        case .politics: return "flag"
        case .moreChildren: return "plus.circle"
        case .longDistance: return "location.slash"
        case .differentParentingStyle: return "person.2.slash"
        }
    }
    
    private func dealBreakerTitle(_ dealBreaker: DealBreaker) -> String {
        switch dealBreaker {
        case .smoking: return "Smoking"
        case .drinking: return "Drinking"
        case .pets: return "Pets"
        case .religion: return "Religion"
        case .politics: return "Politics"
        case .moreChildren: return "More Children"
        case .longDistance: return "Long Distance"
        case .differentParentingStyle: return "Different Parenting"
        }
    }
}

// MARK: - Supporting Views

struct SmartRecommendationCard: View {
    let recommendation: SmartRecommendation
    let onApply: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recommendation.title)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    ConfidenceIndicator(confidence: recommendation.confidence)
                }
                
                Text(recommendation.description)
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(.secondary)
            }
            
            Button("Apply") {
                onApply()
            }
            .font(DesignSystem.Typography.caption)
            .foregroundColor(.blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.blue.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(12)
        .background(.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < Int(confidence * 5) ? .blue : .gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
}

struct FilterToggleCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, isSelected: Bool, color: Color = .blue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct FilterToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(DesignSystem.Typography.callout)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct InterestTag: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(interest)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(isSelected ? .white : .blue)
                
                if isSelected {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? .blue : .blue.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

struct SavedFilterCard: View {
    let filterSet: FilterSet
    let onLoad: () -> Void
    
    var body: some View {
        Button(action: onLoad) {
            VStack(alignment: .leading, spacing: 8) {
                Text(filterSet.name ?? "Unnamed")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Age: \(Int(filterSet.ageRange.lowerBound))-\(Int(filterSet.ageRange.upperBound))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Distance: \(Int(filterSet.maxDistance))km")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .frame(width: 120)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Preview

#Preview {
    AdvancedFiltersView()
}

// Additional supporting components that would need to be implemented:
// - LocationPickerView: Map-based location picker
// - FilterPresetsView: Detailed view of all saved filter sets
// - RangeSlider: Custom range slider component
// - Toast modifier: Toast notification system