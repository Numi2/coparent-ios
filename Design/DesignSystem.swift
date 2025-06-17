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

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignSystem.Layout.padding)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius)
                    .fill(Color.white.opacity(0.1))
                    .background(.ultraThinMaterial)
            )
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