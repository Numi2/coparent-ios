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

### Recently Completed: Advanced Chat Features (Task 6)

#### Key Achievements:
1. **Pull-to-Refresh Message History**: Implemented native SwiftUI refreshable modifier with smooth loading indicators
2. **Infinite Scrolling**: Added automatic message pagination when scrolling to the top with performance optimization
3. **Advanced Message Search**: Created comprehensive search functionality with real-time results and keyword highlighting
4. **Enhanced Keyboard Handling**: Implemented sophisticated keyboard avoidance with smooth animations and multi-line text support

#### Technical Implementation:
- **Enhanced SendbirdChatService**: Added `loadOlderMessages()`, `refreshMessages()`, `searchMessages()`, and `clearSearch()` methods
- **ChatSearchBar Component**: Created glass morphism search interface with debounced search and smooth animations
- **ChatSearchResultsView Component**: Built search results display with highlighted keywords and message navigation
- **KeyboardAdaptive Modifier**: Implemented custom modifier for optimal keyboard handling with proper safe area adjustments
- **Improved ChatDetailView**: Completely restructured with modular components and advanced state management
- **GlassTextFieldStyle**: Enhanced text field styling with glass morphism consistency

#### Code Architecture Patterns Used:
- @Observable pattern for advanced chat state management across components
- @MainActor for UI updates from async search and pagination operations
- Proper async/await patterns for all new chat operations with comprehensive error handling
- Glass morphism design system consistency throughout all new components
- Debounced search with Timer-based optimization for performance
- SwiftUI NavigationPath and ScrollViewReader for smooth message navigation
- Custom ViewModifiers for reusable keyboard handling functionality
- LazyVStack optimization for infinite scrolling performance

#### Integration Details:
- Pull-to-refresh utilizes Sendbird's message pagination with proper timestamp handling
- Infinite scrolling triggers when the first message appears with hasMoreMessages validation
- Search functionality uses Sendbird's MessageSearchQuery with keyword highlighting and result navigation
- Keyboard handling adapts to various input states (single-line, multi-line, emoji picker)
- All search and pagination operations maintain existing chat functionality (reactions, threading, editing)
- Real-time updates continue to work seamlessly during search and pagination
- Error handling provides user feedback via toast notifications for all operations
- Accessibility support maintained throughout all new components with proper labels and hints

#### Performance Optimizations:
- Debounced search prevents excessive API calls during typing
- LazyVStack ensures smooth scrolling with large message histories
- Pagination loads messages in configurable chunks (AppConfig.Chat.messagePageSize)
- Search results are cached until query changes
- Smooth animations prevent UI jank during state transitions
- Memory management for large chat histories with proper message cleanup

### Recently Completed: Super Like Feature (Task 7)

#### Key Achievements:
1. **Complete Super Like Infrastructure**: Implemented comprehensive super like functionality with premium subscription integration and cooldown management
2. **Animated SuperLikeView Component**: Created stunning star burst animation with glass morphism styling and smooth particle effects
3. **Premium SuperLikeButton Component**: Built floating action button with glow effects, cooldown timer, and subscription status indicators
4. **Enhanced MatchService**: Extended with super like functionality including analytics tracking and state persistence
5. **Integrated Gesture Recognition**: Added vertical swipe gesture for super like activation with specialized haptic feedback

#### Technical Implementation:
- **SuperLikeView Component**: Complete animation system with star particles, radial gradients, and glass morphism styling
- **SuperLikeButton Component**: Premium-styled floating button with pulse animations, cooldown timers, and accessibility support
- **Enhanced MatchService**: Added `superLike()` method, cooldown logic, premium status management, and analytics tracking
- **MatchCardView Integration**: Added vertical swipe gesture recognition, super like overlay feedback, and button integration
- **MatchView Enhancement**: Updated with super like status indicators, enhanced match alerts, and action button integration

