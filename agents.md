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

#### Challenge: Modern Image Messaging with Multiple Uploads
**Solution**: Replaced legacy UIImagePickerController with PhotosUI framework:
```swift
@State private var selectedImages: [UIImage] = []
PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images)
```

### Recently Completed: Enhanced Image Message Support (Task 3)

#### Key Achievements:
1. **Modern PhotosPicker Integration**: Replaced UIImagePickerController with PhotosUI framework for native iOS 16+ experience
2. **Multiple Image Support**: Users can now select and send up to 5 images at once
3. **Rich Image Experience**: Full-screen viewing with zoom/pan gestures, save to Photos, and sharing
4. **Image Preview & Editing**: Pre-send carousel with basic editing tools (rotate, scale, brightness, contrast)
5. **Glass Morphism Throughout**: All new components follow the established design system

#### Technical Implementation:
- `ModernImagePicker`: PhotosUI-based picker with glass morphism styling
- `ImageMessageView`: Enhanced message display with action overlays
- `FullScreenImageView`: Zoomable full-screen experience with gestures
- `ImagePreviewView`: Pre-send carousel with editing capabilities
- `SimpleImageEditor`: Basic photo editing with real-time preview
- Enhanced `SendbirdChatService` with `sendImages()` for batch uploads

#### Code Architecture Patterns Used:
- @Observable for state management across components
- @MainActor for UI updates from async operations
- Proper async/await patterns for image loading and uploads
- Glass morphism design system consistency
- Comprehensive error handling with user feedback
- SwiftUI previews for all components

### Recently Completed: Message Reactions System (Task 4)

#### Key Achievements:
1. **Complete Reaction Infrastructure**: Extended `SendbirdChatService` with comprehensive reaction functionality
2. **Glass Morphism Reaction Picker**: Native emoji picker with smooth animations and haptic feedback
3. **Real-time Reaction Updates**: Live reaction updates across all connected devices
4. **Interactive Reaction Display**: Users can tap reactions to add/remove their own reactions
5. **Accessibility Support**: Complete VoiceOver support for all reaction components

#### Technical Implementation:
- **Extended SendbirdChatService**: Added `addReaction()`, `removeReaction()`, `hasUserReacted()`, and `getUserReactionKey()` methods
- **ReactionPickerView**: Glass morphism emoji picker with 8 common reactions (👍, ❤️, 😂, 😮, 😢, 😡, 🎉, 👏)
- **MessageReactionsView**: Displays reactions with counts and user interaction
- **ReactionCountView**: Individual reaction bubbles with glass morphism styling
- **Enhanced ChannelDelegate**: Added `updatedReaction` handler for real-time updates

#### Code Architecture Patterns Used:
- @Observable pattern for reaction state management
- async/await for all reaction operations with proper error handling
- @MainActor for UI updates from Sendbird delegate callbacks
- Glass morphism styling consistent with design system
- Interactive animations with spring effects
- Toast notifications for user feedback
- Sheet presentation with proper detents for reaction picker
- Context menu integration for quick reaction access
- Accessibility labels and hints for VoiceOver users

#### Integration Details:
- Reactions appear below message bubbles with proper spacing
- Context menu includes "Add Reaction" option for all messages
- Reaction picker slides up from bottom with drag indicator
- Real-time updates through Sendbird's ReactionEvent system
- User's own reactions highlighted with blue styling
- Reaction counts display when multiple users react
- Smooth animations for reaction addition/removal

### Recently Completed: Message Threading Support (Task 5)

#### Key Achievements:
1. **Complete Threading Infrastructure**: Implemented comprehensive message threading functionality with native Sendbird integration
2. **ThreadView Component**: Created full-featured thread conversation interface with glass morphism design
3. **ReplyBar Component**: Built parent message context display with proper message type handling
4. **ThreadIndicatorView Component**: Developed interactive thread indicators showing reply counts
5. **Enhanced Message Navigation**: Added seamless navigation between main chat and thread conversations

#### Technical Implementation:
- **ThreadView**: Complete thread interface with parent message context, scrollable thread messages, and dedicated input controls
- **ReplyBar**: Glass morphism component showing original message preview with message type icons and sender information  
- **ThreadIndicatorView**: Interactive button displaying reply count with proper accessibility support
- **Enhanced MessageBubbleView**: Integrated thread indicator display and reply navigation via context menu
- **Navigation Flow**: FullScreenCover presentation with proper state management and dismiss handling
- **Real-time Updates**: Comprehensive delegate handling for thread info updates and parent message refresh

#### Code Architecture Patterns Used:
- @Observable pattern for thread state management across components
- @MainActor for UI updates from async thread operations
- Proper async/await patterns for all thread-related operations
- Glass morphism design system consistency throughout all new components
- Comprehensive error handling with user feedback via toast notifications
- SwiftUI previews for all new components for development testing
- Native SwiftUI navigation patterns with fullScreenCover and proper dismiss
- Complete accessibility support with labels and hints for VoiceOver users

#### Integration Details:
- Threading functionality utilizes existing SendbirdChatService methods (fetchThreadMessages, sendThreadMessage, sendThreadImage)
- Real-time updates through enhanced ChannelDelegate with didReceiveThreadInfo handling
- Thread indicators appear on parent messages with proper reply count display
- Context menu includes "Reply in thread" option for all messages
- Thread view provides complete conversation context with ReplyBar showing parent message
- Navigation maintains proper state management and exits cleanly
- All components follow established glass morphism design principles
- Toast notifications provide user feedback for all thread operations

### Next Priority: Advanced Chat Features (Task 6)

**Upcoming Task: Implement Advanced Chat Features**
**Objective: Add modern chat UX improvements**

#### Planned Implementation Areas:
1. **Pull-to-Refresh for Message History**
   - Implement SwiftUI refreshable modifier for message loading
   - Add glass-styled refresh indicator following design system
   - Handle message pagination properly with state management
   - Maintain scroll position after refresh for better UX

2. **Infinite Scrolling Implementation**  
   - Add automatic message loading when scrolling up
   - Create smooth loading indicators with glass morphism styling
   - Handle memory management for large chat histories
   - Implement message cleanup for optimal performance

3. **Advanced Keyboard Handling**
   - Implement proper keyboard avoidance with native SwiftUI
   - Add keyboard toolbar with quick actions
   - Handle keyboard animations smoothly
   - Support external keyboard shortcuts for power users

4. **Message Search Functionality**
   - Add search bar to chat detail view with glass styling
   - Implement message filtering and highlighting
   - Create search results navigation
   - Follow glass morphism design for search UI

#### Technical Planning:
- Will use @Observable for search state management
- Implement async/await patterns for search operations
- Add proper keyboard handling with @FocusState
- Use LazyVStack for infinite scrolling performance
- Follow established error handling patterns
- Maintain glass morphism design consistency
- Add comprehensive accessibility support

#### Development Approach:
- Work methodically through each subtask
- Integrate with existing SendbirdChatService patterns
- Maintain performance with large message histories
- Follow established SwiftUI and design system patterns
- Add proper testing via SwiftUI previews
- Document architecture decisions and implementation details

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