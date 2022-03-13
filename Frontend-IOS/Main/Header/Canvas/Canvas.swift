//
//  Canvas.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/4/21.
//

import SwiftUI
import Combine
import LinkPresentation


//MARK: Leaf
struct Canvas: View {
    @ObservedObject var xylem: Xylem
    let phloem: CanvasPhloem?
    var body: some View {
        ZStack {
            Sheet(xylem: xylem.sheetXylem, phloem: self)
                .ignoresSafeArea()
            
            NavigationLayer(phloem: phloem)
                .environmentObject(xylem)
        
            StudioLayer()
                .environmentObject(xylem)
        }
        .opacity(xylem.isBlind ? 0 : 1)
        .sheet(isPresented: $xylem.presentingPortal) {
            if let url = xylem.richLinkUrl {
                RichLink(url: url)
            }
        }
    }
}

struct Canvas_Previews: PreviewProvider {
    static var previews: some View {
        Canvas(xylem: DEBUG_DATA().xylem, phloem: nil)
            .background(Color.gray)
    }
}

fileprivate struct NavigationLayer: View {
    @EnvironmentObject var xylem: Canvas.Xylem
    let phloem: CanvasPhloem?
    var body: some View {
        VStack(spacing: 0) {
            Color.clear.contentShape(Rectangle())
                .frame(height: 180)
                .onTapGesture {
                    phloem?.didSelectTop()
                }
            
            Spacer()
            
            Color.clear.contentShape(Rectangle())
                .frame(height: 180)
                .onTapGesture {
                    phloem?.didSelectBottom()
                }
        }
    }
}

fileprivate struct StudioLayer: View {
    @EnvironmentObject var xylem: Canvas.Xylem
    var body: some View {
        if let entity = xylem.entity {
            ZStack {
                if entity.relationship == .Admin {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Spacer()
                            SettingsButton(systemName: "drop.fill") {
                                xylem.studio = .DropAbstraction
                            }
                            .frame(width: 40, height: 40)
                            .frame(width: 60, height: 60, alignment: .center)
                            .contentShape(Rectangle())
                            .padding(.trailing)
                            .opacity(xylem.studio.inactive ? 1 : 0)
                            .animation(.linear(duration: 0.1))
                        }
                        Spacer()
                    }
                    
                    DropAbstractionCursor()
                    DropEntityCursor()
                    DropPortalCursor()
                    LiftingCursor()
                }
            }.animation(.none)
        }
    }
}

fileprivate struct DropAbstractionCursor: View {
    @EnvironmentObject var xylem: Canvas.Xylem
    private var actionable: Bool {
        IN_CONTENT_VIEW(xylem.sheetLocation)
    }
    
    var body: some View {
        ZStack {
            if xylem.studio.droppingAbstraction {
                Circle()
                    .stroke(lineWidth: STANDARD_LINEWIDTH)
                    .foregroundColor(actionable ? Color.white : Color.red)
                    .contentShape(Circle())
                    .frame(width: 2 * DROPPED_ABSTRACTION_RADIUS, height: 2 * DROPPED_ABSTRACTION_RADIUS, alignment: .center)
                    .onTapGesture {
                        xylem.studio = .DropEntity
                    }
                
                if actionable {
                    DropLiftButtonLayer(style: .Drop) {
                        guard let host = xylem.host
                        else {
                            preconditionFailure("Canvas is only visible in Explored position")
                        }
                        xylem.dropFormXylem.position =
                            .DropAbstraction(
                                location: xylem.sheetLocation,
                                host: host)
                    }
                }
            }
        }
    }
}

