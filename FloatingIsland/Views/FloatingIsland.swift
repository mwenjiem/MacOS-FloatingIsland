//
//  FloatingIsland.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 10/31/24.
//

import SwiftUI

struct FloatingIsland: View {
    @Binding var isPinned: Bool
    @Binding var isExpanded: Bool
    @StateObject var mediaViewModel: MediaViewModel
    @StateObject var calendarViewModel: CalendarViewModel
    @State private var showingSettings = false
    @State private var animationWidth: CGFloat = 1.0
    @State private var animationHeight: CGFloat = 1.0
    
    // Calculate minimized width based on media state
    private var minimizedWidth: CGFloat {
        if mediaViewModel.title != nil {
            return 340 // Width when media is playing
        } else {
            return 100 // Smaller width when no media
        }
    }
    
    private var hasCalendarEvents: Bool {
        return calendarViewModel.events.count > 0
    }
    
    private var expandedWidth: CGFloat {
        var expandedWidth = PlayerControlTile.getWidth()
        if hasCalendarEvents {
            expandedWidth += CalendarTile.getWidth()
        }
        return expandedWidth
    }
    
    private var expandedHeight: CGFloat {
        var expandedHeight = PlayerControlTile.getMinHeight()
        if hasCalendarEvents {
            expandedHeight = max(expandedHeight, CalendarTile.getMinHeight())
        }
        
        return expandedHeight + 32
    }
    
    var body: some View {
        Group {
            ZStack {
                if isExpanded {
                    ExpandedView(mediaViewModel: mediaViewModel, calendarViewModel: calendarViewModel, height: expandedHeight, isPinned: $isPinned, isExpanded: $isExpanded)
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 16))
                } else {
                    MinimizedView(mediaViewModel: mediaViewModel)
                        .padding(.vertical, 16)
                }
            }
            .padding(.top, isExpanded ? 20 : 0)
            .frame(
                width: isExpanded ? expandedWidth : minimizedWidth,
                height: isExpanded ? expandedHeight : 38
            )
            .background(Color.black.opacity(1.0))
            .clipShape(CustomRoundedShape())
            .onTapGesture {
                let requireClickToExpand = UserDefaults.standard.bool(forKey: "requireClickToExpand")
                if requireClickToExpand && !isExpanded {
                    withAnimation(.spring()) {
                        isExpanded = true
                    }
                }
            }
        }
        .scaleEffect(x: animationWidth, y: animationHeight)
        .onChange(of: isExpanded) { newValue in
            // Notify expansion state change
            NotificationCenter.default.post(
                name: NSNotification.Name("ExpansionStateChanged"),
                object: newValue
            )
            
            if newValue {
                // Expanding animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animationWidth = 1.20
                    animationHeight = 1.08
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        animationWidth = 1.0
                        animationHeight = 1.02
                    }
                }
            } else {
                // Collapsing animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    animationWidth = 0.90
                    animationHeight = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        animationWidth = 1.0
                        animationHeight = 1.02
                    }
                }
            }
        }
    }
}

// Expanded view with all controls
private struct ExpandedView: View {
    @ObservedObject var mediaViewModel: MediaViewModel
    @ObservedObject var calendarViewModel: CalendarViewModel
    var height: CGFloat
    @Binding var isPinned: Bool
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack {
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
            }
            .padding(.trailing, 16)
            
            HStack(spacing: 0) {
                if calendarViewModel.events.count > 0 {
                    CalendarTile(calendarViewModel: calendarViewModel)
                }
                PlayerControlTile(mediaViewModel: mediaViewModel, height: height)
            }
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
        }
    }
}

// Minimized view with just artwork
private struct MinimizedView: View {
    @ObservedObject var mediaViewModel: MediaViewModel
    
    var body: some View {
        HStack {
            if let _ = mediaViewModel.title {
                ArtworkView(artwork: mediaViewModel.artwork, size: 30)
                    .padding(.leading, 24)
                Spacer()
                RotatingDisc(isPlaying: mediaViewModel.isPlaying)
                    .padding(.trailing, 24)
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

// Add this custom shape
struct CustomRoundedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius: CGFloat = 16
        
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
        
        return path
    }
}

// Add this new component for the rotating disc
private struct RotatingDisc: View {
    let isPlaying: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "opticaldisc")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundColor(.white)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isPlaying {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
            .onChange(of: isPlaying) { newValue in
                if newValue {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    withAnimation(.none) {
                        // Keep current rotation but stop animating
                        rotation = rotation.truncatingRemainder(dividingBy: 360)
                    }
                }
            }
    }
}

#if DEBUG
struct FloatingIsland_Previews: PreviewProvider {
    static var previews: some View {
        // Preview for expanded state
        FloatingIsland(
            isPinned: .constant(false),
            isExpanded: .constant(true),
            mediaViewModel: MediaViewModel(),
            calendarViewModel: CalendarViewModel()
        )
        .frame(width: 600, height: 300)
        .previewDisplayName("Expanded")
        
        // Preview for minimized state
        FloatingIsland(
            isPinned: .constant(false),
            isExpanded: .constant(false),
            mediaViewModel: MediaViewModel(),
            calendarViewModel: CalendarViewModel()
        )
        .frame(width: 340, height: 38)
        .previewDisplayName("Minimized")
    }
}

// Preview helper for ExpandedView
struct ExpandedView_Previews: PreviewProvider {
    static var previews: some View {
        ExpandedView(
            mediaViewModel: MediaViewModel(),
            calendarViewModel: CalendarViewModel(),
            height: 160,
            isPinned: .constant(false),
            isExpanded: .constant(true)
        )
        .frame(width: 600)
        .background(Color.black)
        .previewDisplayName("Expanded View")
    }
}
#endif
