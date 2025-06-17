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
                            SmartRecommendationsSection(
                                recommendations: filtersService.smartRecommendations,
                                onApply: applyRecommendation
                            )
                        }
                        
                        // Basic Filters
                        BasicFiltersSection(filters: $localFilters)
                        
                        // Advanced Filters
                        AdvancedFiltersSection(
                            filters: $localFilters,
                            onToggleParentingStyle: toggleParentingStyle
                        )
                        
                        // Deal Breakers
                        DealBreakersSection(filters: $localFilters)
                        
                        // Location & Travel
                        LocationSection(
                            filters: $localFilters,
                            currentLocation: filtersService.currentLocation,
                            onLocationPickerTap: { showingLocationPicker = true }
                        )
                        
                        // Saved Filter Sets
                        SavedFiltersSection(
                            filters: $localFilters,
                            savedFilters: filtersService.savedFilters,
                            onApplyFilter: applySavedFilter,
                            onDeleteFilter: deleteSavedFilter
                        )
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
    
    // MARK: - Action Buttons
    
    private var actionButtonsOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { showingPresets = true }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Presets")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                
                Button(action: { showingSaveDialog = true }) {
                    HStack {
                        Image(systemName: "bookmark")
                        Text("Save")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Actions
    
    private func applyFilters() {
        filtersService.currentFilters = localFilters
        presentationMode.wrappedValue.dismiss()
    }
    
    private func applyRecommendation(_ recommendation: SmartRecommendation) {
        withAnimation(.spring()) {
            localFilters = recommendation.filters
        }
        showToast("Applied \(recommendation.title)")
    }
    
    private func toggleParentingStyle(_ style: User.ParentingStyle) {
        if localFilters.selectedParentingStyles.contains(style) {
            localFilters.selectedParentingStyles.remove(style)
        } else {
            localFilters.selectedParentingStyles.insert(style)
        }
    }
    
    private func applySavedFilter(_ filterSet: SavedFilterSet) {
        withAnimation(.spring()) {
            localFilters = filterSet.filters
        }
        showToast("Applied \(filterSet.name)")
    }
    
    private func deleteSavedFilter(_ filterSet: SavedFilterSet) {
        filtersService.deleteSavedFilter(filterSet)
        showToast("Deleted \(filterSet.name)")
    }
    
    private func saveCurrentFilters() {
        guard !filterName.isEmpty else { return }
        
        let filterSet = SavedFilterSet(
            id: UUID().uuidString,
            name: filterName,
            filters: localFilters,
            lastUsed: Date()
        )
        
        filtersService.saveFilter(filterSet)
        showToast("Saved \(filterName)")
        filterName = ""
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        showingToast = true
    }
}

#Preview {
    AdvancedFiltersView()
}

// Additional supporting components that would need to be implemented:
// - LocationPickerView: Map-based location picker
// - FilterPresetsView: Detailed view of all saved filter sets
// - RangeSlider: Custom range slider component
// - Toast modifier: Toast notification system
