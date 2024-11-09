//
//  PulsatingCircleView.swift
//  TheWave
//
//  Created by Tika on 09/11/2024.
//
import SwiftUI

struct PulsatingCircleView: View {
    @State private var isAnimating = false
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.5), lineWidth: 2)
                .scaleEffect(isAnimating ? 2 : 1)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Circle()
                .stroke(color.opacity(0.7), lineWidth: 2)
                .scaleEffect(isAnimating ? 1.5 : 1)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                    .delay(0.5),
                    value: isAnimating
                )
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .frame(width: 20, height: 20)
        .onAppear {
            isAnimating = true
        }
    }
}
