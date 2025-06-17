import SwiftUI
import PhotosUI

struct PhotosStepView: View {
    @Environment(ProfileBuilderViewModel.self) private var profileBuilder
    @State private var animatePhotos = false
    @State private var showingImageEditor = false
    @State private var selectedImageForEditing: UIImage?
    @State private var selectedImageIndex: Int = 0
    @State private var toast: ToastData?

    var body: some View {
        VStack(spacing: DesignSystem.Layout.spacing * 1.5) {
            // Photo Upload Section
            photoUploadSection

            // Current Photos Grid
            if !profileBuilder.profileImages.isEmpty {
                currentPhotosSection
            }

            // Photo Guidelines
            photoGuidelinesSection

            // Photo Quality Tips
            photoQualitySection
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.spring.delay(0.2)) {
                animatePhotos = true
            }
        }
        .task(id: profileBuilder.selectedPhotos) {
            await profileBuilder.loadProfileImages()
        }
        .sheet(isPresented: $showingImageEditor) {
            if let selectedImage = selectedImageForEditing {
                PhotoEditorView(
                    image: selectedImage,
                    onSave: { editedImage in
                        profileBuilder.profileImages[selectedImageIndex] = editedImage
                        showingImageEditor = false
                        toast = ToastData.success("Photo updated successfully!")
                    },
                    onCancel: {
                        showingImageEditor = false
                    }
                )
            }
        }
        .toast($toast)
    }

    // MARK: - Photo Upload Section

    private var photoUploadSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Add Your Photos")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(profileBuilder.profileImages.count)/6")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }

            // Photo Picker
            GlassCardView {
                PhotosPicker(
                    selection: $profileBuilder.selectedPhotos,
                    maxSelectionCount: 6 - profileBuilder.profileImages.count,
                    matching: .images
                ) {
                    VStack(spacing: DesignSystem.Layout.spacing) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(spacing: 8) {
                            Text("Add Photos")
                                .font(DesignSystem.Typography.headline)
                                .fontWeight(.semibold)

                            Text("Choose up to 6 photos that show your personality")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Layout.padding * 2)
                }
                .disabled(profileBuilder.profileImages.count >= 6)
            }
        }
        .opacity(animatePhotos ? 1 : 0)
        .offset(y: animatePhotos ? 0 : 20)
        .animation(DesignSystem.Animation.spring, value: animatePhotos)
    }

    // MARK: - Current Photos Section

    private var currentPhotosSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "photo.stack.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Your Photos")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)

                Spacer()

                if !profileBuilder.profileImages.isEmpty {
                    Text("Drag to reorder")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Photos Grid
            GlassCardView {
                LazyVGrid(columns: photoGridColumns, spacing: DesignSystem.Layout.spacing) {
                    ForEach(profileBuilder.profileImages.indices, id: \.self) { index in
                        PhotoCardView(
                            image: profileBuilder.profileImages[index],
                            isMainPhoto: index == profileBuilder.mainPhotoIndex,
                            photoNumber: index + 1,
                            onSetAsMain: {
                                withAnimation(DesignSystem.Animation.spring) {
                                    profileBuilder.setMainPhoto(at: index)
                                }
                                toast = ToastData.success("Main photo updated!")
                            },
                            onEdit: {
                                selectedImageForEditing = profileBuilder.profileImages[index]
                                selectedImageIndex = index
                                showingImageEditor = true
                            },
                            onDelete: {
                                withAnimation(DesignSystem.Animation.spring) {
                                    profileBuilder.removePhoto(at: index)
                                }
                                toast = ToastData.success("Photo removed")
                            }
                        )
                    }
                }
            }

            // Main Photo Info
            if !profileBuilder.profileImages.isEmpty {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Tap a photo to set it as your main profile picture")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, DesignSystem.Layout.padding)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.1))
                .background(.ultraThinMaterial)
                .cornerRadius(DesignSystem.Layout.cornerRadius)
            }
        }
        .opacity(animatePhotos ? 1 : 0)
        .offset(y: animatePhotos ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.2), value: animatePhotos)
    }

    // MARK: - Photo Guidelines Section

    private var photoGuidelinesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)

                Text("Photo Guidelines")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }

            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    ForEach(photoGuidelines, id: \.title) { guideline in
                        GuidelineRowView(
                            icon: guideline.icon,
                            title: guideline.title,
                            description: guideline.description,
                            isRecommended: guideline.isRecommended
                        )
                    }
                }
            }
        }
        .opacity(animatePhotos ? 1 : 0)
        .offset(y: animatePhotos ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.4), value: animatePhotos)
    }

    // MARK: - Photo Quality Section

    private var photoQualitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
            // Section Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)

                Text("Photo Quality Tips")
                    .font(DesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }

            GlassCardView {
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing) {
                    ForEach(qualityTips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.purple)
                                .font(.caption)

                            Text(tip)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)

                            Spacer()
                        }
                    }
                }
            }
        }
        .opacity(animatePhotos ? 1 : 0)
        .offset(y: animatePhotos ? 0 : 20)
        .animation(DesignSystem.Animation.spring.delay(0.6), value: animatePhotos)
    }

    // MARK: - Supporting Properties

    private let photoGridColumns = Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Layout.spacing), count: 2)

    private let photoGuidelines = [
        Guideline(
            icon: "person.crop.circle.fill",
            title: "Show your face clearly",
            description: "Make sure your face is visible and well-lit",
            isRecommended: true
        ),
        Guideline(
            icon: "camera.fill",
            title: "Use recent photos",
            description: "Photos should be from the last 2 years",
            isRecommended: true
        ),
        Guideline(
            icon: "eye.slash.fill",
            title: "Avoid sunglasses",
            description: "Let people see your eyes in at least one photo",
            isRecommended: true
        ),
        Guideline(
            icon: "person.2.fill",
            title: "Include variety",
            description: "Mix of close-ups and full-body photos",
            isRecommended: true
        ),
        Guideline(
            icon: "xmark.circle.fill",
            title: "No inappropriate content",
            description: "Keep photos family-friendly and appropriate",
            isRecommended: false
        )
    ]

    private let qualityTips = [
        "Use natural lighting when possible",
        "Smile genuinely - it's contagious!",
        "Show your hobbies and interests",
        "Include photos with your children (faces can be hidden)",
        "Avoid heavily filtered or edited photos",
        "Make sure photos are high resolution"
    ]
}

