import SwiftUI

struct MatchView: View {
    @Environment(AppState.self) private var appState
    @State private var matchService: MatchService
    @State private var smartFiltersService = SmartFiltersService.shared
    @State private var showingMatchAlert = false
    @State private var matchedUser: User?
    @State private var showingFilters = false
    @State private var isSuperLikeMatch = false
    
    init(user: User) {
        _matchService = State(initialValue: MatchService(currentUser: user))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Cards area
                GeometryReader { geometry in
                    if matchService.isLoading {
                        ProgressView("Finding matches...")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if matchService.filteredMatches.isEmpty {
                        emptyStateView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        cardStackView(in: geometry)
                    }
                }
                
                // Action buttons
                if !matchService.filteredMatches.isEmpty && !matchService.isLoading {
                    actionButtonsView
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await matchService.loadPotentialMatches()
            matchService.refreshSuperLikes()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newMatch)) { notification in
            if let match = notification.userInfo?["match"] as? User {
                matchedUser = match
                isSuperLikeMatch = notification.userInfo?["isSuperLikeMatch"] as? Bool ?? false
                showingMatchAlert = true
            }
        }
        .alert(isSuperLikeMatch ? "Super Like Match! ⭐" : "It's a Match! 🎉", isPresented: $showingMatchAlert) {
            Button("Start Chat") {
                // TODO: Navigate to chat
            }
            Button("Keep Swiping", role: .cancel) {}
        } message: {
            if let match = matchedUser {
                if isSuperLikeMatch {
                    Text("Your Super Like worked! You and \(match.name) have matched! 🌟")
                } else {
                    Text("You and \(match.name) have matched! Start a conversation now.")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            AdvancedFiltersView()
                .onDisappear {
                    // Refresh matches when filters are updated
                    Task { @MainActor in
                        matchService.applyFiltersAndSorting()
                    }
                }
        }
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Discover")
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    if !matchService.filteredMatches.isEmpty {
                        Text("\(matchService.filteredMatches.count) matches")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Smart filters indicator
                    if smartFiltersService.currentFilters != FilterSet() {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption)
                                .foregroundColor(.purple)
                            
                            Text("Smart Filtered")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.purple)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.purple.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    // Super Like status indicator
                    if matchService.isPremiumUser {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            if matchService.canUseSuperLike {
                                Text("\(matchService.superLikesRemaining) Super Likes")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.blue)
                            } else {
                                Text(formatCooldownTime(matchService.superLikeCooldownTimeRemaining))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            Button(action: { showingFilters = true }) {
                ZStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                    // Active filter indicator
                    if smartFiltersService.currentFilters != FilterSet() {
                        Circle()
                            .fill(.purple)
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -12)
                    }
                }
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No More Matches")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                if smartFiltersService.currentFilters != FilterSet() {
                    Text("Try adjusting your filters or check back later for new matches")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 12) {
                        Button("Adjust Filters") {
                            showingFilters = true
                        }
                        .buttonStyle(GlassPrimaryButtonStyle())
                        
                        Button("Reset Filters") {
                            Task { @MainActor in
                                smartFiltersService.resetFilters()
                                matchService.applyFiltersAndSorting()
                            }
                        }
                        .buttonStyle(GlassSecondaryButtonStyle())
                    }
                } else {
                    Text("Check back later for new potential matches or expand your search area")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Expand Search") {
                        showingFilters = true
                    }
                    .buttonStyle(GlassPrimaryButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private func cardStackView(in geometry: GeometryProxy) -> some View {
        let cardWidth = min(geometry.size.width - 40, 350)
        let cardHeight = min(geometry.size.height - 100, 600)
        
        ZStack {
            ForEach(Array(matchService.filteredMatches.prefix(3).enumerated()), id: \.element.id) { index, user in
                let isTopCard = index == 0
                let scale = isTopCard ? 1.0 : 1.0 - (Double(index) * 0.05)
                let offset = CGFloat(index) * 8
                
                MatchCardView(
                    user: user,
                    onLike: {
                        withAnimation(.spring()) {
                            handleLike()
                        }
                    },
                    onPass: {
                        withAnimation(.spring()) {
                            handlePass()
                        }
                    },
                    onSuperLike: {
                        withAnimation(.spring()) {
                            handleSuperLike()
                        }
                    },
                    canUseSuperLike: matchService.canUseSuperLike,
                    isPremium: matchService.isPremiumUser,
                    superLikeCooldownTimeRemaining: matchService.superLikeCooldownTimeRemaining,
                    compatibilityScore: smartFiltersService.calculateCompatibilityScore(
                        for: user,
                        with: appState.currentUser ?? user
                    )
                )
                .frame(width: cardWidth, height: cardHeight)
                .scaleEffect(scale)
                .offset(y: offset)
                .zIndex(Double(3 - index))
                .allowsHitTesting(isTopCard)
                .opacity(isTopCard ? 1.0 : 0.8)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
    
    @ViewBuilder
    private var actionButtonsView: some View {
        HStack(spacing: 40) {
            // Pass button
            Button(action: {
                withAnimation(.spring()) {
                    handlePass()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(.red.gradient)
                    .clipShape(Circle())
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(1.0)
            .animation(.spring(), value: matchService.filteredMatches.count)
            
            // Super Like button
            SuperLikeButton(
                onSuperLike: {
                    withAnimation(.spring()) {
                        handleSuperLike()
                    }
                },
                isEnabled: matchService.canUseSuperLike,
                isPremium: matchService.isPremiumUser,
                cooldownTimeRemaining: matchService.superLikeCooldownTimeRemaining
            )
            .scaleEffect(0.8) // Slightly smaller for action button area
            
            // Like button
            Button(action: {
                withAnimation(.spring()) {
                    handleLike()
                }
            }) {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(.green.gradient)
                    .clipShape(Circle())
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(1.0)
            .animation(.spring(), value: matchService.filteredMatches.count)
        }
        .padding(.horizontal, 20)
    }
    
    private func handleLike() {
        guard !matchService.filteredMatches.isEmpty else { return }
        
        Task {
            await matchService.like()
        }
    }
    
    private func handleSuperLike() {
        guard !matchService.filteredMatches.isEmpty else { return }
        guard matchService.canUseSuperLike else { return }
        
        Task {
            await matchService.superLike()
        }
    }
    
    private func handlePass() {
        guard !matchService.filteredMatches.isEmpty else { return }
        
        matchService.pass()
    }
    
    private func formatCooldownTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "Ready soon"
        }
    }
}

struct FilterView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var ageRange: ClosedRange<Double> = 25...45
    @State private var maxDistance: Double = 50
    @State private var selectedParentingStyles: Set<User.ParentingStyle> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Age Range") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("\(Int(ageRange.lowerBound))")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(ageRange.upperBound))")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(.secondary)
                        }
                        
                        RangeSlider(
                            range: $ageRange,
                            bounds: 18...65,
                            step: 1
                        )
                    }
                }
                
                Section("Distance") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Within \(Int(maxDistance)) km")
                                .font(DesignSystem.Typography.callout)
                            
                            Spacer()
                        }
                        
                        Slider(value: $maxDistance, in: 5...100, step: 5)
                    }
                }
                
                Section("Parenting Styles") {
                    ForEach(User.ParentingStyle.allCases, id: \.self) { style in
                        HStack {
                            Text(style.rawValue.capitalized)
                                .font(DesignSystem.Typography.body)
                            
                            Spacer()
                            
                            if selectedParentingStyles.contains(style) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedParentingStyles.contains(style) {
                                selectedParentingStyles.remove(style)
                            } else {
                                selectedParentingStyles.insert(style)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        ageRange = 25...45
                        maxDistance = 50
                        selectedParentingStyles.removeAll()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        // TODO: Apply filters
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        // This is a simplified implementation
        // In a real app, you'd want a proper range slider component
        VStack {
            HStack {
                Slider(
                    value: Binding(
                        get: { range.lowerBound },
                        set: { newValue in
                            range = newValue...max(newValue, range.upperBound)
                        }
                    ),
                    in: bounds,
                    step: step
                )
                
                Slider(
                    value: Binding(
                        get: { range.upperBound },
                        set: { newValue in
                            range = min(newValue, range.lowerBound)...newValue
                        }
                    ),
                    in: bounds,
                    step: step
                )
            }
        }
    }
}

#Preview("Match View - With Cards") {
    NavigationStack {
        MatchView(user: User(
            id: "1",
            name: "John Doe",
            userType: .singleParent,
            email: "john@example.com",
            phoneNumber: "+1234567890",
            dateOfBirth: Date().addingTimeInterval(-35 * 365 * 24 * 60 * 60),
            profileImageURL: nil,
            bio: "Single father of two amazing kids. Love outdoor activities and cooking.",
            location: User.Location(
                city: "San Francisco",
                state: "CA",
                country: "USA",
                coordinates: User.Location.Coordinates(latitude: 37.7749, longitude: -122.4194)
            ),
            parentingStyle: .authoritative,
            children: [
                User.Child(id: "1", name: "Alex", age: 8, gender: .male, interests: ["sports", "gaming"]),
                User.Child(id: "2", name: "Sam", age: 5, gender: .female, interests: ["art", "music"])
            ],
            preferences: User.Preferences(
                ageRange: 30...45,
                distance: 50,
                parentingStyles: [.authoritative, .gentle],
                dealBreakers: []
            ),
            interests: [.outdoorActivities, .cooking, .sports, .music],
            verificationStatus: .verified
        ))
    }
}

#Preview("Filter View") {
    FilterView()
} 