fileprivate struct DropEntityCursor: View {
    @EnvironmentObject var xylem: Canvas.Xylem
    private var actionable: Bool {
        !WITHIN_PROXIMITY(xylem.sheetLocation, drops: xylem.sheetXylem.drops)
    }
    
    var body: some View {
        ZStack {
            if xylem.studio.droppingEntity {
                Circle()
                    .stroke(lineWidth: STANDARD_LINEWIDTH)
                    .foregroundColor(actionable ? Color.clear : Color.red)
                    .frame(width: 2 * PROXIMITY_RADIUS, height: 2 * PROXIMITY_RADIUS, alignment: .center)
                    .overlay(
                        Circle()
                            .stroke(lineWidth: STANDARD_LINEWIDTH)
                            .foregroundColor(Color.white)
                            .frame(width: 2 * DROPPED_ENTITY_RADIUS, height: 2 * DROPPED_ENTITY_RADIUS, alignment: .center))
                    .frame(width: 2 * DROPPED_ABSTRACTION_RADIUS, height: 2 * DROPPED_ABSTRACTION_RADIUS, alignment: .center)
                    .contentShape(Circle())
                    .onTapGesture {
                        xylem.studio = .DropPortal
                    }
                
                if actionable {
                    DropLiftButtonLayer(style: .Drop) {
                        guard let host = xylem.host
                        else {
                            preconditionFailure("Canvas is only visible in Explored position")
                        }
                        xylem.dropFormXylem.position =
                            .DropEntity(
                                location: xylem.sheetLocation,
                                host: host)
                    }
                }
            }
        }
    }
}

fileprivate struct DropPortalCursor: View {
    @EnvironmentObject var xylem: Canvas.Xylem
    private var actionable: Bool {
        !WITHIN_PROXIMITY(xylem.sheetLocation, drops: xylem.sheetXylem.drops)
    }

    var body: some View {
        if xylem.studio.droppingPortal {
            Circle()
                .stroke(lineWidth: STANDARD_LINEWIDTH)
                .foregroundColor(actionable ? Color.clear : Color.red)
                .frame(width: 2 * PROXIMITY_RADIUS, height: 2 * PROXIMITY_RADIUS, alignment: .center)
                .overlay(
                    Rectangle()
                        .stroke(lineWidth: STANDARD_LINEWIDTH)
                        .foregroundColor(Color.white)
                        .frame(width: 2 * DROPPED_PORTAL_RADIUS, height: 2 * DROPPED_PORTAL_RADIUS, alignment: .center))
                .frame(width: 2 * DROPPED_ABSTRACTION_RADIUS, height: 2 * DROPPED_ABSTRACTION_RADIUS, alignment: .center)
                .contentShape(Circle())
                .onTapGesture {
                    xylem.studio = .Lift
                }
            
            if actionable {
                DropLiftButtonLayer(style: .Drop) {
                    guard let host = xylem.host
                    else {
                        preconditionFailure("Canvas is only visible in Explored position")
                    }
                    xylem.dropFormXylem.position =
                        .DropPortal(
                            location: xylem.sheetLocation,
                            host: host)
                }
            }
        }
    }
}

fileprivate struct LiftingCursor: View {
    @EnvironmentObject var xylem: Canvas.Xylem
    @State private var presenting_form: Bool = false
    private var actionable: Bool {
        targeted_drop != nil
    }

    var body: some View {
        ZStack {
            if xylem.studio.liftingDrops {
                Image(systemName: "xmark.circle")
                    .resizable()
                    .foregroundColor(actionable ? .red : .white)
                    .scaledToFit()
                    .font(.system(.body).weight(.ultraLight))
                    .frame(width: DROPPED_ENTITY_RADIUS * 2, height: DROPPED_ENTITY_RADIUS * 2, alignment: .center)
                    .frame(width: 2 * DROPPED_ABSTRACTION_RADIUS, height: 2 * DROPPED_ABSTRACTION_RADIUS, alignment: .center)
                    .contentShape(Circle())
                    .onTapGesture {
                        xylem.studio = .Inactive
                    }
                
                if actionable {
                    DropLiftButtonLayer(style: .Lift) {
                        guard
                            let host = xylem.host,
                            let drop = targeted_drop
                        else {
                            preconditionFailure("Canvas is only visible in Explored position")
                        }
                        xylem.dropFormXylem.position =
                            .Lift(drop: drop, host: host)
                    }
                }
            }
        }
    }
    
    private var targeted_drop: Dropped? {
        let location = xylem.sheetLocation
        let drops: [Dropped] = xylem.sheetXylem.drops.sortedByLayoutPriority()
        return drops.first { drop in
            if location.z > (drop.location.z + 1) {
                return false
            }
            var drop_radius: CGFloat = DROPPED_PORTAL_RADIUS
            if drop is DroppedEntity {
                drop_radius = DROPPED_ENTITY_RADIUS
                
            } else if drop is DroppedAbstraction {
                drop_radius = DROPPED_ABSTRACTION_RADIUS
            }
            
            let lift_radius = DROPPED_ENTITY_RADIUS
            let scaled_radius = (drop_radius / drop.location.z) + (lift_radius / location.z)
            return location.isIntersecting2D(drop.location, radius: scaled_radius)
        }
    }
}

