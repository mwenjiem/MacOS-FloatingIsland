//
//  FloatingIsland.swift
//  FloatingIsland
//
//  Created by Wenjie Ma on 10/31/24.
//

import SwiftUI

struct FloatingIsland: View {
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                Text("Dynamic Island")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            .frame(height: 28)
            
            // Add some test content to see sizing
            Text("Additional content")
                .foregroundColor(.white)
                .padding()
        }
        .frame(minWidth: 400, minHeight: 100)
        .background(Color.black.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
