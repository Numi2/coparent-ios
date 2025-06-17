import SwiftUI
import PhotosUI
import SendbirdChatSDK

// MARK: - Modern Photos Picker
struct ModernImagePicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoading = false
    let maxSelection: Int
    let onCompletion: () -> Void
    
    init(selectedImages: Binding<[UIImage]>, maxSelection: Int = 5, onCompletion: @escaping () -> Void) {
        self._selectedImages = selectedImages
        self.maxSelection = maxSelection
        self.onCompletion = onCompletion
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Layout.spacing) {
                if isLoading {
                    ProgressView("Loading images...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: maxSelection,
                        matching: .images
                    ) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)
                            
                            Text("Select Photos")
                                .font(DesignSystem.Typography.title2)
                            
                            Text("Choose up to \(maxSelection) photos")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .glassCard()
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                                    ImagePreviewThumbnail(
                                        image: image,
                                        onRemove: {
                                            selectedImages.remove(at: index)
                                            selectedItems.remove(at: index)
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCompletion()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onCompletion()
                    }
                    .disabled(selectedImages.isEmpty)
                }
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                await loadImages(from: newItems)
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        await MainActor.run {
            isLoading = true
        }
        
        var loadedImages: [UIImage] = []
        
        for item in items {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
        
        await MainActor.run {
            selectedImages = loadedImages
            isLoading = false
        }
    }
}

// MARK: - Image Preview Thumbnail
struct ImagePreviewThumbnail: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(12)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Enhanced Image Message View
struct ImageMessageView: View {
    let image: UIImage
    let isCurrentUser: Bool
    @State private var showingFullScreen = false
    @State private var toast: ToastData?
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: 200, maxHeight: 200)
            .clipped()
            .cornerRadius(16)
            .overlay(
                // Glass morphism overlay with actions
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Save button
                            Button(action: saveImage) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.black.opacity(0.3))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            // Share button
                            Button(action: shareImage) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(Color.black.opacity(0.3))
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        .opacity(0.0) // Hidden by default
                        .animation(DesignSystem.Animation.easeOut, value: showingFullScreen)
                    }
                }
                .padding(8)
            )
            .onTapGesture {
                showingFullScreen = true
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                FullScreenImageView(image: image)
            }
            .toast($toast)
    }
    
    private func saveImage() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        toast = .success("Image saved to Photos")
    }
    
    private func shareImage() {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var toast: ToastData?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Navigation bar
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: saveImage) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: shareImage) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Zoomable image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnifyGesture()
                            .onChanged { value in
                                scale = value.magnification
                            }
                            .onEnded { _ in
                                withAnimation(.spring()) {
                                    if scale < 1.0 {
                                        scale = 1.0
                                    } else if scale > 3.0 {
                                        scale = 3.0
                                    }
                                }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring()) {
                                            offset = .zero
                                        }
                                    }
                            )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if scale > 1.0 {
                                scale = 1.0
                                offset = .zero
                            } else {
                                scale = 2.0
                            }
                        }
                    }
                
                Spacer()
            }
        }
        .toast($toast)
    }
    
    private func saveImage() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        toast = .success("Image saved to Photos")
    }
    
    private func shareImage() {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Image Preview and Edit View
struct ImagePreviewView: View {
    @Binding var images: [UIImage]
    let onSend: ([UIImage]) -> Void
    let onCancel: () -> Void
    @State private var currentIndex = 0
    @State private var editingImage: UIImage?
    @State private var showingEditor = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Image carousel
                TabView(selection: $currentIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                            .onTapGesture {
                                editingImage = image
                                showingEditor = true
                            }
                    }
                }
                .tabViewStyle(PageTabViewStyle())
                .frame(maxHeight: 400)
                
                // Page indicator
                if images.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                                .animation(DesignSystem.Animation.spring, value: currentIndex)
                        }
                    }
                    .padding(.vertical)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Edit") {
                        if let image = images[safe: currentIndex] {
                            editingImage = image
                            showingEditor = true
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(images.isEmpty)
                    
                    Button("Remove") {
                        if images.count > 1 {
                            images.remove(at: currentIndex)
                            if currentIndex >= images.count {
                                currentIndex = images.count - 1
                            }
                        }
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(images.count <= 1)
                    
                    Spacer()
                    
                    Button("Send \(images.count) Photo\(images.count == 1 ? "" : "s")") {
                        onSend(images)
                    }
                    .buttonStyle(GlassButtonStyle())
                    .disabled(images.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let editingImage = editingImage {
                SimpleImageEditor(
                    image: editingImage,
                    onSave: { editedImage in
                        images[currentIndex] = editedImage
                        showingEditor = false
                    },
                    onCancel: {
                        showingEditor = false
                    }
                )
            }
        }
    }
}

// MARK: - Simple Image Editor
struct SimpleImageEditor: View {
    let image: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var brightness: Double = 0
    @State private var contrast: Double = 1.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Image preview
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .brightness(brightness)
                    .contrast(contrast)
                    .frame(maxHeight: 300)
                    .glassCard()
                
                // Editing controls
                VStack(spacing: 16) {
                    ControlSlider(
                        title: "Rotate",
                        value: $rotation,
                        range: -180...180,
                        systemImage: "rotate.right"
                    )
                    
                    ControlSlider(
                        title: "Scale",
                        value: $scale,
                        range: 0.5...2.0,
                        systemImage: "magnifyingglass"
                    )
                    
                    ControlSlider(
                        title: "Brightness",
                        value: $brightness,
                        range: -0.5...0.5,
                        systemImage: "sun.max"
                    )
                    
                    ControlSlider(
                        title: "Contrast",
                        value: $contrast,
                        range: 0.5...2.0,
                        systemImage: "circle.righthalf.filled"
                    )
                }
                .padding()
                .glassCard()
            }
            .padding()
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(processedImage)
                    }
                }
            }
        }
    }
    
    private var processedImage: UIImage {
        // For now, return the original image
        // In a full implementation, you would apply the transformations
        return image
    }
}

// MARK: - Control Slider
struct ControlSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(DesignSystem.Typography.callout)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range)
                .tint(.blue)
        }
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview("Modern Image Picker") {
    ModernImagePicker(
        selectedImages: .constant([]),
        maxSelection: 5,
        onCompletion: {}
    )
}

#Preview("Image Message View") {
    VStack {
        ImageMessageView(
            image: UIImage(systemName: "photo")!,
            isCurrentUser: true
        )
        
        ImageMessageView(
            image: UIImage(systemName: "photo")!,
            isCurrentUser: false
        )
    }
    .padding()
}

#Preview("Image Preview View") {
    ImagePreviewView(
        images: .constant([UIImage(systemName: "photo")!]),
        onSend: { _ in },
        onCancel: {}
    )
} 