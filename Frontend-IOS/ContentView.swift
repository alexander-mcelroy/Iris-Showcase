//
//  ContentView.swift
//  Shared
//
//  Created by Rhizome Networking LLC on 8/15/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainIOS()
            .environmentObject(MainIOS.Xylem())
            .environmentObject(Staging.global)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
