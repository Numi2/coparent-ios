# Modern Swift Development

Write idiomatic SwiftUI code following Apple's latest architectural recommendations and best practices.

## Co-Parent App: Current Architecture State

### Project Overview
Co-Parent is a dating app for co-parents built with SwiftUI and modern iOS development practices. The app uses Sendbird Chat SDK for real-time messaging and follows a glass morphism design system.

### Current Implementation Status
- **Authentication**: Complete with SwiftUI onboarding flow
- **Chat System**: Sendbird SDK integrated with @Observable state management
- **UI Design**: Glass morphism design system implemented
- **State Management**: Using @State, @Observable, and @Environment appropriately
- **Async Operations**: Fully async/await based with proper error handling

### Key Architectural Decisions

#### 1. State Management Pattern
```swift
// ✅ Using @Observable for shared services (iOS 17+)
@Observable
class SendbirdChatService {
    private(set) var channels: [GroupChannel] = []
    private(set) var messages: [BaseMessage] = []
    // ...
}

// ✅ Local view state with @State
struct ChatDetailView: View {
    @State private var messageText = ""
    @State private var isLoading = false
    // ...
}
```

#### 2. Service Layer Architecture
Services are implemented as @Observable singletons:
- `SendbirdChatService`: Chat functionality and real-time updates
- `MessageStatusService`: Message status tracking and UI states
- `SendbirdService`: SDK initialization and connection management

#### 3. Error Handling Pattern
```swift
// ✅ Consistent async error handling
private func loadData() async {
    do {
        let data = try await service.fetchData()
        self.data = data
    } catch {
        self.error = error
        self.showingError = true
    }
}
```

#### 4. SwiftUI View Organization
- Views are focused and single-purpose
- Message-related views are grouped in `Views/Chat/`
- Reusable components follow glass morphism design
- Each view handles its own local state appropriately

### Current Challenges & Solutions

#### Challenge: Sendbird SDK Integration with SwiftUI
**Solution**: Wrapped Sendbird callbacks in @Observable classes with @MainActor updates:
```swift
func channel(_ channel: GroupChannel, didReceive message: BaseMessage) {
    Task { @MainActor in
        self.messages.append(message)
    }
}
```

#### Challenge: Real-time UI Updates
**Solution**: Using @Observable ensures automatic SwiftUI updates when Sendbird data changes.

#### Challenge: Glass Morphism Consistency
**Solution**: Created design system with standardized modifiers and components.

## Core Philosophy

- SwiftUI is the default UI paradigm for Apple platforms - embrace its declarative nature
- Avoid legacy UIKit patterns and unnecessary abstractions
- Focus on simplicity, clarity, and native data flow
- Let SwiftUI handle the complexity - don't fight the framework

## Architecture Guidelines

### 1. Embrace Native State Management

Use SwiftUI's built-in property wrappers appropriately:
- `@State` - Local, ephemeral view state
- `@Binding` - Two-way data flow between views
- `@Observable` - Shared state (iOS 17+)
- `@ObservableObject` - Legacy shared state (pre-iOS 17)
- `@Environment` - Dependency injection for app-wide concerns

### 2. State Ownership Principles

- Views own their local state unless sharing is required
- State flows down, actions flow up
- Keep state as close to where it's used as possible
- Extract shared state only when multiple views need it

### 3. Modern Async Patterns

- Use `async/await` as the default for asynchronous operations
- Leverage `.task` modifier for lifecycle-aware async work
- Avoid Combine unless absolutely necessary
- Handle errors gracefully with try/catch

### 4. View Composition

- Build UI with small, focused views
- Extract reusable components naturally
- Use view modifiers to encapsulate common styling
- Prefer composition over inheritance

### 5. Code Organization

- Organize by feature, not by type (avoid Views/, Models/, ViewModels/ folders)
- Keep related code together in the same file when appropriate
- Use extensions to organize large files
- Follow Swift naming conventions consistently

## Implementation Patterns

### Simple State Example
```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") { 
                count += 1 
            }
        }
    }
}
```

### Shared State with @Observable
```swift
@Observable
class UserSession {
    var isAuthenticated = false
    var currentUser: User?
    
    func signIn(user: User) {
        currentUser = user
        isAuthenticated = true
    }
}

struct MyApp: App {
    @State private var session = UserSession()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(session)
        }
    }
}
```

### Async Data Loading
```swift
struct ProfileView: View {
    @State private var profile: Profile?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let profile {
                ProfileContent(profile: profile)
            } else if let error {
                ErrorView(error: error)
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            profile = try await ProfileService.fetch()
        } catch {
            self.error = error
        }
    }
}
```

## Co-Parent App Specific Patterns

### Chat Message Handling
```swift
// ✅ Proper integration with Sendbird
struct MessageBubbleView: View {
    let message: BaseMessage
    @State private var statusService = MessageStatusService.shared
    
    var body: some View {
        HStack {
            // Message content
            Text(messageText)
                .glassCard()
            
            // Status indicator
            Image(systemName: statusService.getStatusIcon(for: message))
                .foregroundColor(statusService.getStatusColor(for: message))
        }
    }
}
```

### Glass Morphism Implementation
```swift
// ✅ Consistent glass effects
extension View {
    func glassCard() -> some View {
        self
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
    }
}
```

## Best Practices

### DO:
- Write self-contained views when possible
- Use property wrappers as intended by Apple
- Test logic in isolation, preview UI visually
- Handle loading and error states explicitly
- Keep views focused on presentation
- Use Swift's type system for safety
- Follow the established glass morphism design patterns
- Integrate properly with Sendbird SDK using @Observable

### DON'T:
- Create ViewModels for every view
- Move state out of views unnecessarily
- Add abstraction layers without clear benefit
- Use Combine for simple async operations
- Fight SwiftUI's update mechanism
- Overcomplicate simple features
- Break the established design system
- Create UIKit bridges unless absolutely necessary

## Testing Strategy

- Unit test business logic and data transformations
- Use SwiftUI Previews for visual testing
- Test @Observable classes independently
- Keep tests simple and focused
- Don't sacrifice code clarity for testability

## Modern Swift Features

- Use Swift Concurrency (async/await, actors)
- Leverage Swift 6 data race safety when available
- Utilize property wrappers effectively
- Embrace value types where appropriate
- Use protocols for abstraction, not just for testing

## Development Workflow for AI Agent

### When Starting a New Task:
1. Examine existing code patterns in the relevant area
2. Check how similar functionality is implemented elsewhere
3. Follow the established service layer pattern
4. Ensure proper @Observable integration
5. Apply glass morphism design consistently

### When Adding New Features:
1. Consider impact on existing Sendbird integration
2. Maintain consistency with established error handling
3. Follow the async/await patterns already in place
4. Add proper accessibility support
5. Create SwiftUI previews for visual testing

### When Refactoring:
1. Preserve existing SwiftUI state management patterns
2. Maintain @Observable service architecture
3. Keep glass morphism design system intact
4. Don't break existing Sendbird delegate patterns

## Summary

Write SwiftUI code that looks and feels like SwiftUI. The framework has matured significantly - trust its patterns and tools. Focus on solving user problems rather than implementing architectural patterns from other platforms.

For the Co-Parent app specifically, maintain the established patterns around Sendbird integration, @Observable state management, and glass morphism design. The architecture is already well-established - focus on extending it consistently rather than changing fundamental patterns.