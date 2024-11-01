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
    @StateObject private var mediaController = MediaController()
    @State private var showingSettings = false

    // Calculate minimized width based on media state
    private var minimizedWidth: CGFloat {
        if mediaController.title != nil {
            return 340 // Width when media is playing
        } else {
            return 100 // Smaller width when no media
        }
    }
    
    private var expandedWidth: CGFloat {
        return PlayerControlTile.getWidth() + CalendarTile.getWidth()
    }
    
    private var expandedHeight: CGFloat {
        return max(PlayerControlTile.getMinHeight(), CalendarTile.getMinHeight()) + 32
    }
    
    var body: some View {
        ZStack {
            if isExpanded {
                ExpandedView(mediaController: mediaController, height: expandedHeight, isPinned: $isPinned, isExpanded: $isExpanded)
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 16))
            } else {
                MinimizedView(mediaController: mediaController)
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
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }
    }
}

// Expanded view with all controls
private struct ExpandedView: View {
    @ObservedObject var mediaController: MediaController
    var height: CGFloat
    @Binding var isPinned: Bool
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.gray)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 0) {
                CalendarTile()
                PlayerControlTile(mediaController: mediaController, height: height)
            }.padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
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
        }
    }
}

// Minimized view with just artwork
private struct MinimizedView: View {
    @ObservedObject var mediaController: MediaController
    
    var body: some View {
        HStack {
            if let _ = mediaController.title {
                ArtworkView(artwork: mediaController.artwork, size: 30)
                    .padding(.leading, 16)
                Spacer()
                RotatingDisc(isPlaying: mediaController.isPlaying)
                    .padding(.trailing, 16)
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
        
        return path
    }
}

// Add this new component for the rotating disc
private struct RotatingDisc: View {
    let isPlaying: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        Image(systemName: "record.circle")
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
            isExpanded: .constant(true)
        )
        .frame(width: 600, height: 300)
        .previewDisplayName("Expanded")
        
        // Preview for minimized state
        FloatingIsland(
            isPinned: .constant(false),
            isExpanded: .constant(false)
        )
        .frame(width: 340, height: 38)
        .previewDisplayName("Minimized")
    }
}

// Preview helper for ExpandedView
struct ExpandedView_Previews: PreviewProvider {
    static var previews: some View {
        ExpandedView(
            mediaController: MediaController(),
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
