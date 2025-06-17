import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProfileViewModel

    @State private var ageRange: ClosedRange<Int>
    @State private var distance: Double
    @State private var selectedParentingStyles: Set<User.ParentingStyle>
    @State private var dealBreakers = ""

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _ageRange = State(initialValue: viewModel.user.preferences.ageRange)
        _distance = State(initialValue: Double(viewModel.user.preferences.distance))
        _selectedParentingStyles = State(initialValue: Set(viewModel.user.preferences.parentingStyles))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Age Range") {
                    VStack {
                        HStack {
                            Text("\(ageRange.lowerBound)")
                            Spacer()
                            Text("\(ageRange.upperBound)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        RangeSlider(value: $ageRange, in: 18...65)
                    }
                }

                Section("Distance") {
                    VStack {
                        HStack {
                            Text("0 km")
                            Spacer()
                            Text("\(Int(distance)) km")
                            Spacer()
                            Text("100 km")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Slider(value: $distance, in: 0...100, step: 5)
                    }
                }

                Section("Parenting Styles") {
                    ForEach(User.ParentingStyle.allCases, id: \.self) { style in
                        Toggle(style.rawValue.capitalized, isOn: Binding(
                            get: { selectedParentingStyles.contains(style) },
                            set: { isSelected in
                                if isSelected {
                                    selectedParentingStyles.insert(style)
                                } else {
                                    selectedParentingStyles.remove(style)
                                }
                            }
                        ))
                    }
                }

                Section("Deal Breakers") {
                    TextField("Enter deal breakers (comma-separated)", text: $dealBreakers, axis: .vertical)
                        .lineLimit(3...)
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreferences()
                    }
                }
            }
        }
    }

    private func savePreferences() {
        let dealBreakersList = dealBreakers
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        viewModel.updatePreferences(
            ageRange: ageRange,
            distance: Int(distance),
            parentingStyles: Array(selectedParentingStyles),
            dealBreakers: dealBreakersList
        )

        dismiss()
    }
}

struct RangeSlider: View {
    @Binding var value: ClosedRange<Int>
    let bounds: ClosedRange<Int>

    init(value: Binding<ClosedRange<Int>>, in bounds: ClosedRange<Int>) {
        self._value = value
        self.bounds = bounds
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: width(for: value, in: geometry), height: 4)
                    .offset(x: xOffset(for: value.lowerBound, in: geometry))

                HStack(spacing: 0) {
                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(x: xOffset(for: value.lowerBound, in: geometry))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = value(for: gesture.location.x, in: geometry)
                                    value = min(newValue, value.upperBound - 1)...value.upperBound
                                }
                        )

                    Circle()
                        .fill(.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(x: xOffset(for: value.upperBound, in: geometry))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = value(for: gesture.location.x, in: geometry)
                                    value = value.lowerBound...max(newValue, value.lowerBound + 1)
                                }
                        )
                }
            }
        }
        .frame(height: 24)
    }

    private func xOffset(for value: Int, in geometry: GeometryProxy) -> CGFloat {
        let range = bounds.upperBound - bounds.lowerBound
        let percentage = CGFloat(value - bounds.lowerBound) / CGFloat(range)
        return percentage * (geometry.size.width - 24)
    }

    private func width(for range: ClosedRange<Int>, in geometry: GeometryProxy) -> CGFloat {
        let range = bounds.upperBound - bounds.lowerBound
        let percentage = CGFloat(range.upperBound - range.lowerBound) / CGFloat(range)
        return percentage * geometry.size.width
    }

    private func value(for x: CGFloat, in geometry: GeometryProxy) -> Int {
        let range = bounds.upperBound - bounds.lowerBound
        let percentage = x / (geometry.size.width - 24)
        let value = percentage * CGFloat(range) + CGFloat(bounds.lowerBound)
        return Int(round(value))
    }
}

#Preview {
    PreferencesView(viewModel: ProfileViewModel(user: User(
        id: "1",
        name: "John Doe",
        userType: .singleParent,
        email: "john@example.com",
        phoneNumber: "+1234567890",
        dateOfBirth: Date(),
        profileImageURL: nil,
        bio: "Single father of two amazing kids. Love outdoor activities and cooking.",
        location: User.Location(city: "San Francisco", state: "CA", country: "USA"),
        parentingStyle: .authoritative,
        children: [],
        preferences: User.Preferences(
            ageRange: 30...45,
            distance: 50,
            parentingStyles: [.authoritative, .gentle],
            dealBreakers: []
        ),
        interests: [.outdoorActivities, .cooking, .sports],
        verificationStatus: .verified
    )))
}
