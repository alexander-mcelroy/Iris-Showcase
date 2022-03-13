//
//  Header.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/4/21.
//

import SwiftUI
import Combine
import CoreLocation
import Amplify
import MapKit


//MARK: Leaf
struct Header: View {
    @ObservedObject var xylem: Xylem
    let phloem: HeaderPhloem?
    var body: some View {
        ZStack {
            NavigationLayer()
                .opacity(xylem.centeredEntity != nil ? 1 : 0)
                .ignoresSafeArea()
            
            SettingsButtonLayer(phloem: phloem)
            
            SearchLayer()
                .opacity(xylem.centeredEntity?.counterRelationship == .Distant ? 0 : 1)
            
            MediaLayer()
                .ignoresSafeArea()
                .opacity(!xylem.presentingMap ? 1 : 0)
            
            Canvas(xylem: xylem.canvasXylem, phloem: self)
                .opacity(!xylem.presentingMap ? 1 : 0)
            
            DetailLayer()
                .opacity(xylem.dragging ? 1 : 0)
                    
            ChainLayer(phloem: phloem)
                .ignoresSafeArea(.keyboard, edges: .bottom)

        }
        .opacity(xylem.isBlind ? 0 : 1)
        .animation(.none)
        .environmentObject(xylem)
    }
}

struct Header_Previews: PreviewProvider {
    static var previews: some View {
        Header(xylem: DEBUG_DATA().xylem, phloem: nil)
            .background(Color.gray)
            .previewDisplayName("Header")
    }
}

fileprivate struct MediaLayer: View {
    @EnvironmentObject var xylem: Header.Xylem
    var body: some View {
        ZStack {
            BACKDROP_COLOR
                .animation(.easeIn)
                
            if let entity = xylem.centeredEntity {
                EntityBackdrop(entity: entity)
                    .transition(.opacity)
            }
        }
        .animation(.linear(duration: 1).delay(1))
    }
}

fileprivate struct DetailLayer: View {
    @EnvironmentObject var xylem: Header.Xylem
    var body: some View {
        ZStack {
            Color
                .black
                .opacity(xylem.centeredEntity == nil ? 0 : 0.85)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let ce = xylem.centeredEntity {
                    
                    Name(text: ce.name)
                        .padding(.top, xylem.presentingMap ? 60 : (140 + 25 + 15))
                        .padding(.horizontal)
                    
                    RelationshipSlider(relationship: .constant(ce.relationship))
                        .padding()
                        .disabled(true)
                    
                    if !ce.description.isEmpty {
                        Description(text: ce.description)
                            .padding(.horizontal)
                            .padding(.top)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

fileprivate struct NavigationLayer: View {
    @EnvironmentObject var xylem: Header.Xylem
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.contentShape(Rectangle())
                .frame(height: 180)
                .onTapGesture {
                    if xylem.centeredEntity?.counterRelationship == .Distant {
                        withAnimation(.default) {
                            xylem.badAttempts += 1
                        }
                        xylem.presentingMap = true
                    } else {
                        xylem.presentingMap = false
                    }
                }
            
            Spacer()
            
            Color.clear.contentShape(Rectangle())
                .frame(height: 180)
                .onTapGesture {
                    xylem.presentingMap = true
                }
            
        }
    }
}

fileprivate struct ChainLayer: View {
    @EnvironmentObject var xylem: Header.Xylem
    @GestureState private var offset: CGSize = .zero
    let phloem: HeaderPhloem?
    
    private var presenting_entity: Entity? {
        presenting_entity_for_offset(offset)
    }
    var body: some View {
        ZStack {
            if xylem.centeredEntity != nil {
                VStack {
                    if xylem.presentingMap {
                        Spacer()
                    }
                    ZStack {
                        if let entity = presenting_entity {
                            EntityPortrait(entity: entity)
                        }
                    }
                    .contentShape(Circle())
                    .frame(width: 140, height: 140, alignment: .center)
                    .padding(.vertical, 25)
                    .animation(.none)
                    .modifier(Shake(animatableData: CGFloat(xylem.badAttempts)))
                    .offset(offset)
                    .gesture(drag_gesture, including: .gesture)

                    if !xylem.presentingMap {
                        Spacer()
                    }
                }
            }
        }.animation(.easeIn)
    }
    
    private var drag_gesture: some Gesture {
        DragGesture(minimumDistance: .zero)
            .onChanged { _ in
                xylem.dragging = true
            }
            .updating($offset) { (value, offset, _) in
                offset = value.translation
            }
            .onEnded { end in
                xylem.dragging = false
                guard let entity = xylem.centeredEntity else {
                    return
                }
                if let presenting_entity = presenting_entity_for_offset(end.translation) {
                    if presenting_entity.id != entity.id {
                        phloem?.didSelect(presenting_entity)
                    }
                } else {
                    //UPSTREAM
                    phloem?.didSelectGlobe()
                }
            }
    }
    
    private func presenting_entity_for_offset(_ offset: CGSize) -> Entity?{
        guard let path = xylem.path else {
            return nil
        }
        let dy = offset.height
        if
            offset.equalTo(.zero) ||
                (dy >= 0 && xylem.presentingMap) ||
                (dy <= 0 && !xylem.presentingMap)
        {
            return xylem.centeredEntity
        }
        else {
            let x = abs(dy / 400)
            let y = x * x
  
            let index = Int(abs((y * CGFloat(path.count))).rounded(.toNearestOrAwayFromZero))
            return xylem.path?.reversed()[safe: index]
        }
    }
}

fileprivate struct Name: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 35, weight: .thin, design: .default))
            .fontWeight(.thin)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
    }
}