fileprivate struct DropLiftButtonLayer: View {
    @EnvironmentObject private var xylem: Canvas.Xylem
    @State private var presenting_write: Bool = false
    let style: Style
    let action: () -> Void
    private var icon_name: String {
        switch style {
        case .Drop:
            return "drop.fill"
        case .Lift:
            return "smoke.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Button {
                action()
                presenting_write = true
            } label: {
                VStack {
                    Image(systemName: icon_name)
                        .resizable()
                        .foregroundColor(.orange)
                        .scaledToFit()
                        .font(.system(.body).weight(.ultraLight))
                        //.rotationEffect(style == .Lift ? .degrees(0) : .zero)
                    
                    Text(style.rawValue)
                        .font(.system(size: 17, weight: .thin, design: .default))
                        .fontWeight(.thin)
                        .foregroundColor(.orange)
                }
                .frame(width: 70, height: 70, alignment: .center)
                .opacity(0.9)
            }
            .frame(width: 200, height: 200, alignment: .center)
            .contentShape(Circle())
            .padding(.bottom)
        }
        .sheet(isPresented: $presenting_write) {
            DropForm(xylem: xylem.dropFormXylem, phloem: xylem)
        }
    }
    
    enum Style: String {
        case Drop = "Drop"
        case Lift = "Lift"
    }
}




//MARK: Xylem
extension Canvas {
    class Xylem: ObservableObject {
        @Published var position: Position = .Blind
        enum Position {
            case Blind
            case Centered(host: Entity, entity: Entity)
        }
        
        //LEAF
        @Published fileprivate var studio: Studio = .Inactive
        @Published fileprivate var sheetLocation: Location3D = Location3D(x: CONTENT_VIEW_SIZE.width / 2, y: CONTENT_VIEW_SIZE.height / 2, z: 1)
        @Published fileprivate var presentingPortal: Bool = false
        @Published fileprivate var richLinkUrl: URL?
        fileprivate let dropFormXylem: DropForm.Xylem = DropForm.Xylem()
        
        //XYLEM
        fileprivate let sheetXylem: Sheet.Xylem = Sheet.Xylem()
        private var position_listener: AnyCancellable?
        private var drops_loader: AnyCancellable?
        private var metadata_loader = LPMetadataProvider()
        
        init() {
            position_listener = $position.sink { new_position in
                self.drops_loader?.cancel()
                
                switch new_position {
                case let .Centered(host: host, entity: entity):
                    //BEGIN EXCEPTION to the rule
                    if entity.relationship != .Admin {
                        self.studio = .Inactive
                    }
                    //END EXCEPTION
                    self.sheetXylem.drops = []
                    self.load_drops(entity, host: host)
                    
                case .Blind:
                    self.sheetXylem.drops = []
                }
            }
        }
    }
}

extension Canvas.Xylem {
    var entity: Entity? {
        switch position {
        case .Centered(host: _, entity: let entity):
            return entity
        case .Blind:
            return nil
        }
    }
    
    var isBlind: Bool {
        switch position {
        case .Blind:
            return true
        case .Centered(entity: _):
            return false
        }
    }
    
    var host: Entity? {
        switch position {
        case .Centered(host: let host, entity: _):
            return host
        case .Blind:
            return nil
        }
    }
}

extension Canvas.Xylem: DropFormPhloem {
    func didUpdateCanvas() {
        guard let entity = entity, let host = host else { return }
        drops_loader?.cancel()
        load_drops(entity, host: host)
    }
    
    private func load_drops(_ entity: Entity, host: Entity) {
        sheetXylem.drops = []
        
        guard entity.counterRelationship != .Distant
        else { return }
        
        self.drops_loader = Pipeline.tap_ReadDrops(of: entity, host: host)
            .receive(on: RunLoop.main)
            .sink {
                if case let .failure(err) = $0 {
                    err.presentToUser()
                }
            } receiveValue: {
                self.sheetXylem.drops = $0
            }
    }
}

