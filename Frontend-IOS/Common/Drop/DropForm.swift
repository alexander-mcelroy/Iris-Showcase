//
//  DropForm.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/18/21.
//

import SwiftUI
import Combine
import CoreLocation


//MARK: Leaf
struct DropForm: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var xylem: Xylem
    let phloem: DropFormPhloem?
    var body: some View {
        ZStack {
            Backdrop()
                .ignoresSafeArea()
            
            VStack {
                Text(xylem.lifting ? "Lift" : "Drop")
                    .font(.system(size: 55, weight: .thin, design: .default))
                    .foregroundColor(.white)
                    .padding(.top, 55)
                Spacer()
            }
            
            if xylem.droppingAbstraction {
                AbstractionInput(readOnly: nil)
            
            } else if xylem.droppingPortal {
                PortalInput()
                    .padding(.horizontal)
                
            } else if xylem.droppingEntity {
                EntityInput()
            
            } else if xylem.lifting {
                LiftInput()
            }
            
            VStack {
                Spacer()
                ConfirmationButton {
                    xylem.send(phloem?.didUpdateCanvas ?? {})
                    presentationMode.wrappedValue.dismiss()
                }
                .animation(.easeIn)
                .opacity(xylem.canSend ? 1 : 0)
                .padding(.bottom, 60)
                
            }
            .ignoresSafeArea(.keyboard)
        }
        .environmentObject(xylem)
    }
}

struct DropForm_Previews: PreviewProvider {
    static var previews: some View {
        DropForm(xylem: DEBUG_DATA().xylem, phloem: nil)
    }
}

fileprivate struct Backdrop: View {
    @EnvironmentObject var xylem: DropForm.Xylem
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BACKDROP_COLOR
    
                if let image_url =
                        xylem.abstractionToBeLifted?.imageURL ??
                        xylem.entityToBeLifted?.entity.portraitImageURL
                {
                    RemoteImage(url: image_url)
                        .scaledToFill()
                        .clipped()
                        
                    BlurView()
                
                } else if let image = xylem.imageInput, xylem.droppingAbstraction {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                    
                    BlurView()
                    
                } else if let image_url =
                            xylem.host?.supplementalImageURL ??
                            xylem.host?.portraitImageURL
                {
                    RemoteImage(url: image_url)
                        .scaledToFill()
                        .clipped()
                        
                    BlurView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

fileprivate struct AbstractionInput: View {
    @EnvironmentObject var xylem: DropForm.Xylem
    let readOnly: DroppedAbstraction?
    var body: some View {
        if let abstraction = readOnly {
            RemoteImage(url: abstraction.imageURL)
                .scaledToFill()
                .frame(width: 250, height: 250, alignment: .center)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.orange, lineWidth: 2))
            
        } else {
            SquareImageInput(image: $xylem.imageInput)
                .frame(width: 250, height: 250, alignment: .center)
                .clipShape(Circle())
                .overlay(Circle().stroke(xylem.imageInputIsValid ? Color.orange : Color.white, lineWidth: 2))
        }
    }
}

fileprivate struct EntityRead: View {
    let drop: DroppedEntity
    var body: some View {
        VStack {
            EntityPortrait(entity: drop.entity)
                .frame(width: 150, height: 150, alignment: .center)
                .padding(.bottom)
            
            Text(drop.entity.name)
                .font(.system(size: 18, weight: .thin, design: .default))
                .foregroundColor(.white)
        }
    }
}

fileprivate struct EntityInput: View, MapPhloem {
    @EnvironmentObject var xylem: DropForm.Xylem
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ZStack {
            Map(xylem: xylem.mapXylem, phloem: self)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("cancel")
                            .font(.system(size: 18, weight: .regular, design: .default))
                            .foregroundColor(BACKDROP_COLOR)
                    }
                    .padding(.leading)
                    .padding(.top)
                    .animation(.linear(duration: 0.1))
                    
                    Spacer()
                }
                Spacer()
            }

            VStack {
                if let entity = xylem.entityInput {
                    EntityPortrait(entity: entity)
                        .frame(width: 150, height: 150, alignment: .center)
                        .padding(.top, 55)
                        .padding(.bottom)
                    
                    Text(entity.name)
                        .font(.system(size: 18, weight: .regular, design: .default))
                        .foregroundColor(BACKDROP_COLOR)
                } else {
                    Text("Drop")
                        .font(.system(size: 55, weight: .thin, design: .default))
                        .foregroundColor(BACKDROP_COLOR)
                        .padding(.top, 55)
                }
                Spacer()
            }
            .animation(.easeIn)
        }
    }
    
    func didSelect(_ entity: Entity) {
        xylem.entityInput = entity
    }
}