fileprivate struct SearchLayer: View {
    @EnvironmentObject var xylem: Header.Xylem
    @EnvironmentObject var staging: Staging
    @State private var search_query: String = ""
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    xylem.searching.toggle()
                }
                label: {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .foregroundColor(.orange)
                        .scaledToFit()
                        .font(.system(.body).weight(.light))
                        .frame(width: 40)
                        .frame(width: 60, height: 60, alignment: .center)
                        .contentShape(Rectangle())
                        .animation(.none)
                }
                .padding(.trailing)
                
                if xylem.searching {
                    TextField("Search", text: $search_query, onEditingChanged: { _ in }) {
                        staging.fly(search_query)
                    }
                        .padding()
                        .foregroundColor(Color.white)
                        .background(Color.clear.background(BlurView()))
                        .clipShape(RoundedRectangle(cornerRadius: 10.0))
                        .overlay(RoundedRectangle(cornerRadius: 10.0).stroke(Color.orange, lineWidth: 2))
                        .transition(.move(edge: .trailing))
                        
                } else {
                    Spacer()
                }
            }
            .animation(.linear(duration: 0.15))
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

fileprivate struct SettingsButtonLayer: View, EntityFormPhloem, RelationshipFormPhloem {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var xylem: Header.Xylem
    let phloem: HeaderPhloem?
    @State private var presenting_action_sheet: Bool = false
    @State private var presenting_form: Bool = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                
                SettingsButton(systemName: "ellipsis") {
                    if xylem.hostedOnly {
                        presenting_action_sheet = true
                        
                    } else if xylem.exploring {
                        presenting_form = true
                    }
                }
                .frame(width: 40)
                .frame(width: 60, height: 60, alignment: .center)
                .contentShape(Rectangle())
                .padding(.trailing)
                .animation(.linear(duration: 0.1))
            }
            Spacer()
        }
        .actionSheet(isPresented: $presenting_action_sheet) {
            ActionSheet(
                title: Text("Options"),
                buttons: [
                    .default(Text("Change Iris")) {
                        phloem?.didExitHost()
                    },
                    
                    .default(Text("Privacy Policy")) {
                        openURL(PRIVACY_POLICY_URL)
                    },

                    .default(Text("Terms and Conditions")) {
                        openURL(TERMS_URL)
                    },
                    
                    .default(Text("End-User License Agreement")) {
                        openURL(EULA_URL)
                    },
                    
                    .destructive(Text("Sign Out")) {
                        xylem.attemptSignOut {
                            phloem?.didSignOut()
                        }
                    },

                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $presenting_form) {
            if xylem.centeredEntityIsHost {
                EntityForm(xylem: xylem.entityFormXylem, phloem: self)
                    .ignoresSafeArea()
            } else if xylem.exploring {
                RelationshipForm(xylem: xylem.relationshipFormXylem, phloem: self)
                    .ignoresSafeArea()
            } else {
                preconditionFailure("Cannot edit entity without centered entity")
            }
        }
    }
    
    func didUpdateHost(host: Entity) {
        phloem?.didSelect(host: host)
    }
    
    func didDeleteHost() {
        phloem?.didExitHost()
    }
    
    func didUpdateRelationship(of entity: Entity) {
        phloem?.didSelect(entity)
    }
}




//MARK: Xylem
extension Header {
    class Xylem: ObservableObject {
        @Published var position: Position = .Blind
        enum Position {
            case Blind
            case Hosted(host: Entity)
            case Explored(host: Entity, path: [Entity])
        }
        
