//
//  DeleteButton.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/17/21.
//

import SwiftUI

struct DeleteButton: View {
    @State private var presenting_alert: Bool = false
    let action: () -> Void
    var body: some View {
        Button {
            presenting_alert = true
        }
        label: {
            VStack {
                Image(systemName: "minus.circle")
                    .resizable()
                    .foregroundColor(.white)
                    .scaledToFit()
                    .font(.system(.body).weight(.ultraLight))
                    .clipShape(Circle())
                    .shadow(radius: 15)
                    .frame(width: 50, height: 50, alignment: .center)
                
                Text("delete")
                    .font(.system(size: 18, weight: .thin, design: .default))
                    .foregroundColor(.white)
            }
        }
        .alert(isPresented: $presenting_alert) {
            Alert(
                title: Text("Are you certain in your wish to delete?"),
                message: Text("This action cannot be undone"),
                primaryButton: .cancel(),
                secondaryButton: .destructive(Text("Delete"), action: action))
        }
    }
}

struct DeleteButton_Previews: PreviewProvider {
    static var previews: some View {
        DeleteButton(action: {})
            .previewLayout(.fixed(width: 100, height: 100))
            .frame(width: 100, height: 100, alignment: .center)
            .background(Color.gray)
            .previewDisplayName("Delete Button")
    }
}