// MARK: - Photo Card View

struct PhotoCardView: View {
    let image: UIImage
    let isMainPhoto: Bool
    let photoNumber: Int
    let onSetAsMain: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showingActionSheet = false

    var body: some View {
        ZStack {
            // Photo
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 120)
                .clipped()
                .cornerRadius(DesignSystem.Layout.cornerRadius)

            // Main Photo Badge
            if isMainPhoto {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .background(Circle().fill(.black.opacity(0.3)))
                            .padding(8)
                    }
                    Spacer()
                }
            }

            // Photo Number
            VStack {
                HStack {
                    Text("\(photoNumber)")
                        .font(DesignSystem.Typography.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(.black.opacity(0.5)))
                    Spacer()
                }
                Spacer()
            }
            .padding(8)

            // Action Overlay
            Rectangle()
                .fill(Color.black.opacity(0.001))
                .onTapGesture {
                    showingActionSheet = true
                }
        }
        .confirmationDialog("Photo Options", isPresented: $showingActionSheet) {
            if !isMainPhoto {
                Button("Set as Main Photo") {
                    onSetAsMain()
                }
            }

            Button("Edit Photo") {
                onEdit()
            }

            Button("Delete Photo", role: .destructive) {
                onDelete()
            }

            Button("Cancel", role: .cancel) { }
        }
    }
}

// MARK: - Guideline Row View

struct GuidelineRowView: View {
    let icon: String
    let title: String
    let description: String
    let isRecommended: Bool

    var body: some View {
        HStack(spacing: DesignSystem.Layout.spacing) {
            // Icon
            Image(systemName: icon)
                .foregroundColor(isRecommended ? .green : .red)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)

                Text(description)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status
            Image(systemName: isRecommended ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isRecommended ? .green : .red)
        }
    }
}

// MARK: - Supporting Types

struct Guideline {
    let icon: String
    let title: String
    let description: String
    let isRecommended: Bool
}

#Preview {
    ScrollView {
        PhotosStepView()
            .padding()
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .environment(ProfileBuilderViewModel())
}