fileprivate enum Studio {
    case Inactive
    case DropAbstraction
    case DropEntity
    case DropPortal
    case Lift
    
    var inactive: Bool {
        switch self {
        case .Inactive:
            return true
        case .DropAbstraction, .DropEntity, .DropPortal, .Lift:
            return false
        }
    }
    
    var droppingAbstraction: Bool {
        switch self {
        case .DropAbstraction:
            return true
        case .Inactive, .DropEntity, .DropPortal, .Lift:
            return false
        }
    }
    
    var droppingEntity: Bool {
        switch self {
        case .DropEntity:
            return true
        case .Inactive, .DropAbstraction, .DropPortal, .Lift:
            return false
        }
    }
    
    var droppingPortal: Bool {
        switch self {
        case .DropPortal:
            return true
        case .Inactive, .DropAbstraction, .DropEntity, .Lift:
            return false
        }
    }
    
    var liftingDrops: Bool {
        switch self {
        case .Lift:
            return true
        case .Inactive, .DropAbstraction, .DropEntity, .DropPortal:
            return false
        }
    }
}




//MARK: Phloem
protocol CanvasPhloem {
    func didSelect(entity: Entity)
    func didSelectTop()
    func didSelectBottom()
}

extension Canvas: SheetPhloem {
    func didSelect(droppedEntity: DroppedEntity) {
        //UPSTREAM
        phloem?.didSelect(entity: droppedEntity.entity)
    }
    
    func didSelect(droppedPortal: DroppedPortal) {
        //DOWNSTREAM
        xylem.richLinkUrl = droppedPortal.url
        xylem.presentingPortal = true
    }
    
    func didMove(to location: Location3D) {
        DispatchQueue.main.async {
            xylem.sheetLocation = location
        }
    }
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static func tap_ReadDrops(of entity: Entity, host: Entity) -> AnyPublisher<[Dropped], Error> {
        let url = API_DOMAIN
            .appendingPathComponent("hosts/\(host.id)/drops", isDirectory: false)
            .appending("filter", value: entity.id)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return Pipeline.pump_APIRequest(request)
            .decode(type: APIData<[APIDrop]>.self, decoder: JSONDecoder())
            .map {
                var drops: [Dropped] = []
                $0.data.forEach { api_drop in
                    if let drop = DroppedAbstraction(apiDrop: api_drop) {
                        drops.append(drop)
                    } else if let drop = DroppedPortal(apiDrop: api_drop) {
                        drops.append(drop)
                    } else if let drop = DroppedEntity(apiDrop: api_drop) {
                        drops.append(drop)
                    }
                }
                return drops
            }
            .mapError { _ in
                AppError(title: "Read Drops", reason: "Failed to decode API response")
            }
            .eraseToAnyPublisher()
    }
}




//MARK: Constants
fileprivate struct DEBUG_DATA {
    let xylem = Canvas.Xylem()
    init() {
        xylem.position = .Centered(host: DEBUG_ENTITY, entity: DEBUG_ENTITY)
    }
}
fileprivate let STANDARD_LINEWIDTH: CGFloat = 2
fileprivate let PROXIMITY_RADIUS: CGFloat = DROPPED_ENTITY_RADIUS * 2
fileprivate func WITHIN_PROXIMITY(_ location: Location3D, drops: [Dropped]) -> Bool {
    let proximity_radius_scaled = PROXIMITY_RADIUS / location.z
    if !IN_CONTENT_VIEW(location, padding: proximity_radius_scaled) {
        return true
    }
    
    return !drops.allSatisfy { drop in
        if drop is DroppedAbstraction || abs(location.z - drop.location.z) > 2 {
            return true
        }
        
        let drop_radius = drop is DroppedEntity ? DROPPED_ENTITY_RADIUS : DROPPED_PORTAL_RADIUS
        let drop_radius_scaled = drop_radius / drop.location.z
        
        let radius_scaled = proximity_radius_scaled + drop_radius_scaled
        return !location.isIntersecting2D(drop.location, radius: radius_scaled)
    }
}

fileprivate var DEFAULT_METADATA: LPLinkMetadata {
    let metadata = LPLinkMetadata()
    metadata.title = "Default"
    metadata.url = URL(string: "https://www.nasa.gov/")!
    return metadata
}


