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
    
    var body: some View {
        ZStack {
            // Main content
            HStack(spacing: 16) {
                if let media = mediaController.currentMedia {
                    // Album Artwork or Music Icon
                    if let artwork = media.artwork {
                        Image(nsImage: artwork)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "music.note")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60) // Match artwork frame size
                    }
                    
                    // Media Info and Controls Container
                    VStack(alignment: .center, spacing: 4) {
                        // Title and Artist
                        VStack(alignment: .center, spacing: 4) {
                            Text(media.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let artist = media.artist {
                                Text(artist)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Media Controls
                        HStack(alignment: .center, spacing: 20) {
                            Button(action: { mediaController.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { mediaController.togglePlayPause() }) {
                                Image(systemName: media.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { mediaController.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                } else {
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
            
            // Pin button in bottom right corner
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
        .padding(.top, 80)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 300, height: 160)
        .background(Color.black.opacity(1.0))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: isPinned) { newValue in
            print("Pin state changed to: \(newValue)")
        }
    }
}
