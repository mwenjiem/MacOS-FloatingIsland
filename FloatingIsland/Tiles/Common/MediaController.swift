//
//  MediaController.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 11/1/24.
//
import SwiftUI

// Command constants
private let kMRPlay: UInt32 = 0
private let kMRPause: UInt32 = 1
private let kMRTogglePlayPause: UInt32 = 2
private let kMRNextTrack: UInt32 = 4
private let kMRPreviousTrack: UInt32 = 5

class MediaController: ObservableObject {
    @Published var artwork: NSImage?
    @Published var title: String?
    @Published var artist: String?
    @Published var isPlaying: Bool = false
    @Published var duration: TimeInterval = .zero
    @Published var currentPosition: TimeInterval = .zero
    var timer: Timer?
    
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
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("kMRMediaRemotePlayerDidExitNotification"),
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
                    var artwork: NSImage?
                    if let artworkData = info?["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
                        artwork = NSImage(data: artworkData)
                    }
                    if self?.title != title { // avoid glitch caused by frequent updates
                        self?.artwork = artwork
                        self?.title = title
                        self?.artist = info?["kMRMediaRemoteNowPlayingInfoArtist"] as? String
                        self?.isPlaying = (info?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0) > 0
                        self?.duration = info?["kMRMediaRemoteNowPlayingInfoDuration"] as? TimeInterval ?? 0
                        self?.currentPosition = info?["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? TimeInterval ?? 0
                    } else {
                        if self?.artwork == nil, artwork != nil {
                            self?.artwork = artwork // backfill artwork if necessary
                        }
                        self?.isPlaying = (info?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0) > 0
                        self?.currentPosition = info?["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? TimeInterval ?? 0
                    }
                    // Start a timer to update currentPosition every second
                    self?.timer?.invalidate()
                    self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                        guard let self = self else {
                            timer.invalidate()
                            return
                        }
                        if self.isPlaying {
                            self.currentPosition += 1
                        } else {
                            timer.invalidate()
                        }
                    }
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