#### Code Architecture Patterns Used:
- @Observable pattern for super like state management across components
- @MainActor for UI updates from async super like operations
- Proper async/await patterns for all super like operations with comprehensive error handling
- Glass morphism design system consistency throughout all new components
- UserDefaults persistence for super like state and cooldown management
- Analytics tracking infrastructure for super like usage metrics
- Haptic feedback integration with UINotificationFeedbackGenerator for premium feel
- SwiftUI particle animation system using TimelineView for visual effects

#### Integration Details:
- Super like functionality utilizes daily limits (1 for free users, 5 for premium)
- Cooldown system prevents abuse with 24-hour reset cycle
- Premium users get enhanced match probability (80% vs 60% for free users)
- Vertical swipe gesture activates super like with specialized haptic feedback
- SuperLikeButton appears on match cards with status-aware styling
- Real-time super like status indicators in header showing remaining count/cooldown
- Enhanced match notifications distinguish super like matches from regular matches
- Complete accessibility support with VoiceOver labels and hints
- Analytics tracking for super like usage and conversion metrics

#### Performance Optimizations:
- Efficient particle animation system with proper cleanup
- State persistence using UserDefaults for offline functionality
- Smooth animations with spring physics for natural feel
- Memory-efficient star burst effects with reusable components
- Proper gesture recognition with threshold-based activation

### Next Priority: Enhanced Matching Features (Task 8)

**Upcoming Task: Advanced Filtering System**
**Objective: Implement comprehensive filtering with smart recommendations**

#### Planned Implementation Areas:
1. **AdvancedFiltersView Component Creation**
   - Design multi-section filter interface with collapsible glass cards
   - Implement search functionality for location-based filtering with MapKit integration
   - Create interest-based filtering with multiple selection and smart suggestions
   - Include deal-breaker settings with clear warning indicators
   - Add filter preset saving and loading functionality with CoreData

2. **SmartFiltersService Implementation**
   - Create @Observable service for filter state management with proper async/await patterns
   - Add machine learning-based filter suggestions using Core ML
   - Implement filter analytics for optimization and user behavior tracking
   - Include location-based smart defaults with privacy-conscious implementation
   - Add cloud sync for filter preferences across devices

3. **Enhanced Distance and Location Filtering**
   - Add map-based location selection with native MapKit SwiftUI integration
   - Implement radius visualization on map with interactive controls
   - Add multiple location support (home, work) with smart switching
   - Include travel mode for temporary location changes
   - Add location-based push notifications for matches in new areas

4. **Compatibility Scoring System**
   - Implement parenting style compatibility algorithm with weighted factors
   - Add interest overlap calculation with dynamic scoring
   - Create lifestyle compatibility metrics based on user preferences
   - Include communication style matching using behavioral analysis
   - Display compatibility scores in cards with clear visual indicators

5. **Filter Persistence System**
   - Implement CoreData/SwiftData for filter storage with proper relationships
   - Add cloud sync for filter preferences using CloudKit
   - Create quick filter presets (nearby, highly compatible) with smart suggestions
   - Add filter history and analytics with privacy-compliant tracking
   - Include export/import functionality for backup and migration

#### Technical Planning:
- Will use @Observable for advanced filter state management across components
- Implement async/await patterns for all filter operations with proper error handling
- Add proper MapKit integration with SwiftUI for location-based features
- Use Core ML for compatibility scoring algorithms and smart recommendations
- Follow established error handling patterns with comprehensive user feedback
- Maintain glass morphism design consistency throughout all new components
- Add complete accessibility support with VoiceOver labels and hints

#### Development Approach:
- Work methodically through each filtering component starting with UI
- Integrate with existing MatchService patterns and maintain consistency
- Test location services on device for optimal performance and battery efficiency
- Follow established SwiftUI and design system architectural patterns
- Add proper testing via SwiftUI previews for all filter states
- Document all filtering algorithm and machine learning implementation details

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