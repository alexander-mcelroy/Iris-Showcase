//
//  LongTextInput.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/14/21.
//

import SwiftUI

struct LongTextInput: View {
    @State private var presenting_sheet: Bool = false
    @Binding var currentText: String
    let originalText: String
    let minCharacters: Int
    let maxCharacters: Int
    
    var body: some View {
        Button {
            presenting_sheet = true
        }
        label: {
            Description(text: currentText)
        }
        .sheet(isPresented: $presenting_sheet) {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    Description(text: currentText)
                        .padding(.vertical)
                }

                TextField(placeholder, text: $currentText)
                    .padding()
                    .foregroundColor(unchanged ? Color.gray : Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(border_color, lineWidth: 2))
                    .background(currentText == "" || unchanged ? Color.white.opacity(0.2) : Color.clear)
                
                Spacer()
            }
            .padding()
            .background(
                Color(red: 23 / 255, green: 39 / 255, blue: 64 / 255)
                    .ignoresSafeArea())
        }
    }
}

extension LongTextInput {
    private var border_color: Color {
        unchanged || !valid_length ? Color.white : Color.orange
    }
    
    private var unchanged: Bool {
        currentText == originalText
    }
    
    private var placeholder: String {
        "Between \(minCharacters) and \(maxCharacters) characters"
    }
    
    private var valid_length: Bool {
        currentText.count > minCharacters &&
        currentText.count < maxCharacters
    }
}

struct LongTextInput_Previews: PreviewProvider {
    static var previews: some View {
        PREVIEW_CONTAINER()
            .padding()
            .previewLayout(.fixed(width: 390, height: 240))
            .frame(width: 390, height: 240, alignment: .center)
            .background(Color.gray)
            .previewDisplayName("LongTextInput")
    }
}

fileprivate struct PREVIEW_CONTAINER: View {
    @State var currentText: String = ""
    var body: some View {
        LongTextInput(
            currentText: $currentText,
            originalText: "Original",
            minCharacters: 10,
            maxCharacters: 1000
        )
    }
}
