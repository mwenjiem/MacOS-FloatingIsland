//
//  ArtworkView.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 11/1/24.
//
import SwiftUI

// Artwork view component
struct ArtworkView: View {
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
