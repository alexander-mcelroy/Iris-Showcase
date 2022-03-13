//
//  EntityForm.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/16/21.
//

import SwiftUI
import Mapbox
import Combine
import AVKit
import Amplify


//MARK: Leaf
struct EntityForm: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var xylem: Xylem
    let phloem: EntityFormPhloem?
    
    var body: some View {
        ZStack {
            Backdrop()
                .environmentObject(xylem)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    Text(xylem.updating ? "Update" : "Create")
                        .font(.system(size: 55, weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .padding(.top, 35)
                    
                    NameInput(valid: name_valid)
                        .padding(.top, 35)
                        .padding(.horizontal)
                        .environmentObject(xylem)
                    
                    VisualInput(portraitValid: portrait_valid, supplementValid: supplement_valid)
                        .padding(.top)
                        .environmentObject(xylem)
                    
                    LocationLabel(defaultLocation: xylem.defaultLocation)
                        .padding(.top)
                        .padding(.horizontal)
                        .environmentObject(xylem)
                    
                    LongTextInput(
                        currentText: $xylem.description,
                        originalText: "",
                        minCharacters: MIN_DESCRIPTION,
                        maxCharacters: MAX_DESCRIPTION)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()
                        .overlay(
                            Rectangle()
                                .stroke(!description_valid || xylem.description.isEmpty ? Color.white : Color.orange, lineWidth: 2))
                        .padding(.top)
                        .padding(.horizontal)
                    
                    Text("optional description")
                        .font(.system(size: 18, weight: .thin, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, xylem.updating ? .zero : CGFloat(170))
                        
                    
                    if xylem.updating {
                        DeleteButton {
                            presentationMode.wrappedValue.dismiss()
                            xylem.send_DeleteHost {
                                phloem?.didDeleteHost()
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 170)
                    }
                }
            }
        
            VStack {
                Spacer()
                ConfirmationButton {
                    presentationMode.wrappedValue.dismiss()
                    switch xylem.position {
                    case .Create:
                        xylem.send_CreateHost {
                            phloem?.didCreateHost(host: $0)
                        }
                    case .Update:
                        xylem.send_UpdateHost {
                            phloem?.didUpdateHost(host: $0)
                        }
                    }
                }
                .opacity(valid ? 1 : 0)
                .padding(.bottom, 60)
            }
        }
        .onDisappear {
            xylem.revertChangesIfNeccessary()
        }
    }
}

struct EntityForm_Previews: PreviewProvider {
    static var previews: some View {
        EntityForm(xylem: DEBUG_DATA().xylem, phloem: nil)
    }
}

fileprivate struct Backdrop: View {
    @EnvironmentObject var xylem: EntityForm.Xylem
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BACKDROP_COLOR
                    
                if let movie_url = xylem.supplementalMovieURL {
                    RemoteMovie(url: movie_url)
                    BlurView()
                    
                } else if let image = xylem.supplementalImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                    BlurView()
                }
            }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
        }
    }
}

fileprivate struct NameInput: View {
    @EnvironmentObject var xylem: EntityForm.Xylem
    let valid: Bool
    var body: some View {
        VStack {
            if let host_name = xylem.host?.name {
                Text(host_name)
                    .font(.system(size: 30, weight: .thin, design: .default))
                    .foregroundColor(.white)
                
            } else {
                TextField("", text: $xylem.name)
                    .padding()
                    .foregroundColor(Color.white)
                    .overlay(Rectangle().stroke(valid ? Color.orange : Color.white, lineWidth: 2))
                
                Text("name")
                    .font(.system(size: 18, weight: .thin, design: .default))
                    .foregroundColor(.white)
            }
        }
    }
}

fileprivate struct VisualInput: View {
    @EnvironmentObject var xylem: EntityForm.Xylem
    let portraitValid: Bool
    let supplementValid: Bool
    var body: some View {
        VStack(spacing: 0) {
            SquareImageInput(image: $xylem.portraitImage)
                .zIndex(1)
                .frame(width: 150, height: 150, alignment: .center)
                .background(BACKDROP_COLOR.zIndex(2))
                .clipShape(Circle())
                .overlay(Circle().stroke(portraitValid ? Color.orange : Color.white, lineWidth: 2))
                .offset(x: .zero, y: 45)
                .padding(.top, -45)
            
            MultimediaInput(image: $xylem.supplementalImage, movieURL: $xylem.supplementalMovieURL)
                .frame(width: 300, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(supplementValid ? Color.orange : Color.white, lineWidth: 2))
        }
    }
}

