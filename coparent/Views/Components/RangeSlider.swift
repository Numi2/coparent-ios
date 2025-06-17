import SwiftUI

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double

    @State private var dragOffset: CGSize = .zero
    @State private var isDraggingLower = false
    @State private var isDraggingUpper = false

    private let trackHeight: CGFloat = 6
    private let thumbSize: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width - thumbSize
            let lowerPosition = thumbPosition(for: range.lowerBound, trackWidth: trackWidth)
            let upperPosition = thumbPosition(for: range.upperBound, trackWidth: trackWidth)

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: trackHeight)
                    .padding(.horizontal, thumbSize / 2)

                // Active track (between thumbs)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: trackHeight)
                    .offset(x: lowerPosition + thumbSize / 2)
                    .frame(width: max(0, upperPosition - lowerPosition))

                // Lower thumb
                thumbView
                    .offset(x: lowerPosition)
                    .scaleEffect(isDraggingLower ? 1.2 : 1.0)
                    .animation(DesignSystem.Animation.spring, value: isDraggingLower)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDraggingLower && !isDraggingUpper {
                                    isDraggingLower = true
                                }
                                if isDraggingLower {
                                    updateLowerBound(with: value, trackWidth: trackWidth)
                                }
                            }
                            .onEnded { _ in
                                isDraggingLower = false
                            }
                    )

                // Upper thumb
                thumbView
                    .offset(x: upperPosition)
                    .scaleEffect(isDraggingUpper ? 1.2 : 1.0)
                    .animation(DesignSystem.Animation.spring, value: isDraggingUpper)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDraggingLower && !isDraggingUpper {
                                    isDraggingUpper = true
                                }
                                if isDraggingUpper {
                                    updateUpperBound(with: value, trackWidth: trackWidth)
                                }
                            }
                            .onEnded { _ in
                                isDraggingUpper = false
                            }
                    )
            }
        }
        .frame(height: thumbSize)
    }

    @ViewBuilder
    private var thumbView: some View {
        Circle()
            .fill(Color.white)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .overlay(
                Circle()
                    .stroke(Color.blue, lineWidth: 2)
            )
    }

    private func thumbPosition(for value: Double, trackWidth: CGFloat) -> CGFloat {
        let normalizedValue = (value - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
        return CGFloat(normalizedValue) * trackWidth
    }

    private func valueFromPosition(_ position: CGFloat, trackWidth: CGFloat) -> Double {
        let normalizedPosition = min(max(position / trackWidth, 0), 1)
        let value = bounds.lowerBound + Double(normalizedPosition) * (bounds.upperBound - bounds.lowerBound)
        return round(value / step) * step
    }

    private func updateLowerBound(with dragValue: DragGesture.Value, trackWidth: CGFloat) {
        let currentPosition = thumbPosition(for: range.lowerBound, trackWidth: trackWidth)
        let newPosition = currentPosition + dragValue.translation.x
        let newValue = valueFromPosition(newPosition, trackWidth: trackWidth)

        let clampedValue = min(newValue, range.upperBound - step)
        let finalValue = max(bounds.lowerBound, clampedValue)

        range = finalValue...range.upperBound
    }

    private func updateUpperBound(with dragValue: DragGesture.Value, trackWidth: CGFloat) {
        let currentPosition = thumbPosition(for: range.upperBound, trackWidth: trackWidth)
        let newPosition = currentPosition + dragValue.translation.x
        let newValue = valueFromPosition(newPosition, trackWidth: trackWidth)

        let clampedValue = max(newValue, range.lowerBound + step)
        let finalValue = min(bounds.upperBound, clampedValue)

        range = range.lowerBound...finalValue
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age Range: 25 - 45")
                .font(DesignSystem.Typography.headline)

            RangeSlider(
                range: .constant(25...45),
                bounds: 18...65,
                step: 1
            )
        }
        .padding()
        .glassCard()

        VStack(alignment: .leading, spacing: 8) {
            Text("Price Range: $50 - $200")
                .font(DesignSystem.Typography.headline)

            RangeSlider(
                range: .constant(50...200),
                bounds: 0...500,
                step: 5
            )
        }
        .padding()
        .glassCard()
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
