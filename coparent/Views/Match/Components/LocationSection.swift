import SwiftUI
import MapKit

struct LocationSection: View {
    @Binding var filters: FilterSet
    let currentLocation: CLLocation?
    let onLocationPickerTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.green)
                Text("Location & Travel")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            
            // Location
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Current Location")
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button(action: onLocationPickerTap) {
                        Text("Change")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if let location = currentLocation {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        
                        Text(location.coordinate.formattedAddress)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Location not available")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Travel Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Travel Preferences")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                
                ForEach(TravelPreference.allCases, id: \.self) { preference in
                    TravelPreferenceToggle(
                        preference: preference,
                        isSelected: filters.travelPreferences.contains(preference)
                    ) {
                        toggleTravelPreference(preference)
                    }
                }
            }
        }
        .glassCard()
    }
    
    private func toggleTravelPreference(_ preference: TravelPreference) {
        if filters.travelPreferences.contains(preference) {
            filters.travelPreferences.remove(preference)
        } else {
            filters.travelPreferences.insert(preference)
        }
    }
}

struct TravelPreferenceToggle: View {
    let preference: TravelPreference
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: preferenceIcon)
                    .foregroundColor(isSelected ? .green : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(preference.title)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(preference.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(0.5))
            .cornerRadius(12)
        }
    }
    
    private var preferenceIcon: String {
        switch preference {
        case .willingToTravel: return "car.fill"
        case .preferLocal: return "house.fill"
        case .openToRelocation: return "arrow.triangle.2.circlepath"
        case .noTravel: return "xmark.circle.fill"
        }
    }
}

enum TravelPreference: String, CaseIterable {
    case willingToTravel
    case preferLocal
    case openToRelocation
    case noTravel
    
    var title: String {
        switch self {
        case .willingToTravel: return "Willing to Travel"
        case .preferLocal: return "Prefer Local"
        case .openToRelocation: return "Open to Relocation"
        case .noTravel: return "No Travel"
        }
    }
    
    var description: String {
        switch self {
        case .willingToTravel: return "Open to traveling for dates"
        case .preferLocal: return "Prefer to stay close to home"
        case .openToRelocation: return "Willing to move for the right match"
        case .noTravel: return "Not interested in traveling"
        }
    }
}

extension CLLocationCoordinate2D {
    var formattedAddress: String {
        // TODO: Implement proper address formatting
        return String(format: "%.4f, %.4f", latitude, longitude)
    }
}

#Preview {
    LocationSection(
        filters: .constant(FilterSet()),
        currentLocation: CLLocation(latitude: 37.7749, longitude: -122.4194),
        onLocationPickerTap: {}
    )
    .padding()
} 
