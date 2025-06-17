import SwiftUI

struct SavedFiltersSection: View {
    @Binding var filters: FilterSet
    let savedFilters: [SavedFilterSet]
    let onApplyFilter: (SavedFilterSet) -> Void
    let onDeleteFilter: (SavedFilterSet) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.orange)
                Text("Saved Filters")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Manage")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if savedFilters.isEmpty {
                Text("No saved filters yet")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(savedFilters) { filterSet in
                            SavedFilterCard(
                                filterSet: filterSet,
                                onApply: { onApplyFilter(filterSet) },
                                onDelete: { onDeleteFilter(filterSet) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .glassCard()
    }
}

struct SavedFilterCard: View {
    let filterSet: SavedFilterSet
    let onApply: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(filterSet.name)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Menu {
                    Button(action: onApply) {
                        Label("Apply", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(filterSet.filterCount) filters")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
            
            Text(filterSet.lastUsed.formatted(date: .abbreviated, time: .omitted))
                .font(DesignSystem.Typography.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 160)
        .background(Color(.systemBackground).opacity(0.5))
        .cornerRadius(12)
        .alert("Delete Filter Set", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this filter set? This action cannot be undone.")
        }
    }
}

struct SavedFilterSet: Identifiable {
    let id: String
    let name: String
    let filters: FilterSet
    let lastUsed: Date
    
    var filterCount: Int {
        var count = 0
        if !filters.selectedParentingStyles.isEmpty { count += 1 }
        if !filters.selectedInterests.isEmpty { count += 1 }
        if !filters.dealBreakers.isEmpty { count += 1 }
        if !filters.travelPreferences.isEmpty { count += 1 }
        return count
    }
}

#Preview {
    SavedFiltersSection(
        filters: .constant(FilterSet()),
        savedFilters: [
            SavedFilterSet(
                id: "1",
                name: "Local Parents",
                filters: FilterSet(),
                lastUsed: Date()
            ),
            SavedFilterSet(
                id: "2",
                name: "Travel Ready",
                filters: FilterSet(),
                lastUsed: Date()
            )
        ],
        onApplyFilter: { _ in },
        onDeleteFilter: { _ in }
    )
    .padding()
} 