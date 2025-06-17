import SwiftUI

struct CompatibilityIndicator: View {
    let score: Double
    
    private var scorePercentage: Int {
        Int(score)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0..<40:
            return .red
        case 40..<60:
            return .orange
        case 60..<80:
            return .yellow
        default:
            return .green
        }
    }
    
    private var compatibilityLevel: String {
        switch score {
        case 0..<40:
            return "Low"
        case 40..<60:
            return "Medium"
        case 60..<80:
            return "Good"
        default:
            return "Great"
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(
                        LinearGradient(
                            colors: [scoreColor, scoreColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: score)
                
                Text("\(scorePercentage)")
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(compatibilityLevel)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

#Preview("Compatibility Indicator") {
    VStack(spacing: 20) {
        CompatibilityIndicator(score: 85)
        CompatibilityIndicator(score: 65)
        CompatibilityIndicator(score: 45)
        CompatibilityIndicator(score: 25)
    }
    .padding()
    .background(.ultraThinMaterial)
}