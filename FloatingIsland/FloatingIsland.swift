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
    
    var body: some View {
        ZStack {
            if isExpanded {
                ExpandedView(mediaController: mediaController)
                    .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            } else {
                MinimizedView(mediaController: mediaController)
                    .padding(.vertical, 16) // Only add vertical padding in minimized state
            }
            
            if isExpanded {
                PinButton(isPinned: $isPinned)
            }
        }
        .padding(.top, isExpanded ? 60 : 0)
        .frame(
            width: isExpanded ? 300 : 340,
            height: isExpanded ? 160 : 39
        )
        .background(Color.black.opacity(0.5))
        .clipShape(Rectangle())
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
                ArtworkView(artwork: media.artwork, size: 40)
                    .padding(.leading, 16) // Add padding to move from edge
                Spacer() // Push artwork to the left
            }
        }
        .frame(maxWidth: .infinity) // Ensure HStack fills available width
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
                .padding(8)
            }
        }
    }
}