fileprivate struct PortalInput: View {
    @EnvironmentObject var xylem: DropForm.Xylem
    @State private var presenting_portal: Bool = false
    var body: some View {
        VStack {
            TextField("https://www.nasa.gov/", text: $xylem.stringUrlInput)
                .padding()
                .foregroundColor(Color.white)
                .overlay(Rectangle().stroke(xylem.urlInputIsValid ? Color.orange : Color.white, lineWidth: 2))
                .padding(.top, 55 + 55 + 55)
            
            Button {
                presenting_portal = true
            }
            label: {
                if let url = xylem.portalURL {
                    VStack {
                        LinkFlavicon(url: url)
                            .frame(width: 50, height: 50, alignment: .center)

                        Text("test")
                            .font(.system(size: 18, weight: .thin, design: .default))
                            .foregroundColor(.white)
                    }
                }
            }
            .opacity(xylem.urlInputIsValid ? 1 : 0)
            .padding(.top)
            
            Spacer()

        }
        .sheet(isPresented: $presenting_portal) {
            if let url = xylem.portalURL {
                RichLink(url: url)
            }
        }
    }
}

fileprivate struct LiftInput: View {
    @EnvironmentObject var xylem: DropForm.Xylem
    var body: some View {
        ZStack {
            if let abstraction = xylem.abstractionToBeLifted {
                AbstractionInput(readOnly: abstraction)
                
            } else if let entity = xylem.entityToBeLifted {
                EntityRead(drop: entity)
            
            } else if let portal = xylem.portalToBeLifted {
                RichLink(url: portal.url)
                
                VStack {
                    Text("Lift")
                        .font(.system(size: 55, weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .padding(.top, 55)
                    
                    Spacer()
                }
            }
        }
    }
}

 


//MARK: Xylem
extension DropForm {
    class Xylem: ObservableObject {
        @Published var position: Position = .Blind
        enum Position{
            case Blind
            case DropAbstraction(location: Location3D, host: Entity)
            case DropEntity(location: Location3D, host: Entity)
            case DropPortal(location: Location3D, host: Entity)
            case Lift(drop: Dropped, host: Entity)
        }
        
        //LEAF
        @Published fileprivate var imageInput: UIImage?
        @Published fileprivate var stringUrlInput: String = ""
        @Published fileprivate var entityInput: Entity?
        
        //XYLEM
        let mapXylem: Map.Xylem = Map.Xylem()
        private var position_listener: AnyCancellable?
        private var sender: AnyCancellable?
        
        init() {
            position_listener = $position.sink { new_position in
                if case let .DropEntity(location: _, host: host) = new_position {
                    self.mapXylem.position = .Links(ofEntity: host, host: host)
                }
                self.entityInput = nil
            }
        }
    }
}

fileprivate extension DropForm.Xylem {
    var host: Entity? {
        switch position {
        case .DropAbstraction(location: _, host: let host):
            return host
        case .DropEntity(location: _, host: let host):
            return host
        case .DropPortal(location: _, host: let host):
            return host
        case .Lift(drop: _, host: let host):
            return host
        case .Blind:
            return nil
        }
    }
    var lifting: Bool {
        switch position {
        case .Lift:
            return true
        case .Blind, .DropAbstraction, .DropEntity, .DropPortal:
            return false
        }
    }
    
    var droppingAbstraction: Bool {
        switch position {
        case .DropAbstraction:
            return true
        case .Blind, .DropEntity, .DropPortal, .Lift:
            return false
        }
    }
    
    var droppingPortal: Bool {
        switch position {
        case .DropPortal:
            return true
        case .Blind, .DropAbstraction, .DropEntity, .Lift:
            return false
        }
    }
    
    var droppingEntity: Bool {
        switch position {
        case .DropEntity:
            return true
        case .Blind, .DropAbstraction, .DropPortal, .Lift:
            return false
        }
    }
    
    var imageInputIsValid: Bool {
        imageInput != nil
    }
    
    var urlInputIsValid: Bool {
        if let url = URL(string: stringUrlInput) {
            return !stringUrlInput.isEmpty && UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    var entityInputIsValid: Bool {
        entityInput != nil
    }
    
    var canSend: Bool {
        switch position {
        case .Blind:
            return false
        case .DropAbstraction:
            return imageInputIsValid
        case .DropEntity:
            return entityInputIsValid
        case .DropPortal:
            return urlInputIsValid
        case .Lift:
            return true
        }
    }
    
    var portalURL: URL? {
        if urlInputIsValid {
            return URL(string: stringUrlInput)
        }
        return nil
    }
    
    var abstractionToBeLifted: DroppedAbstraction? {
        if case .Lift(drop: let drop, host: _) = position {
            return drop as? DroppedAbstraction
        }
        return nil
    }
    
    var entityToBeLifted: DroppedEntity? {
        if case .Lift(drop: let drop, host: _) = position {
            return drop as? DroppedEntity
        }
        return nil
    }
    
    var portalToBeLifted: DroppedPortal? {
        if case .Lift(drop: let drop, host: _) = position {
            return drop as? DroppedPortal
        }
        return nil
    }
}

fileprivate extension DropForm.Xylem {
    func send(_ onSuccess: @escaping () -> Void) {
        sender?.cancel()
        switch position {
        case .Blind:
            return
        
        case .DropAbstraction(location: let location, host: let host):
            guard let image = imageInput else { return }
            Staging.global.lock()
            sender = Pipeline.pump_CreateDrop(host: host, coordinate: location, image: image)
                .receive(on: RunLoop.main)
                .sink {
                    if case .failure(let err) = $0 {
                        err.presentToUser()
                    }
                    Staging.global.unlock()
                }
                receiveValue: { _ in 
                    onSuccess()
                    Staging.global.unlock()
                }
        
        case .DropEntity(location: let location, host: let host):
            guard let entity = entityInput else { return }
            Staging.global.lock()
            sender = Pipeline.pump_CreateDrop(host: host, coordinate: location, entity: entity)
                .receive(on: RunLoop.main)
                .sink {
                    if case .failure(let err) = $0 {
                        err.presentToUser()
                    }
                    Staging.global.unlock()
                }
                receiveValue: { _ in
                    onSuccess()
                    Staging.global.unlock()
                }
            
        case .DropPortal(location: let location, host: let host):
            guard let url = portalURL, urlInputIsValid else { return }
            Staging.global.lock()
            sender = Pipeline.pump_CreateDrop(host: host, coordinate: location, portal: url)
                .receive(on: RunLoop.main)
                .sink {
                    if case .failure(let err) = $0 {
                        err.presentToUser()
                    }
                    Staging.global.unlock()
                }
                receiveValue: { _ in
                    onSuccess()
                    Staging.global.unlock()
                }
            
        case .Lift(drop: let drop, host: let host):
            Staging.global.lock()
            sender = Pipeline.pump_DeleteDrop(host: host, drop: drop)
                .receive(on: RunLoop.main)
                .sink {
                    if case .failure(let err) = $0 {
                        err.presentToUser()
                    }
                    Staging.global.unlock()
                }
                receiveValue: { _ in
                    onSuccess()
                    Staging.global.unlock()
                }
        }
    }
}




//MARK: Phloem
protocol DropFormPhloem {
    func didUpdateCanvas()
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static func pump_CreateDrop(host: Entity, coordinate: Location3D, image: UIImage) -> AnyPublisher<String, Error> {
        Pipeline.pump_ImageS3(image: image)
            .map {
                APICreateDrop(
                    id: UUID().uuidString,
                    canvas_location: coordinate.asStrings,
                    image_id: $0,
                    portal_url: nil)
            }
            .tryMap {
                do { return try JSONEncoder().encode($0) }
                catch { throw AppError(title: "Create Drop", reason: "Failed to encode body")}
            }
            .flatMap {
                pump_CreateDrop(host: host, createDropBody: $0)
            }
            .eraseToAnyPublisher()
    }
    
    static func pump_CreateDrop(host: Entity, coordinate: Location3D, portal: URL) -> AnyPublisher<String, Error> {
        let body = APICreateDrop(
            id: UUID().uuidString,
            canvas_location: coordinate.asStrings,
            image_id: nil,
            portal_url: portal.absoluteString)
        return Just(body)
            .tryMap {
                do { return try JSONEncoder().encode($0) }
                catch { throw AppError(title: "Create Drop", reason: "Failed to encode body")}
            }
            .flatMap {
                pump_CreateDrop(host: host, createDropBody: $0)
            }
            .eraseToAnyPublisher()
    }
    
    static func pump_CreateDrop(host: Entity, coordinate: Location3D, entity: Entity) -> AnyPublisher<String, Error> {
        let body = APICreateDrop(
            id: entity.id,
            canvas_location: coordinate.asStrings,
            image_id: nil,
            portal_url: nil)
        return Just(body)
            .tryMap {
                do { return try JSONEncoder().encode($0) }
                catch { throw AppError(title: "Create Drop", reason: "Failed to encode body")}
            }
            .flatMap {
                pump_CreateDrop(host: host, createDropBody: $0)
            }
            .eraseToAnyPublisher()
    }
    
    private static func pump_CreateDrop(host: Entity, createDropBody: Data) -> AnyPublisher<String, Error> {
        let url = API_DOMAIN.appendingPathComponent("hosts/\(host.id)/drops", isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = createDropBody
        return Pipeline.pump_APIRequest(request)
            .decode(type: APIData<APIServerMessage>.self, decoder: JSONDecoder())
            .map { $0.data.message }
            .eraseToAnyPublisher()
    }
}

fileprivate extension Pipeline {
    static func pump_DeleteDrop(host: Entity, drop: Dropped) -> AnyPublisher<String, Error> {
        let url = API_DOMAIN.appendingPathComponent("hosts/\(host.id)/drops/\(drop.id)", isDirectory: false)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        return Pipeline.pump_APIRequest(request)
                .decode(type: APIData<APIServerMessage>.self, decoder: JSONDecoder())
                .map { $0.data.message }
                .eraseToAnyPublisher()
    }
}




//MARK: Constants
fileprivate struct DEBUG_DATA {
    let xylem = DropForm.Xylem()
    init() {
        xylem.position = .Lift(drop: DEBUG_DROPPED_ENTITY, host: DEBUG_HOST)
    }
}
fileprivate let BACKDROP_COLOR: Color = Color("Base")
fileprivate func S3_SUFFIX(hostId: String, dropId: String, ext: MediaExtension) -> String {
    hostId + "/drops/" + dropId + "." + ext.rawValue
}