fileprivate struct LocationLabel: View {
    let defaultLocation: CLLocationCoordinate2D
    var body: some View {
        VStack {
            DefaultLocation(defaultLocation: defaultLocation)
            LiveLocation()
        }
    }
}

fileprivate struct DefaultLocation: View {
    let defaultLocation: CLLocationCoordinate2D
    var body: some View {
        HStack {
            VStack {
                Image(systemName: "mappin.and.ellipse")
                    .resizable()
                    .scaledToFit()
                    .font(.system(.body).weight(.ultraLight))
                    .frame(width: 40, height: 40, alignment: .center)
                
                Text("default")
                    .font(.system(size: 18, weight: .thin, design: .default))
            }
            .foregroundColor(.orange)
            
            Text(defaultLocation.asString)
                .font(.system(size: 18, weight: .thin, design: .default))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

fileprivate struct LiveLocation: View {
    @EnvironmentObject private var xylem: EntityForm.Xylem
    @ObservedObject private var pipeline_state: Pipeline = Pipeline.state
    var body: some View {
        Button {
            xylem.desiresLiveLocation.toggle()
            Pipeline.pump_RequestDeviceLocation()
        }
        label: {
            HStack {
                VStack {
                    Image(systemName: icon_name)
                        .resizable()
                        .scaledToFit()
                        .font(.system(.body).weight(.ultraLight))
                        .frame(width: 40, height: 40, alignment: .center)
                    
                    Text("live")
                        .font(.system(size: 18, weight: .thin, design: .default))
                }
                .foregroundColor(icon_color)
                
                Text(message)
                    .font(.system(size: 18, weight: .thin, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.disabled(pipeline_state.deviceLocationStatus.isUnavailable)
    }
    
    private var icon_name: String {
        xylem.desiresLiveLocation && pipeline_state.deviceLocationStatus.isAvailable ?
            "location.fill" : "location"
    }
    
    private var icon_color: Color {
        xylem.desiresLiveLocation && pipeline_state.deviceLocationStatus.isAvailable ?
            Color.orange : Color.white
    }
    
    private var message: String {
        if pipeline_state.deviceLocationStatus.isUnavailable {
            return "your live location is unavailable"
        
        } else if xylem.desiresLiveLocation {
            if let device_location = pipeline_state.deviceLocation {
                return device_location.asString
            }
        }
        
        return "tap to additionally use your live location, this is optional"
    }
}

extension EntityForm {
    private var valid: Bool {
        name_valid &&
        portrait_valid &&
        supplement_valid &&
        description_valid
    }
    
    private var name_valid: Bool {
        MIN_NAME < xylem.name.count && xylem.name.count < MAX_NAME
    }
    
    private var portrait_valid: Bool {
        xylem.portraitImage != nil
    }
    
    private var supplement_valid: Bool {
        xylem.supplementalImage != nil || xylem.supplementalMovieURL != nil
    }
    
    private var description_valid: Bool {
        xylem.description.isEmpty ||
            (MIN_DESCRIPTION < xylem.description.count && xylem.description.count < MAX_DESCRIPTION)
    }
}




//MARK: Xylem
extension EntityForm {
    class Xylem: ObservableObject {
        @Published var position: Position = .Create(defaultLocation: .init())
        enum Position {
            case Create(defaultLocation: CLLocationCoordinate2D)
            case Update(host: Entity)
        }
        
        @Published fileprivate var name: String = ""
        @Published fileprivate var description: String = ""
        @Published fileprivate var portraitImage: UIImage?
        @Published fileprivate var supplementalImage: UIImage?
        @Published fileprivate var supplementalMovieURL: URL?
        @Published fileprivate var desiresLiveLocation: Bool = false
        
        private var position_listener: AnyCancellable?
        private var portrait_image_loader: AnyCancellable?
        private var supplemental_image_loader: AnyCancellable?
        
        private var create_host_sender: AnyCancellable?
        private var update_host_sender: AnyCancellable?
        private var delete_host_sender: AnyCancellable?
        
        init() {
            position_listener = $position.sink { new_position in
                switch new_position {
                case .Create:
                    self.portrait_image_loader?.cancel()
                    self.supplemental_image_loader?.cancel()
                
                case let .Update(host: host):
                    self.name = host.name
                    self.description = host.description
                    self.load_media(of: host)
                    self.desiresLiveLocation = host.liveLocationEnabled ?? false
                }
            }
        }
        
        fileprivate func revertChangesIfNeccessary() {
            if case .Update(host: let host) = position {
                self.name = host.name
                self.description = host.description
                self.load_media(of: host)
                self.desiresLiveLocation = host.liveLocationEnabled ?? false
            }
        }
    }
}

extension EntityForm.Xylem {
    var host: Entity? {
        if case let .Update(host) = position {
            return host
        }
        return nil
    }
    
    var updating: Bool {
        if case .Update(host: _) = position {
            return true
        }
        return false
    }
    
    var defaultLocation: CLLocationCoordinate2D {
        switch position {
        case .Create(defaultLocation: let location):
            return location
        case .Update(host: let host):
            return host.location
        }
    }
    
    private func load_media(of entity: Entity) {
        self.portraitImage = LOADING_IMAGE
        self.supplementalImage = LOADING_IMAGE
        self.supplementalMovieURL = nil
        
        portrait_image_loader = Pipeline.tap_UIImage(url: entity.portraitImageURL)
            .catch { _ in Just(FAILURE_IMAGE) }
            .receive(on: RunLoop.main)
            .sink { self.portraitImage = $0 }
        
        if let image_url = entity.supplementalImageURL {
            supplemental_image_loader = Pipeline.tap_UIImage(url: image_url)
                .catch { _ in Just(FAILURE_IMAGE) }
                .receive(on: RunLoop.main)
                .sink { self.supplementalImage = $0; self.supplementalMovieURL = nil }
            
        } else if let movie_url = entity.supplementalMovieURL {
            self.supplementalImage = nil
            self.supplementalMovieURL = movie_url
        }
    }
}

fileprivate extension EntityForm.Xylem {
    private var valid_input: Bool {
        guard
            NAME_VALID(name),
            DESCRIPTION_VALID(description),
            let portrait = portraitImage,
            IMAGE_VALID(portrait)
        else {return false}
        
        if let supplement = supplementalImage {
            return IMAGE_VALID(supplement)
        } else if let supplement = supplementalMovieURL {
            let unchanged = host?.supplementalMovieURL == supplement
            let local = MOVIE_VALID(supplement)
            return unchanged || local
        } else {
            return false
        }
    }
    
    func send_CreateHost(_ onSuccess: @escaping (Entity) -> Void) {
        guard valid_input, let portraitImage = portraitImage else {
            Staging.global.alert(title: "Unable to Create Profile", INVALID_FORM_MESSAGE)
            return
        }

        var upload_operation: AnyPublisher<Entity, Error>
        if let supplement = supplementalMovieURL {
            upload_operation = Pipeline.pump_CreateHost(
                name: name,
                description: description,
                defaultLocation: defaultLocation,
                liveLocation: desiresLiveLocation ? Pipeline.state.deviceLocation : nil,
                portraitImage: portraitImage,
                supplementalMovie: supplement)
            
        } else if let supplement = supplementalImage {
            upload_operation = Pipeline.pump_CreateHost(
                name: name,
                description: description,
                defaultLocation: defaultLocation,
                liveLocation: desiresLiveLocation ? Pipeline.state.deviceLocation : nil,
                portraitImage: portraitImage,
                supplementalImage: supplement)
            
        } else {
            Staging.global.alert(title: "Unable to Create Profile", INVALID_FORM_MESSAGE)
            return
        }
        
        Staging.global.lock()
        create_host_sender = upload_operation.receive(on: RunLoop.main)
            .sink {
                if case .failure(let err) = $0 {
                    err.presentToUser()
                }
                Staging.global.unlock()
            }
            receiveValue: {
                onSuccess($0)
                Staging.global.unlock()
            }
        
    }
}

fileprivate extension EntityForm.Xylem {
    func send_UpdateHost(_ onSuccess: @escaping (Entity) -> Void) {
        guard valid_input, let host = host else {
            Staging.global.alert(title: "Unable to Update Profile", INVALID_FORM_MESSAGE)
            return
        }

        var upload_operation: AnyPublisher<Entity, Error>
        if let supplement = supplementalMovieURL, supplement != host.supplementalMovieURL {
            upload_operation = Pipeline.pump_UpdateHost(
                host: host,
                liveLocation: desiresLiveLocation ? Pipeline.state.deviceLocation : nil,
                description: description,
                portraitImage: portraitImage,
                supplementalMovie: supplement)
            
        } else {
            upload_operation = Pipeline.pump_UpdateHost(
                host: host,
                liveLocation: desiresLiveLocation ? Pipeline.state.deviceLocation : nil,
                description: description,
                portraitImage: portraitImage,
                supplementalImage: supplementalImage)
            
        }
        
        Staging.global.lock()
        update_host_sender = upload_operation.receive(on: RunLoop.main)
            .sink {
                if case .failure(let err) = $0 {
                    err.presentToUser()
                }
                Staging.global.unlock()
            }
            receiveValue: {
                onSuccess($0)
                Staging.global.unlock()
            }
        
    }
}

fileprivate extension EntityForm.Xylem {
    func send_DeleteHost(_ onSuccess: @escaping () -> Void) {
        guard let host = host else {return}
                
        Staging.global.lock()
        delete_host_sender = Pipeline.pump_DeleteHost(host: host)
            .sink {
                if case .failure = $0 {
                    Staging.global.alert(title: "Unable to Delete Profile", "Please try again in a few moments")
                }
                Staging.global.unlock()
            }
            receiveValue: { _ in
                onSuccess()
                Staging.global.unlock()
            }
    }
}




//MARK: Pipeline
fileprivate extension Pipeline {
    static func pump_CreateHost(
        name: String,
        description: String,
        defaultLocation: CLLocationCoordinate2D,
        liveLocation: CLLocationCoordinate2D?,
        portraitImage: UIImage,
        supplementalImage: UIImage) -> AnyPublisher<Entity, Error> {
                
        Publishers.Zip(
            Pipeline.pump_ImageS3(image: portraitImage),
            Pipeline.pump_ImageS3(image: supplementalImage)
        )
        .flatMap { (portrait_id, supplement_id) in
            pump_CreateHost(
                name: name,
                description: description,
                defaultLocation: defaultLocation,
                liveLocation: liveLocation,
                portraitId: portrait_id,
                supplementId: supplement_id)
        }
        .eraseToAnyPublisher()
    }
    
    static func pump_CreateHost(
        name: String,
        description: String,
        defaultLocation: CLLocationCoordinate2D,
        liveLocation: CLLocationCoordinate2D?,
        portraitImage: UIImage,
        supplementalMovie: URL) -> AnyPublisher<Entity, Error> {
                
        Publishers.Zip(
            Pipeline.pump_ImageS3(image: portraitImage),
            Pipeline.pump_MovieS3(movie: supplementalMovie)
        )
        .flatMap { (portrait_id, supplement_id) in
            pump_CreateHost(
                name: name,
                description: description,
                defaultLocation: defaultLocation,
                liveLocation: liveLocation,
                portraitId: portrait_id,
                supplementId: supplement_id)
        }
        .eraseToAnyPublisher()
    }
    
    private static func pump_CreateHost(
        name: String,
        description: String,
        defaultLocation: CLLocationCoordinate2D,
        liveLocation: CLLocationCoordinate2D?,
        portraitId: String,
        supplementId: String) -> AnyPublisher<Entity, Error> {
        
        var live_location: [String]?
        if let liveLocation = liveLocation {
            live_location = [String(liveLocation.longitude), String(liveLocation.latitude)]
        }
        let body = APICreateHost(
            id: UUID().uuidString,
            name: name,
            description: description,
            default_location: [String(defaultLocation.longitude), String(defaultLocation.latitude)],
            live_location: live_location,
            portrait_id: portraitId,
            supplement_id: supplementId)
        
        return Just(body)
            .tryMap { body -> Data in
                do { return try JSONEncoder().encode(body) }
                catch { throw AppError(title: "Create Host", reason: error.localizedDescription) }
            }
            .map {
                var request = URLRequest(url: API_DOMAIN.appendingPathComponent("hosts", isDirectory: false))
                request.httpMethod = "POST"
                request.httpBody = $0
                return request
            }
            .flatMap {
                Pipeline.pump_APIRequest($0)
                    .decode(type: APIData<APIGeoNode>.self, decoder: JSONDecoder())
                    .map { Entity(apiGeoNode: $0.data) }
                    .mapError { _ in AppError(title: "Create Host", reason: "Failed to decode API response") }
            }
            .eraseToAnyPublisher()
    }
}

fileprivate extension Pipeline {
    static func pump_UpdateHost(
        host: Entity,
        liveLocation: CLLocationCoordinate2D?,
        description: String?,
        portraitImage: UIImage?,
        supplementalImage: UIImage?) -> AnyPublisher<Entity, Error> {
        
        if let portrait_image = portraitImage, let supplemental_image = supplementalImage {
            return Publishers.Zip(
                Pipeline.pump_ImageS3(image: portrait_image),
                Pipeline.pump_ImageS3(image: supplemental_image)
            )
            .flatMap { (portrait_id, supplement_id) in
                pump_UpdateHost(
                    host: host,
                    liveLocation: liveLocation,
                    description: description,
                    portraitId: portrait_id,
                    supplementId: supplement_id)
            }
            .eraseToAnyPublisher()
            
        } else if let portrait_image = portraitImage {
            return Pipeline.pump_ImageS3(image: portrait_image)
                .flatMap { portrait_id in
                    pump_UpdateHost(
                        host: host,
                        liveLocation: liveLocation,
                        description: description,
                        portraitId: portrait_id,
                        supplementId: nil)
                }
                .eraseToAnyPublisher()
            
        } else if let supplemental_image = supplementalImage {
            return Pipeline.pump_ImageS3(image: supplemental_image)
                .flatMap { supplement_id in
                    pump_UpdateHost(
                        host: host,
                        liveLocation: liveLocation,
                        description: description,
                        portraitId: nil,
                        supplementId: supplement_id)
                }
                .eraseToAnyPublisher()
            
        } else {
            return pump_UpdateHost(
                host: host,
                liveLocation: liveLocation,
                description: description,
                portraitId: nil,
                supplementId: nil)
        }
    }
    
    static func pump_UpdateHost(
        host: Entity,
        liveLocation: CLLocationCoordinate2D?,
        description: String?,
        portraitImage: UIImage?,
        supplementalMovie: URL?) -> AnyPublisher<Entity, Error> {
        
        if let portrait_image = portraitImage, let supplemental_movie = supplementalMovie {
            return Publishers.Zip(
                Pipeline.pump_ImageS3(image: portrait_image),
                Pipeline.pump_MovieS3(movie: supplemental_movie)
            )
            .flatMap { (portrait_id, supplement_id) in
                pump_UpdateHost(
                    host: host,
                    liveLocation: liveLocation,
                    description: description,
                    portraitId: portrait_id,
                    supplementId: supplement_id)
            }
            .eraseToAnyPublisher()
            
        } else if let portrait_image = portraitImage {
            return Pipeline.pump_ImageS3(image: portrait_image)
                .flatMap { portrait_id in
                    pump_UpdateHost(
                        host: host,
                        liveLocation: liveLocation,
                        description: description,
                        portraitId: portrait_id,
                        supplementId: nil)
                }
                .eraseToAnyPublisher()
            
        } else if let supplemental_movie = supplementalMovie {
            return Pipeline.pump_MovieS3(movie: supplemental_movie)
                .flatMap { supplement_id in
                    pump_UpdateHost(
                        host: host,
                        liveLocation: liveLocation,
                        description: description,
                        portraitId: nil,
                        supplementId: supplement_id)
                }
                .eraseToAnyPublisher()
            
        } else {
            return pump_UpdateHost(
                host: host,
                liveLocation: liveLocation,
                description: description,
                portraitId: nil,
                supplementId: nil)
        }
    }
    
    private static func pump_UpdateHost(
        host: Entity,
        liveLocation: CLLocationCoordinate2D?,
        description: String?,
        portraitId: String?,
        supplementId: String?) -> AnyPublisher<Entity, Error> {
        
        var live_location: [String]?
        if let liveLocation = liveLocation {
            live_location = [String(liveLocation.longitude), String(liveLocation.latitude)]
        }

        let body = APIUpdateHost(
            description: description,
            live_location: live_location,
            portrait_id: portraitId,
            supplement_id: supplementId)
        
        return Just(body)
            .tryMap { body -> Data in
                do { return try JSONEncoder().encode(body) }
                catch { throw AppError(title: "Update Host", reason: error.localizedDescription) }
            }
            .map {
                var request = URLRequest(url: API_DOMAIN.appendingPathComponent("hosts/\(host.id)", isDirectory: false))
                request.httpMethod = "PATCH"
                request.httpBody = $0
                return request
            }
            .flatMap {
                Pipeline.pump_APIRequest($0)
                    .decode(type: APIData<APIGeoNode>.self, decoder: JSONDecoder())
                    .map { Entity(apiGeoNode: $0.data) }
                    .mapError { _ in AppError(title: "Update Host", reason: "Failed to decode API response") }
            }
            .eraseToAnyPublisher()
    }
}

fileprivate extension Pipeline {
    static func pump_DeleteHost(host: Entity) -> AnyPublisher<String, Error> {
        var request = URLRequest(url: API_DOMAIN.appendingPathComponent("hosts/\(host.id)", isDirectory: false))
        request.httpMethod = "DELETE"
        
        return Pipeline.pump_APIRequest(request)
            .decode(type: APIData<APIServerMessage>.self, decoder: JSONDecoder())
            .map { $0.data.message }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}




//MARK: Phloem
protocol EntityFormPhloem {
    func didCreateHost(host: Entity)
    func didUpdateHost(host: Entity)
    func didDeleteHost()
}
extension EntityFormPhloem {
    func didCreateHost(host: Entity) {}
    func didUpdateHost(host: Entity) {}
    func didDeleteHost() {}
}




//MARK: To Move
extension CLLocationCoordinate2D {
    var asString: String {
        "\(abs(latitude))° \(latitude > 0 ? "N" : "S")\n\(abs(longitude))° \(longitude > 0 ? "E" : "W")"
    }
}

extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)

        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}

typealias EncodedMovie = (URL, MediaExtension)
typealias EncodedImage = (Data, MediaExtension)
func S3_PREFIX(identityId: String) -> String {
    "public/" + identityId + "/"
}
extension UIImage {
    func encoded() -> EncodedImage? {
        if let jpg_data = jpegData(compressionQuality: 0.25) {
            return (jpg_data, MediaExtension.jpg)
        
        } else if let png_data = pngData() {
            return (png_data, MediaExtension.png)
        
        } else {
            return nil
        }
    }
}
extension URL {
    func encodedAsMovie() -> EncodedMovie? {
        guard
            isFileURL,
            let media_extension = MediaExtension(rawValue: pathExtension),
            media_extension == .mov || media_extension == .mp4
        else { return nil }
        return (self, media_extension)
    }
}




//MARK: Constants
fileprivate struct DEBUG_DATA {
    let xylem: EntityForm.Xylem = EntityForm.Xylem()
    init() {
        xylem.position = .Update(host: DEBUG_HOST)
    }
}
fileprivate let MAX_FILE_SIZE = 30 * 1048576 //30MB
fileprivate let MIN_NAME = 1
fileprivate let MAX_NAME = 60
fileprivate let MIN_DESCRIPTION = 25
fileprivate let MAX_DESCRIPTION = 350
fileprivate let BACKDROP_COLOR: Color = Color("Base")
fileprivate let INVALID_FORM_MESSAGE = "Images and Videos must be less than 30MB. Name must be between \(MIN_NAME) and \(MAX_NAME) characters. Description, if provided, must be between \(MIN_DESCRIPTION) and \(MAX_DESCRIPTION) characters. You can have at most 3 active Irises."

fileprivate func IMAGE_VALID(_ image: UIImage) -> Bool {
    if let jpg_data = image.jpegData(compressionQuality: 1.0) {
        return jpg_data.count < MAX_FILE_SIZE
    } else if let png_data = image.pngData() {
        return png_data.count < MAX_FILE_SIZE
    } else {
        return false
    }
}
fileprivate func MOVIE_VALID(_ movie: URL) -> Bool {
    guard
        movie.isFileURL,
        let filesize = AVURLAsset(url: movie).fileSize,
        let media_extension = MediaExtension(rawValue: movie.pathExtension)
    else { return false }
    
    let valid_path = media_extension == .mov || media_extension == .mp4
    let valid_size = filesize < MAX_FILE_SIZE
    return valid_path && valid_size
}
fileprivate func DESCRIPTION_VALID(_ description: String) -> Bool {
    description.isEmpty || (MIN_DESCRIPTION < description.count && description.count < MAX_DESCRIPTION)
}
fileprivate func NAME_VALID(_ name: String) -> Bool {
    MIN_NAME < name.count && name.count < MAX_NAME
}

