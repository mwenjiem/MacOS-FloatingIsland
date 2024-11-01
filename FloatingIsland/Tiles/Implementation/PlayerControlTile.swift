import SwiftUI

struct PlayerControlTile: View, TileProtocol {
    @ObservedObject var mediaController: MediaController
    var height: CGFloat
    
    var body: some View {
        HStack(spacing: 16) {
            if let title = mediaController.title {
                ArtworkView(artwork: mediaController.artwork, size: 60)
                MediaControlsView(mediaController: mediaController)
            } else {
                NoMediaView()
            }
        }
    }
    
    static func getWidth() -> CGFloat {
        return 360
    }
    
    static func getMinHeight() -> CGFloat {
        return 160
    }

    // Media controls and info view
    private struct MediaControlsView: View {
        @ObservedObject var mediaController: MediaController
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                MediaInfoView(title: mediaController.title!, artist: mediaController.artist)
                
                // Add progress bar
                ProgressBar(currentPosition: mediaController.currentPosition, duration: mediaController.duration)
                    .padding(.vertical, 4)
                
                PlaybackControlsView(
                    isPlaying: mediaController.isPlaying,
                    mediaController: mediaController
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
        @ObservedObject var mediaController: MediaController
        
        var body: some View {
            HStack(alignment: .center, spacing: 20) {
                MediaControlButton(
                    systemName: "backward.fill",
                    action: mediaController.previousTrack
                )
                
                MediaControlButton(
                    systemName: isPlaying ? "pause.fill" : "play.fill",
                    action: mediaController.togglePlayPause
                )
                
                MediaControlButton(
                    systemName: "forward.fill",
                    action: mediaController.nextTrack
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
