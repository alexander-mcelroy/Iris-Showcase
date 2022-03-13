//
//  ConfirmationButton.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/16/21.
//

import SwiftUI

struct ConfirmationButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action, label: {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .foregroundColor(.orange)
                .scaledToFit()
                .font(.system(.body).weight(.ultraLight))
                .background(Color.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                .shadow(radius: 15)
                .frame(width: 80, height: 80, alignment: .center)
        })
    }
}

struct ConfirmationButton_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationButton(action: {})
            .previewLayout(.fixed(width: 100, height: 100))
            .frame(width: 100, height: 100, alignment: .center)
            .background(Color.gray)
            .previewDisplayName("Confirmation Button")
    }
}
