//
//  SettingsButton.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/20/21.
//

import SwiftUI

struct SettingsButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action, label: {
            Image(systemName: systemName)
                .resizable()
                .foregroundColor(.orange)
                .scaledToFit()
                .font(.system(.body).weight(.ultraLight))
        })
    }
}

struct SettingsButton_Previews: PreviewProvider {
    static var previews: some View {
        SettingsButton(systemName: "ellipsis", action: {})
            .previewLayout(.fixed(width: 100, height: 100))
            .frame(width: 100, height: 100, alignment: .center)
            .background(Color.gray)
            .previewDisplayName("Settings")
    }
}
