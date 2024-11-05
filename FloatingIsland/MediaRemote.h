#import <Foundation/Foundation.h>

// Notification names
extern NSString * const kMRMediaRemoteNowPlayingInfoDidChangeNotification;
extern NSString * const kMRMediaRemoteNowPlayingPlaybackStateDidChangeNotification;

// Info dictionary keys
extern NSString * const kMRMediaRemoteNowPlayingApplicationIsPlayingKey;
extern NSString * const kMRMediaRemoteNowPlayingApplicationBundleIdentifierKey;
extern NSString * const kMRMediaRemoteNowPlayingTrackTitleKey;
extern NSString * const kMRMediaRemoteNowPlayingArtistNameKey;

// Block type definitions
typedef void (^MRMediaRemoteGetNowPlayingInfoCompletion)(NSDictionary * _Nullable info);
typedef void (^MRMediaRemoteGetNowPlayingApplicationIsPlayingCompletion)(BOOL isPlaying);

// Function declarations
void MRMediaRemoteRegisterForNowPlayingNotifications(dispatch_queue_t queue);
void MRMediaRemoteUnregisterForNowPlayingNotifications(void);
void MRMediaRemoteGetNowPlayingInfo(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingInfoCompletion completion);
void MRMediaRemoteGetNowPlayingApplicationIsPlaying(dispatch_queue_t queue, MRMediaRemoteGetNowPlayingApplicationIsPlayingCompletion completion);
void MRMediaRemoteSendCommand(unsigned int command, NSDictionary * _Nullable options);

// Command types
enum {
    kMRPlay = 0,
    kMRPause = 1,
    kMRTogglePlayPause = 2,
    kMRStop = 3,
    kMRNextTrack = 4,
    kMRPreviousTrack = 5,
    kMRToggleShuffle = 6,
    kMRToggleRepeat = 7,
    kMRStartForwardSeek = 8,
    kMREndForwardSeek = 9,
    kMRStartBackwardSeek = 10,
    kMREndBackwardSeek = 11,
    kMRGoBackFifteenSeconds = 12,
    kMRSkipFifteenSeconds = 13
}; 