        //LEAF
        @Published fileprivate var searching: Bool = false
        @Published fileprivate var dragging: Bool = false
        @Published fileprivate var presentingMap: Bool = true
        @Published fileprivate var badAttempts: Int = 0
        
        //XYLEM
        let canvasXylem: Canvas.Xylem = Canvas.Xylem()
        let entityFormXylem: EntityForm.Xylem = EntityForm.Xylem()
        let relationshipFormXylem: RelationshipForm.Xylem = RelationshipForm.Xylem()
        
        private var listener: AnyCancellable?
        private var sign_out_loader: AnyCancellable?
        
        init() {
            listener = $position.sink { new_position in
                switch new_position {
                case .Blind, .Hosted:
                    self.canvasXylem.position = .Blind
                    self.relationshipFormXylem.position = .Blind
                    //BEGIN EXCEPTION to the rule
                    self.searching = false
                    self.presentingMap = true
                    //END EXCEPTION
                case .Explored(host: let host, path: let path):
                    guard let new_centered_entity = path.last else {
                        preconditionFailure("Explored path can never be empty")
                    }
                    self.canvasXylem.position = .Centered(host: host, entity: new_centered_entity)
                    self.entityFormXylem.position = .Update(host: host)
                    self.relationshipFormXylem.position = .Update(entity: new_centered_entity, host: host)
                    //BEGIN EXCEPTION to the rule
                    self.searching = false
                    if new_centered_entity.counterRelationship == .Distant {
                        withAnimation(.default) {
                            self.presentingMap = true
                        }
                    }
                    //END EXCEPTION
                }
            }
        }
        
        fileprivate func attemptSignOut(onSuccess: @escaping () -> Void) {
            sign_out_loader = Pipeline.pump_SignOut().sink { signed_out in
                if signed_out {
                    onSuccess()
                } else {
                    Staging.global.alert(title: "Unable to Sign Out", "Please try again in a few moments")
                }
            }
        }
    }
}

extension Header.Xylem {
    var exploring: Bool {
        switch position {
        case .Explored:
            return true
        case .Blind, .Hosted:
            return false
        }
    }
    
    var hostedOnly: Bool {
        switch position {
        case .Hosted:
            return true
        case .Blind, .Explored:
            return false
        }
    }
    
    var centeredEntity: Entity? {
        switch position {
        case .Explored(host: _, path: let path):
            precondition(!path.isEmpty, "Entity path cannot be empty when in explored state")
            return path.last
        case .Blind, .Hosted(host: _):
            return nil
        }
    }
    
    var centeredEntityIsHost: Bool {
        switch position {
        case .Explored(host: let host, path: _):
            guard let centered_entity = centeredEntity else {
                preconditionFailure("No centered enity implies that path is empty despite Explore state")
            }
            return host.id == centered_entity.id
        case .Blind, .Hosted(host: _):
            return false
        }
    }
    
    var path: [Entity]? {
        switch position {
        case .Explored(host: _, path: let path):
            precondition(!path.isEmpty, "Entity path cannot be empty when in explored state")
            return path
        case .Blind, .Hosted(host: _):
            return nil
        }
    }
    
    var isBlind: Bool {
        switch position {
        case .Blind:
            return true
        case .Hosted(host: _), .Explored(host: _, path: _):
            return false
        }
    }
    
    var host: Entity? {
        switch position {
        case .Hosted(host: let host):
            return host
        case .Explored(host: let host, path: _):
            return host
        case .Blind:
            return nil
        }
    }
}




//MARK: Phloem
protocol HeaderPhloem {
    func didSelect(host: Entity)
    func didSelect(_ entity: Entity)
    func didSelectGlobe()
    func didExitHost()
    func didSignOut()
}

fileprivate typealias Phloem = CanvasPhloem
extension Header: Phloem {
    func didSelect(entity: Entity) {
        //UPSTREAM
        phloem?.didSelect(entity)
    }
    
    func didSelectTop() {
        xylem.presentingMap = false
    }
    
    func didSelectBottom() {
        xylem.presentingMap = true
    }
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static func pump_SignOut() -> AnyPublisher<Bool, Never> {
        Auth0Manager.signOut()
    }
}




//MARK: Constants
fileprivate struct DEBUG_DATA {
    let xylem: Header.Xylem = Header.Xylem()
    init() {
        xylem.position = .Hosted(host: DEBUG_ENTITY)
        xylem.canvasXylem.position = .Centered(host: DEBUG_ENTITY, entity: DEBUG_ENTITY)
    }
}
fileprivate let BACKDROP_COLOR: Color = Color(red: 247, green: 248, blue: 248)
