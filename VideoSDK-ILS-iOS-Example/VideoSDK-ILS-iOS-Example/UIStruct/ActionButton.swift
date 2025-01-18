//
//  ActionButton.swift
//  VideoSDK-ILS-iOS-Example
//
//  Created by Deep Bhupatkar on 18/01/25.
//


import SwiftUI
struct ActionButton: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 2)
        )
    }
}




struct ActionButtonn: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.indigo)
        )
        .foregroundColor(.white)
    }
}

