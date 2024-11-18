import SwiftUI

struct PlayerControlTile: View, TileProtocol {
    @ObservedObject var mediaViewModel: MediaViewModel
    var height: CGFloat
    
    var body: some View {
        HStack(spacing: 16) {
            if let _ = mediaViewModel.title {
                ArtworkView(artwork: mediaViewModel.artwork, size: 60)
                MediaControlsView(mediaViewModel: mediaViewModel)
            } else {
                NoMediaView()
            }
        }.padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
    }
    
    static func getWidth() -> CGFloat {
        return 360
    }
    
    static func getMinHeight() -> CGFloat {
        return 160
    }

    // Media controls and info view
    private struct MediaControlsView: View {
        @ObservedObject var mediaViewModel: MediaViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                MediaInfoView(title: mediaViewModel.title!, artist: mediaViewModel.artist)
                
                // Add progress bar
                ProgressBar(currentPosition: mediaViewModel.currentPosition, duration: mediaViewModel.duration)
                    .padding(.vertical, 4)
                
                PlaybackControlsView(
                    isPlaying: mediaViewModel.isPlaying,
                    mediaViewModel: mediaViewModel
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    // Media info (title and artist) view
    private struct MediaInfoView: View {
        let title: String
        let artist: String?
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let artist = artist {
                    Text(artist)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // Playback controls view
    private struct PlaybackControlsView: View {
        let isPlaying: Bool
        @ObservedObject var mediaViewModel: MediaViewModel
        
        var body: some View {
            HStack(alignment: .center, spacing: 20) {
                MediaControlButton(
                    systemName: "backward.fill",
                    action: mediaViewModel.previousTrack
                )
                
                MediaControlButton(
                    systemName: isPlaying ? "pause.fill" : "play.fill",
                    action: mediaViewModel.togglePlayPause
                )
                
                MediaControlButton(
                    systemName: "forward.fill",
                    action: mediaViewModel.nextTrack
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    // Generic media control button
    private struct MediaControlButton: View {
        let systemName: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Image(systemName: systemName)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
    }

    // No media playing view
    private struct NoMediaView: View {
        var body: some View {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text("No media playing")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Add new ProgressBar component
private struct ProgressBar: View {
    let currentPosition: TimeInterval
    let duration: TimeInterval
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return currentPosition / duration
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 2)
                    
                    // Progress
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * progress, height: 2)
                }
            }
            .frame(height: 2)
            
            // Time labels
            HStack {
                Text(formatTime(currentPosition))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
    }
}

#if DEBUG
struct PlayerControlTile_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with no media playing
            PlayerControlTile(
                mediaViewModel: MockMediaViewModel(hasMedia: false),
                height: PlayerControlTile.getMinHeight()
            )
            .previewDisplayName("No Media")
            
            // Preview with media playing
            PlayerControlTile(
                mediaViewModel: MockMediaViewModel(
                    hasMedia: true,
                    isPlaying: true,
                    title: "Never Gonna Give You Up",
                    artist: "Rick Astley",
                    currentPosition: 135,
                    duration: 213
                ),
                height: PlayerControlTile.getMinHeight()
            )
            .previewDisplayName("Playing")
            
            // Preview with media paused
            PlayerControlTile(
                mediaViewModel: MockMediaViewModel(
                    hasMedia: true,
                    isPlaying: false,
                    title: "Bohemian Rhapsody",
                    artist: "Queen",
                    currentPosition: 45,
                    duration: 354
                ),
                height: PlayerControlTile.getMinHeight()
            )
            .previewDisplayName("Paused")
        }
        .frame(width: PlayerControlTile.getWidth())
        .background(Color.black)
    }
}

// Mock MediaController for previews
private class MockMediaViewModel: MediaViewModel {
    init(
        hasMedia: Bool = false,
        isPlaying: Bool = false,
        title: String? = nil,
        artist: String? = nil,
        currentPosition: TimeInterval = 0,
        duration: TimeInterval = 0
    ) {
        super.init()
        self.title = hasMedia ? title : nil
        self.artist = artist
        self.isPlaying = isPlaying
        self.currentPosition = currentPosition
        self.duration = duration
    }
    
    override func togglePlayPause() {
        // No-op for preview
    }
    
    override func nextTrack() {
        // No-op for preview
    }
    
    override func previousTrack() {
        // No-op for preview
    }
}
#endif
