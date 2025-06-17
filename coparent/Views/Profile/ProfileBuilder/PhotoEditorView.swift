import SwiftUI
import UIKit

struct PhotoEditorView: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var editedImage: UIImage
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var rotation: Double = 0.0
    @State private var scale: Double = 1.0
    @State private var cropRect: CGRect = .zero
    @State private var isProcessing = false
    @State private var currentTool: EditingTool = .brightness

    enum EditingTool: String, CaseIterable {
        case brightness = "Brightness"
        case contrast = "Contrast"
        case rotate = "Rotate"
        case scale = "Scale"

        var systemImage: String {
            switch self {
            case .brightness: return "sun.max.fill"
            case .contrast: return "circle.lefthalf.filled"
            case .rotate: return "rotate.right.fill"
            case .scale: return "arrow.up.left.and.arrow.down.right"
            }
        }
    }

    init(image: UIImage, onSave: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
        self.image = image
        self.onSave = onSave
        self.onCancel = onCancel
        self._editedImage = State(initialValue: image)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Image Preview
                    imagePreviewSection

                    // Editing Controls
                    editingControlsSection
                }
            }
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEditedImage()
                    }
                    .foregroundColor(.blue)
                    .disabled(isProcessing)
                }
            }
        }
    }

    // MARK: - Image Preview Section

    private var imagePreviewSection: some View {
        GeometryReader { _ in
            ZStack {
                Image(uiImage: editedImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.5))
                }
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged({ value in
                    scale = max(0.5, min(3.0, value))
                })
        )
    }

    // MARK: - Editing Controls Section

    private var editingControlsSection: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            // Tool Selector
            toolSelectorView

            // Tool Controls
            toolControlsView

            // Reset Button
            resetButton
        }
        .padding(DesignSystem.Layout.padding)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.8))
    }

    private var toolSelectorView: some View {
        HStack(spacing: DesignSystem.Layout.spacing) {
            ForEach(EditingTool.allCases, id: \.self) { tool in
                Button(action: {
                    withAnimation(DesignSystem.Animation.spring) {
                        currentTool = tool
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tool.systemImage)
                            .font(.title2)
                            .foregroundColor(currentTool == tool ? .blue : .white)

                        Text(tool.rawValue)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(currentTool == tool ? .blue : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .fill(currentTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var toolControlsView: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            switch currentTool {
            case .brightness:
                brightnessControl
            case .contrast:
                contrastControl
            case .rotate:
                rotateControl
            case .scale:
                scaleControl
            }
        }
        .animation(DesignSystem.Animation.spring, value: currentTool)
    }

    private var brightnessControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Brightness")
                    .foregroundColor(.white)
                    .font(DesignSystem.Typography.callout)
                Spacer()
                Text("\(Int(brightness * 100))")
                    .foregroundColor(.gray)
                    .font(DesignSystem.Typography.caption)
            }

            Slider(value: $brightness, in: -1.0...1.0, step: 0.01)
                .accentColor(.blue)
                .onChange(of: brightness) { _, _ in
                    applyImageFilters()
                }
        }
    }

    private var contrastControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Contrast")
                    .foregroundColor(.white)
                    .font(DesignSystem.Typography.callout)
                Spacer()
                Text("\(Int(contrast * 100))%")
                    .foregroundColor(.gray)
                    .font(DesignSystem.Typography.caption)
            }

            Slider(value: $contrast, in: 0.5...2.0, step: 0.01)
                .accentColor(.blue)
                .onChange(of: contrast) { _, _ in
                    applyImageFilters()
                }
        }
    }

    private var rotateControl: some View {
        VStack(spacing: DesignSystem.Layout.spacing) {
            HStack {
                Text("Rotation")
                    .foregroundColor(.white)
                    .font(DesignSystem.Typography.callout)
                Spacer()
                Text("\(Int(rotation))°")
                    .foregroundColor(.gray)
                    .font(DesignSystem.Typography.caption)
            }

            Slider(value: $rotation, in: -180...180, step: 1)
                .accentColor(.blue)

            HStack(spacing: DesignSystem.Layout.spacing) {
                Button("90° Left") {
                    withAnimation(DesignSystem.Animation.spring) {
                        rotation = max(-180, rotation - 90)
                    }
                }
                .buttonStyle(GlassSecondaryButtonStyle())
                .foregroundColor(.white)

                Button("90° Right") {
                    withAnimation(DesignSystem.Animation.spring) {
                        rotation = min(180, rotation + 90)
                    }
                }
                .buttonStyle(GlassSecondaryButtonStyle())
                .foregroundColor(.white)
            }
        }
    }

    private var scaleControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Scale")
                    .foregroundColor(.white)
                    .font(DesignSystem.Typography.callout)
                Spacer()
                Text("\(Int(scale * 100))%")
                    .foregroundColor(.gray)
                    .font(DesignSystem.Typography.caption)
            }

            Slider(value: $scale, in: 0.5...3.0, step: 0.01)
                .accentColor(.blue)
        }
    }

    private var resetButton: some View {
        Button("Reset All Changes") {
            withAnimation(DesignSystem.Animation.spring) {
                brightness = 0.0
                contrast = 1.0
                rotation = 0.0
                scale = 1.0
                editedImage = image
            }
        }
        .buttonStyle(GlassSecondaryButtonStyle())
        .foregroundColor(.white)
    }

    // MARK: - Image Processing

    private func applyImageFilters() {
        guard let ciImage = CIImage(image: image) else { return }

        let context = CIContext()
        var outputImage = ciImage

        // Apply brightness
        if brightness != 0 {
            let brightnessFilter = CIFilter.colorControls()
            brightnessFilter.inputImage = outputImage
            brightnessFilter.brightness = Float(brightness)
            outputImage = brightnessFilter.outputImage ?? outputImage
        }

        // Apply contrast
        if contrast != 1.0 {
            let contrastFilter = CIFilter.colorControls()
            contrastFilter.inputImage = outputImage
            contrastFilter.contrast = Float(contrast)
            outputImage = contrastFilter.outputImage ?? outputImage
        }

        // Convert back to UIImage
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            editedImage = UIImage(cgImage: cgImage)
        }
    }

    private func saveEditedImage() {
        isProcessing = true

        Task {
            let finalImage = await processedFinalImage()

            await MainActor.run {
                isProcessing = false
                onSave(finalImage)
            }
        }
    }

    private func processedFinalImage() async -> UIImage {
        // Apply all transformations to create final image
        var finalImage = editedImage

        // Apply rotation if needed
        if rotation != 0 {
            finalImage = rotateImage(finalImage, by: rotation)
        }

        // Apply scale if needed
        if scale != 1.0 {
            finalImage = scaleImage(finalImage, by: scale)
        }

        return finalImage
    }

    private func rotateImage(_ image: UIImage, by degrees: Double) -> UIImage {
        let radians = degrees * .pi / 180

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return image }

        context.translateBy(x: image.size.width / 2, y: image.size.height / 2)
        context.rotate(by: radians)
        context.translateBy(x: -image.size.width / 2, y: -image.size.height / 2)

        image.draw(at: .zero)

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    private func scaleImage(_ image: UIImage, by scale: Double) -> UIImage {
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
}

#Preview {
    PhotoEditorView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onSave: { _ in },
        onCancel: { }
    )
}
