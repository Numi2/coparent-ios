import SwiftUI

enum DesignSystem {
    // MARK: - Colors
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let background = Color(.systemBackground)
        static let glassBackground = Color.black.opacity(0.1)
        
        static let success = Color.green
        static let error = Color.red
        static let warning = Color.orange
    }
    
    // MARK: - Glass Effects
    enum Glass {
        static let background = AnyView(
            Color.black.opacity(0.1)
                .background(.ultraThinMaterial)
        )
        
        static let card = AnyView(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        
        static let button = AnyView(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Typography
    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title, design: .rounded).weight(.semibold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.medium)
        static let headline = Font.system(.headline, design: .rounded).weight(.medium)
        static let body = Font.system(.body, design: .rounded)
        static let callout = Font.system(.callout, design: .rounded)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let footnote = Font.system(.footnote, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
    }
    
    // MARK: - Layout
    enum Layout {
        static let spacing: CGFloat = 16
        static let cornerRadius: CGFloat = 20
        static let buttonHeight: CGFloat = 44
        static let iconSize: CGFloat = 24
        static let padding: CGFloat = 16
    }
    
    // MARK: - Animations
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.2)
        static let easeIn = SwiftUI.Animation.easeIn(duration: 0.2)
    }
}

// MARK: - View Modifiers
struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Glass.background)
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Glass.card)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
    }
}

struct GlassButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DesignSystem.Glass.button)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
    }
}

// MARK: - View Extensions
extension View {
    func glassBackground() -> some View {
        modifier(GlassBackground())
    }
    
    func glassCard() -> some View {
        modifier(GlassCard())
    }
    
    func glassButton() -> some View {
        modifier(GlassButton())
    }
}

// MARK: - Reusable Components
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, DesignSystem.Layout.padding)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(configuration.isPressed ? 
                          Color.white.opacity(0.2) : 
                          Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

struct GlassPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.callout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Layout.padding)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .fill(Color.white.opacity(configuration.isPressed ? 0.2 : 0.1))
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

struct GlassSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.callout.weight(.medium))
            .foregroundColor(.primary)
            .padding(.horizontal, DesignSystem.Layout.padding)
            .frame(height: DesignSystem.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                            .fill(Color.white.opacity(configuration.isPressed ? 0.2 : 0.1))
                            .background(.ultraThinMaterial)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, DesignSystem.Layout.padding)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color(.systemGray6).opacity(0.8))
                    .background(.ultraThinMaterial)
            )
            .font(DesignSystem.Typography.body)
    }
}

struct GlassIconButton: View {
    let systemName: String
    let action: () -> Void
    let color: Color
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: DesignSystem.Layout.iconSize, weight: .medium))
                .foregroundColor(color)
                .frame(width: DesignSystem.Layout.buttonHeight, 
                       height: DesignSystem.Layout.buttonHeight)
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

struct GlassCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Layout.padding)
            .glassCard()
    }
}

struct ToastView: View {
    let message: String
    let systemImage: String
    let color: Color
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(color)
            
            Text(message)
                .font(DesignSystem.Typography.callout)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(DesignSystem.Layout.padding)
        .background(.ultraThinMaterial)
        .cornerRadius(DesignSystem.Layout.cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isShowing ? 1.0 : 0.8)
        .opacity(isShowing ? 1.0 : 0.0)
        .animation(DesignSystem.Animation.spring, value: isShowing)
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastData?
    @State private var workItem: DispatchWorkItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let toast = toast {
                        VStack {
                            Spacer()
                            ToastView(
                                message: toast.message,
                                systemImage: toast.systemImage,
                                color: toast.color,
                                isShowing: .constant(true)
                            )
                            .onTapGesture {
                                dismissToast()
                            }
                        }
                        .padding(DesignSystem.Layout.padding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(DesignSystem.Animation.spring, value: toast)
            )
            .onChange(of: toast) { newValue in
                showToastIfNeeded()
            }
    }
    
    private func showToastIfNeeded() {
        guard let _ = toast else { return }
        
        // Cancel previous work item
        workItem?.cancel()
        
        // Create new work item to dismiss toast
        let task = DispatchWorkItem {
            dismissToast()
        }
        
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: task)
    }
    
    private func dismissToast() {
        withAnimation(DesignSystem.Animation.spring) {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

struct ToastData: Equatable {
    let message: String
    let systemImage: String
    let color: Color
    
    init(message: String, systemImage: String, color: Color) {
        self.message = message
        self.systemImage = systemImage
        self.color = color
    }
    
    // Legacy constructor for compatibility
    init(message: String, type: ToastType) {
        self.message = message
        switch type {
        case .success:
            self.systemImage = "checkmark.circle.fill"
            self.color = .green
        case .error:
            self.systemImage = "exclamationmark.circle.fill"
            self.color = .red
        case .info:
            self.systemImage = "info.circle.fill"
            self.color = .blue
        }
    }
    
    static func success(_ message: String) -> ToastData {
        ToastData(message: message, systemImage: "checkmark.circle.fill", color: .green)
    }
    
    static func error(_ message: String) -> ToastData {
        ToastData(message: message, systemImage: "exclamationmark.circle.fill", color: .red)
    }
    
    static func info(_ message: String) -> ToastData {
        ToastData(message: message, systemImage: "info.circle.fill", color: .blue)
    }
}

enum ToastType {
    case success
    case error
    case info
}

extension View {
    func toast(_ toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
    
    // Legacy method for backward compatibility
    func toast(data toast: Binding<ToastData?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
    
    // New method for simple message + isShowing binding
    func toast(message: String, isShowing: Binding<Bool>) -> some View {
        self.toast(Binding<ToastData?>(
            get: {
                isShowing.wrappedValue ? ToastData.info(message) : nil
            },
            set: { newValue in
                isShowing.wrappedValue = newValue != nil
            }
        ))
    }
} 