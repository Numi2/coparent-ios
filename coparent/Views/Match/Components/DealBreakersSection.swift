import SwiftUI

struct DealBreakersSection: View {
    @Binding var filters: FilterSet

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Deal Breakers")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 12) {
                ForEach(DealBreaker.allCases, id: \.self) { dealBreaker in
                    DealBreakerToggle(
                        dealBreaker: dealBreaker,
                        isEnabled: filters.dealBreakers.contains(dealBreaker)
                    ) {
                        toggleDealBreaker(dealBreaker)
                    }
                }
            }
        }
        .glassCard()
    }

    private func toggleDealBreaker(_ dealBreaker: DealBreaker) {
        if filters.dealBreakers.contains(dealBreaker) {
            filters.dealBreakers.remove(dealBreaker)
        } else {
            filters.dealBreakers.insert(dealBreaker)
        }
    }
}

struct DealBreakerToggle: View {
    let dealBreaker: DealBreaker
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: dealBreakerIcon)
                    .foregroundColor(isEnabled ? .red : .secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(dealBreaker.title)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(dealBreaker.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isEnabled ? .red : .secondary)
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(0.5))
            .cornerRadius(12)
        }
    }

    private var dealBreakerIcon: String {
        switch dealBreaker {
        case .smoking: return "smoke.fill"
        case .drinking: return "wineglass.fill"
        case .drugs: return "pills.fill"
        case .religion: return "cross.fill"
        case .politics: return "person.2.fill"
        case .education: return "graduationcap.fill"
        case .income: return "dollarsign.circle.fill"
        case .children: return "person.3.fill"
        }
    }
}

enum DealBreaker: String, CaseIterable {
    case smoking
    case drinking
    case drugs
    case religion
    case politics
    case education
    case income
    case children

    var title: String {
        switch self {
        case .smoking: return "No Smoking"
        case .drinking: return "No Drinking"
        case .drugs: return "No Drugs"
        case .religion: return "Religious Compatibility"
        case .politics: return "Political Alignment"
        case .education: return "Education Level"
        case .income: return "Income Level"
        case .children: return "Children Preferences"
        }
    }

    var description: String {
        switch self {
        case .smoking: return "Exclude matches who smoke"
        case .drinking: return "Exclude matches who drink alcohol"
        case .drugs: return "Exclude matches who use recreational drugs"
        case .religion: return "Match with similar religious beliefs"
        case .politics: return "Match with similar political views"
        case .education: return "Match with similar education level"
        case .income: return "Match with similar income level"
        case .children: return "Match with similar children preferences"
        }
    }
}

#Preview {
    DealBreakersSection(filters: .constant(FilterSet()))
        .padding()
}
