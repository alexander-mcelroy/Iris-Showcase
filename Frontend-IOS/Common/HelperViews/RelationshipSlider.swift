//
//  RelationshipSlider.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/6/21.
//

import SwiftUI


struct RelationshipSlider: View {
    @Binding var relationship: Entity.Relationship
    @State private var dragging_relative_offset: CGFloat?
    
    private var relative_offset: CGFloat {
        dragging_relative_offset ?? RESTING_RELATIVE_OFFSET(relationship)
    }
    private var layer_colors: (Color, Color, Color, Color) {
        LAYERS_COLORS(relationship)
    }

    var body: some View {
        VStack(alignment: .center) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundColor(Color.white)
                    .colorMultiply(layer_colors.0)
                    .animation(.linear)
                    .frame(width: LENGTH, height: 3, alignment: .center)
                
                Circle()
                    .foregroundColor(Color.white)
                    .colorMultiply(layer_colors.0)
                    .frame(width: DIAMETER, height: DIAMETER, alignment: .center)
                    .overlay(
                        Circle()
                            .foregroundColor(Color.white)
                            .colorMultiply(layer_colors.1)
                            .frame(width: 0.75 * DIAMETER, height: DIAMETER, alignment: .center)
                    )
                    .overlay(
                        Circle()
                            .foregroundColor(Color.white)
                            .colorMultiply(layer_colors.2)
                            .frame(width: 0.5 * DIAMETER, height: DIAMETER, alignment: .center)
                    )
                    .overlay(
                        Circle()
                            .foregroundColor(Color.white)
                            .colorMultiply(layer_colors.3)
                            .frame(width: 0.25 * DIAMETER, height: DIAMETER, alignment: .center)
                    )
                    .offset(x: relative_offset * (LENGTH - DIAMETER))
                    .animation(.easeIn)
                    .gesture(
                        DragGesture()
                            .onChanged { (val) in
                                let rel_x = (val.startLocation.x + val.translation.width - (DIAMETER / 2)) / (LENGTH - DIAMETER)
                                relationship = Entity.Relationship.ofRelativeLocation(rel_x)
                                dragging_relative_offset = rel_x
                            }
                            .onEnded { (val) in
                                dragging_relative_offset = nil
                            }
                    )
            }
            
            Text(relationship.rawValue)
                .font(.system(size: 20, weight: .thin, design: .default))
                .foregroundColor(.white)
                .animation(.none)
        }
    }
}

extension Entity.Relationship {
    fileprivate static func ofRelativeLocation(_ x: CGFloat) -> Entity.Relationship {
        let admin = abs(RESTING_RELATIVE_OFFSET(.Admin) - x)
        let peer = abs(RESTING_RELATIVE_OFFSET(.Peer) - x)
        let aquainted = abs(RESTING_RELATIVE_OFFSET(.Aquainted) - x)
        let distant = abs(RESTING_RELATIVE_OFFSET(.Distant) - x)
        switch min(admin, peer, aquainted, distant) {
        case admin:
            return .Admin
        case peer:
            return .Peer
        case aquainted:
            return .Aquainted
        case distant:
            return .Distant
        default:
            preconditionFailure()
        }
    }
}

struct RelationshipSlider_Previews: PreviewProvider {
    static var previews: some View {
        PREVIEW_CONTAINER()
            .padding()
            .previewLayout(.fixed(width: 390, height: 240))
            .frame(width: 390, height: 240, alignment: .center)
            .background(Color.gray)
            .previewDisplayName("Relationship Slider")
    }
}




//MARK: Constants
fileprivate struct PREVIEW_CONTAINER: View {
    @State private var relationship: Entity.Relationship = .Peer
    var body: some View {
        RelationshipSlider(relationship: $relationship)
    }
}
fileprivate let DIAMETER: CGFloat = 60
fileprivate let LENGTH: CGFloat = 300
fileprivate let BUTTON_LENGTH: CGFloat = 60
fileprivate func RESTING_RELATIVE_OFFSET(_ RELATIONSHIP: Entity.Relationship) -> CGFloat {
    switch RELATIONSHIP {
    case .Admin:
        return 1
    case .Peer:
        return 0.75
    case .Aquainted:
        return 0.25
    case .Distant:
        return 0
    }
}

fileprivate func LAYERS_COLORS(_ RELATIONSHIP: Entity.Relationship) -> (Color, Color, Color, Color) {
    switch RELATIONSHIP {
    case .Admin:
        return ADMIN_COLORS
    case .Peer:
        return PEER_COLORS
    case .Aquainted:
        return AQUAINTED_COLORS
    case .Distant:
        return DISTANT_COLORS
    }
}

fileprivate let ADMIN_COLORS = (
    Color(red: 128/255, green: 27/255, blue: 250/255),
    Color(red: 68/255, green: 8/255, blue: 140/255),
    Color(red: 128/255, green: 27/255, blue: 250/255),
    Color(red: 68/255, green: 8/255, blue: 140/255)
)
    
fileprivate let PEER_COLORS = (
    Color(red: 255/255, green: 189/255, blue: 89/255),
    Color(red: 255/255, green: 145/255, blue: 77/255),
    Color(red: 228/255, green: 105/255, blue: 29/255),
    Color(red: 171/255, green: 81/255, blue: 26/255)
)
    
fileprivate let AQUAINTED_COLORS = (
    Color(red: 217/255, green: 217/255, blue: 217/255),
    Color(red: 255/255, green: 189/255, blue: 89/255),
    Color(red: 255/255, green: 145/255, blue: 77/255),
    Color(red: 228/255, green: 105/255, blue: 29/255)
)
    
fileprivate let DISTANT_COLORS = (
    Color(red: 217/255, green: 217/255, blue: 217/255),
    Color(red: 166/255, green: 166/255, blue: 166/255),
    Color(red: 115/255, green: 115/255, blue: 115/255),
    Color(red: 84/255, green: 84/255, blue: 84/255)
)
