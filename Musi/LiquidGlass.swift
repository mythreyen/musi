import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: - Liquid Glass Design Language (iOS / macOS Golden Gate)
// ─────────────────────────────────────────────────────────────

/// High-fidelity liquid glass background for circular buttons and icons.
/// Simulates physical glass lens curvature, specular reflection, and caustics.
struct LiquidGlassCircleBackground: View {
    var isActive: Bool = false
    var isHovered: Bool = false
    var isPressed: Bool = false
    var isMain: Bool = false
    var tint: Color? = nil
    
    var body: some View {
        ZStack {
            // 1. Physical glass substrate (Frosted blur)
            Circle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // 2. Volumetric glass refraction fill
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            (tint ?? .white).opacity(isActive ? (isMain ? 0.38 : 0.30) : (isHovered ? 0.22 : (isMain ? 0.18 : 0.10))),
                            (tint ?? .white).opacity(isActive ? (isMain ? 0.24 : 0.18) : (isHovered ? 0.10 : (isMain ? 0.08 : 0.04)))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 3. Convex specular dome highlight (Light incident from top)
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.48 : (isMain ? 0.40 : 0.32)),
                            Color.white.opacity(isHovered ? 0.20 : (isMain ? 0.16 : 0.10)),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .padding(0.8)
            
            // 4. Subtle bottom specular floor reflex
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(isHovered ? 0.16 : 0.09)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
                .padding(0.8)
            
            // 5. Specular rim bevel (Fresnel edge gradient)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            (tint ?? .white).opacity(isActive ? 0.75 : (isHovered ? 0.58 : 0.38)),
                            Color.white.opacity(isHovered ? 0.28 : 0.14),
                            Color.white.opacity(isHovered ? 0.38 : 0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isMain ? 1.25 : 0.85
                )
        }
        // Dual-layer caustic depth & active glow bloom
        .shadow(
            color: isActive && tint != nil ? tint!.opacity(0.4) : Color.black.opacity(isMain ? 0.35 : 0.22),
            radius: isMain ? (isHovered ? 10 : 7) : (isHovered ? 5 : 3),
            x: 0,
            y: isMain ? 4 : 1.5
        )
    }
}

/// Liquid glass background for pill/capsule shapes.
struct LiquidGlassCapsuleBackground: View {
    var isActive: Bool = false
    var isHovered: Bool = false
    var isPressed: Bool = false
    var tint: Color? = nil
    
    var body: some View {
        ZStack {
            // 1. Material base
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // 2. Base refraction
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            (tint ?? .white).opacity(isActive ? 0.28 : (isHovered ? 0.20 : 0.10)),
                            (tint ?? .white).opacity(isActive ? 0.16 : (isHovered ? 0.08 : 0.04))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 3. Convex specular dome highlight
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.white.opacity(isHovered ? 0.44 : 0.32),
                        Color.white.opacity(isHovered ? 0.16 : 0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 14)
                .clipShape(Capsule())
                Spacer(minLength: 0)
            }
            .padding(0.8)
            
            // 4. Bottom reflex
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(isHovered ? 0.16 : 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 8)
                .clipShape(Capsule())
            }
            .padding(0.8)
            
            // 5. Specular rim bevel
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            (tint ?? .white).opacity(isActive ? 0.70 : (isHovered ? 0.52 : 0.34)),
                            Color.white.opacity(isHovered ? 0.24 : 0.12),
                            Color.white.opacity(isHovered ? 0.34 : 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        }
        .shadow(
            color: isActive && tint != nil ? tint!.opacity(0.35) : Color.black.opacity(isHovered ? 0.25 : 0.16),
            radius: isHovered ? 6 : 3.5,
            x: 0,
            y: 2
        )
    }
}

/// Liquid glass background for rounded card panels and option tiles.
struct LiquidGlassCardBackground: View {
    var cornerRadius: CGFloat = 14
    var isActive: Bool = false
    var isHovered: Bool = false
    var isPressed: Bool = false
    var tint: Color? = nil
    
    var body: some View {
        ZStack {
            // 1. Material base
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // 2. Base refraction
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            (tint ?? .white).opacity(isActive ? 0.24 : (isHovered ? 0.16 : 0.07)),
                            (tint ?? .white).opacity(isActive ? 0.14 : (isHovered ? 0.07 : 0.02))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 3. Top specular highlight
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        Color.white.opacity(isHovered ? 0.40 : 0.26),
                        Color.white.opacity(isHovered ? 0.12 : 0.05),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 18)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                Spacer(minLength: 0)
            }
            .padding(0.8)
            
            // 4. Specular rim bevel
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            (tint ?? .white).opacity(isActive ? 0.70 : (isHovered ? 0.48 : 0.30)),
                            Color.white.opacity(isHovered ? 0.22 : 0.09),
                            Color.white.opacity(isHovered ? 0.32 : 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        }
        .shadow(
            color: isActive && tint != nil ? tint!.opacity(0.35) : Color.black.opacity(isHovered ? 0.24 : 0.12),
            radius: isHovered ? 8 : 4,
            x: 0,
            y: 2
        )
    }
}

// ─────────────────────────────────────────────────────────────
// MARK: - Reusable Liquid Glass Interactive Buttons
// ─────────────────────────────────────────────────────────────

/// Full liquid glass circular button with tactile spring dynamics and specular sheen.
struct LiquidGlassCircleButton: View {
    let icon: String
    var size: CGFloat = 26
    var iconSize: CGFloat = 12
    var weight: Font.Weight = .medium
    var isActive: Bool = false
    var activeTint: Color? = nil
    var isMain: Bool = false
    var helpText: String? = nil
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                LiquidGlassCircleBackground(
                    isActive: isActive,
                    isHovered: isHovered,
                    isPressed: isPressed,
                    isMain: isMain,
                    tint: isActive ? (activeTint ?? .white) : nil
                )
                
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: weight))
                    .foregroundStyle(
                        isActive
                            ? Color.white
                            : (isHovered ? Color.white : Color.white.opacity(0.75))
                    )
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            }
            .frame(width: size, height: size)
            .scaleEffect(isPressed ? 0.92 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isPressed)
            .animation(.spring(response: 0.26, dampingFraction: 0.75), value: isHovered)
            .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .modifier(OptionalHelpModifier(helpText: helpText))
    }
}

/// Helper modifier to conditionally apply tooltip help
struct OptionalHelpModifier: ViewModifier {
    let helpText: String?
    
    func body(content: Content) -> some View {
        if let text = helpText {
            content.help(text)
        } else {
            content
        }
    }
}

/// Full liquid glass pill/capsule button.
struct LiquidGlassPillButton<Label: View>: View {
    var isActive: Bool = false
    var tint: Color? = nil
    let action: () -> Void
    let label: () -> Label
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    init(
        isActive: Bool = false,
        tint: Color? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.isActive = isActive
        self.tint = tint
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button(action: action) {
            label()
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    LiquidGlassCapsuleBackground(
                        isActive: isActive,
                        isHovered: isHovered,
                        isPressed: isPressed,
                        tint: tint
                    )
                )
                .contentShape(Capsule())
                .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.03 : 1.0))
                .animation(.spring(response: 0.24, dampingFraction: 0.65), value: isPressed)
                .animation(.spring(response: 0.26, dampingFraction: 0.75), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
