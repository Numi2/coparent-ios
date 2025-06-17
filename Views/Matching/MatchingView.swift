import SwiftUI

struct MatchingView: View {
    @StateObject private var viewModel = MatchingViewModel()
    @State private var showingFilters = false
    
    var body: some View {
        ZStack {
            DesignSystem.Glass.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Layout.spacing) {
                // Header
                HStack {
                    Text("Find Matches")
                        .font(DesignSystem.Typography.title)
                    
                    Spacer()
                    
                    GlassIconButton(
                        systemName: "slider.horizontal.3",
                        action: { showingFilters = true },
                        color: DesignSystem.Colors.primary
                    )
                }
                .padding(.horizontal)
                
                // Match Cards
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.matches.isEmpty {
                    VStack(spacing: DesignSystem.Layout.spacing) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.secondary)
                        
                        Text("No matches found")
                            .font(DesignSystem.Typography.title3)
                        
                        Text("Try adjusting your filters")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Layout.spacing) {
                            ForEach(viewModel.matches) { match in
                                MatchCard(match: match) { action in
                                    switch action {
                                    case .like:
                                        Task {
                                            await viewModel.like(match)
                                        }
                                    case .dislike:
                                        Task {
                                            await viewModel.dislike(match)
                                        }
                                    case .message:
                                        viewModel.startChat(with: match)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView(viewModel: viewModel)
        }
    }
}

struct MatchCard: View {
    let match: Match
    let onAction: (MatchAction) -> Void
    
    var body: some View {
        GlassCardView {
            VStack(spacing: DesignSystem.Layout.spacing) {
                // Profile Image
                if let image = match.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
                }
                
                // Profile Info
                VStack(alignment: .leading, spacing: DesignSystem.Layout.spacing / 2) {
                    HStack {
                        Text(match.name)
                            .font(DesignSystem.Typography.title3)
                        
                        Spacer()
                        
                        Text("\(match.age) years")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(match.location)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(match.parentingStyle)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.secondary)
                }
                
                // Action Buttons
                HStack(spacing: DesignSystem.Layout.spacing) {
                    Button(action: { onAction(.dislike) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: DesignSystem.Layout.iconSize, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(DesignSystem.Colors.error)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: { onAction(.message) }) {
                        Image(systemName: "message.fill")
                            .font(.system(size: DesignSystem.Layout.iconSize, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(DesignSystem.Colors.primary)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: { onAction(.like) }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: DesignSystem.Layout.iconSize, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(DesignSystem.Colors.success)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}

enum MatchAction {
    case like
    case dislike
    case message
}

#Preview {
    MatchingView()
} 