//
//  FloatingIsland.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 10/31/24.
//

import SwiftUI

// Command constants
private let kMRPlay: UInt32 = 0
private let kMRPause: UInt32 = 1
private let kMRTogglePlayPause: UInt32 = 2
private let kMRNextTrack: UInt32 = 4
private let kMRPreviousTrack: UInt32 = 5

struct MediaInfo {
    let artwork: NSImage?
    let title: String
    let artist: String?
    let isPlaying: Bool
}

class MediaController: ObservableObject {
    @Published var currentMedia: MediaInfo?
    
    init() {
        setupMediaRemote()
    }
    
    private func setupMediaRemote() {
        let queue = DispatchQueue.main
        MRMediaRemoteRegisterForNowPlayingNotifications(queue)
        
        // Observe now playing info changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("kMRMediaRemoteNowPlayingInfoDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        
        // Initial update
        updateNowPlayingInfo()
    }
    
    private func updateNowPlayingInfo() {
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main) { [weak self] info in
            DispatchQueue.main.async {
                if let title = info?["kMRMediaRemoteNowPlayingInfoTitle"] as? String {
                    // Get artwork if available
                    var artwork: NSImage?
                    if let artworkData = info?["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                        artwork = NSImage(data: artworkData)
                    }
                    
                    self?.currentMedia = MediaInfo(
                        artwork: artwork,
                        title: title,
                        artist: info?["kMRMediaRemoteNowPlayingInfoArtist"] as? String,
                        isPlaying: (info?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0) > 0
                    )
                } else {
                    self?.currentMedia = nil
                }
            }
        }
    }
    
    func togglePlayPause() {
        MRMediaRemoteSendCommand(kMRTogglePlayPause, nil)
    }
    
    func nextTrack() {
        MRMediaRemoteSendCommand(kMRNextTrack, nil)
    }
    
    func previousTrack() {
        MRMediaRemoteSendCommand(kMRPreviousTrack, nil)
    }
}

struct FloatingIsland: View {
    @StateObject private var mediaController = MediaController()
    @Binding var isPinned: Bool
    @Binding var isExpanded: Bool
    
    // Calculate minimized width based on media state
    private var minimizedWidth: CGFloat {
        if mediaController.currentMedia != nil {
            return 340 // Width when media is playing
        } else {
            return 100 // Smaller width when no media
        }
    }
    
    var body: some View {
        ZStack {
            if isExpanded {
                ExpandedView(mediaController: mediaController)
                    .padding(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 16))
            } else {
                MinimizedView(mediaController: mediaController)
                    .padding(.vertical, 16)
            }
            
            if isExpanded {
                PinButton(isPinned: $isPinned)
            }
        }
        .padding(.top, isExpanded ? 20 : 0)
        .frame(
            width: isExpanded ? 300 : minimizedWidth,
            height: isExpanded ? 120 : 38
        )
        .background(Color.black.opacity(1.0))
        .clipShape(CustomRoundedShape())
        .onTapGesture {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}

// Expanded view with all controls
private struct ExpandedView: View {
    @ObservedObject var mediaController: MediaController
    
    var body: some View {
        HStack(spacing: 16) {
            if let media = mediaController.currentMedia {
                ArtworkView(artwork: media.artwork, size: 60)
                MediaControlsView(media: media, mediaController: mediaController)
            } else {
                NoMediaView()
            }
        }
    }
}

// Minimized view with just artwork
private struct MinimizedView: View {
    @ObservedObject var mediaController: MediaController
    
    var body: some View {
        HStack {
            if let media = mediaController.currentMedia {
                ArtworkView(artwork: media.artwork, size: 30)
                    .padding(.leading, 16)
                Spacer()
            } else {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Artwork view component
private struct ArtworkView: View {
    let artwork: NSImage?
    let size: CGFloat
    
    var body: some View {
        if let artwork = artwork {
            Image(nsImage: artwork)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .cornerRadius(8)
        } else {
            Image(systemName: "music.note")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.75, height: size * 0.75)
                .foregroundColor(.gray)
                .frame(width: size, height: size)
        }
    }
}

// Media controls and info view
private struct MediaControlsView: View {
    let media: MediaInfo
    @ObservedObject var mediaController: MediaController
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            MediaInfoView(title: media.title, artist: media.artist)
            PlaybackControlsView(
                isPlaying: media.isPlaying,
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

// Pin button view
private struct PinButton: View {
    @Binding var isPinned: Bool
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                        isPinned.toggle()
                    }
                }) {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                        .foregroundColor(isPinned ? .white : .gray)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
                .padding(16)
            }
        }
    }
}

// Add this custom shape
struct CustomRoundedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 8
        
        // Top left - inward curve
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            control: CGPoint(x: rect.minX + cornerRadius, y: rect.minY)
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY-cornerRadius))
        
        // Bottom left - regular corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + 2*cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY)
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius*2, y: rect.maxY))
        
        // Bottom right - regular corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY)
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius))
        
        // Top right - inward curve
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY)
        )
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        
        
        
        
        
        
        
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}
