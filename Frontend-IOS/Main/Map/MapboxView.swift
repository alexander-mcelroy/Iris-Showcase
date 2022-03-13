//
//  MapboxView.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/5/21.
//

import SwiftUI
import Mapbox
import Combine


//MARK: Leaf
struct MapboxView: UIViewRepresentable {
    @ObservedObject var xylem: MapboxView.Xylem
    @EnvironmentObject var staging: Staging
    let phloem: MapboxViewPhloem?
    let mapView: MGLMapView = MGLMapView(frame: .zero, styleURL: DARK_STYLE_URL)
    
    func makeUIView(context: UIViewRepresentableContext<MapboxView>) -> MGLMapView {
        mapView.delegate = context.coordinator
        mapView.minimumZoomLevel = 2
        mapView.setCamera(DEFAULT_CAMERA, animated: false)
        mapView.compassViewPosition = .bottomRight
        
        let press = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mapView(didLongPress:)))
        mapView.addGestureRecognizer(press)
        
        return mapView
    }
    
    func updateUIView(_ : MGLMapView, context: UIViewRepresentableContext<MapboxView>) {
        context.coordinator.update()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MGLMapViewDelegate {
        let parent: MapboxView
        
        private var annotations_source: MGLShapeSource
        private var annotations_layer: MGLCircleStyleLayer
        
        private var query_source: MGLShapeSource
        private var query_layer: MGLCircleStyleLayer
        private var heatmap_layer: MGLHeatmapStyleLayer

        init(_ parent: MapboxView) {
            self.parent = parent
            
            annotations_source = MGLShapeSource(identifier: ANNOTATIONS_SOURCE_ID, features: [])
            annotations_layer = FEATURE_LAYER(annotations_source, ID: ANNOTATIONS_LAYER_ID)
            
            query_source = MGLShapeSource(identifier: QUERY_SOURCE_ID, features: [])
            query_layer = FEATURE_LAYER(query_source, ID: QUERY_LAYER_ID)
            heatmap_layer = HEATMAP_LAYER(query_source, LIGHT_DENSITY, HEATMAP_LAYER_ID)
            
            super.init()
            
            idle_timer = Timer
                .publish(every: .seconds(0.1), on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    self.time_till_idle -= 0.1
                    self.is_idle = self.time_till_idle <= 0
                }
        }
    
        func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
            
            annotations_source = MGLShapeSource(identifier: ANNOTATIONS_SOURCE_ID, features: [])
            annotations_layer = FEATURE_LAYER(annotations_source, ID: ANNOTATIONS_LAYER_ID)
            
            query_source = MGLShapeSource(identifier: QUERY_SOURCE_ID, features: [])
            query_layer = FEATURE_LAYER(query_source, ID: QUERY_LAYER_ID) 
            heatmap_layer = HEATMAP_LAYER(query_source, LIGHT_DENSITY, HEATMAP_LAYER_ID)
            
            style.addSource(annotations_source)
            style.addLayer(annotations_layer)
            
            style.addSource(query_source)
            style.addLayer(query_layer)
            //style.addLayer(heatmap_layer) //TODO Leaving as dots?
            
            update()
        }

        func update() {
            time_till_idle = MAX_TIME_TILL_IDLE + 2
            
            if parent.xylem.mapboxStyle.url != parent.mapView.styleURL {
                parent.mapView.styleURL = parent.xylem.mapboxStyle.url
                return
            }
            
            //Update Hosts Map
            safely_clear_annotations()
            let hosts = parent.xylem.hostsmap.map { EntityAnnotation($0) }
            safely_add_annotations(annotations: hosts)
            
            //Update Sources
            annotations_source.url = parent.xylem.annotationsMapURL
            query_source.url = parent.xylem.queryMapURL
            
            //Update Layers (TODO)
            switch parent.xylem.queryStyle {
            case .Light:
                //heatmap_layer.heatmapColor = HEATMAP_COLOR(LIGHT_DENSITY)
                query_layer.circleColor = LIGHT_COLOR
            case .Dark:
                //heatmap_layer.heatmapColor = HEATMAP_COLOR(DARK_DENSITY)
                query_layer.circleColor = DARK_COLOR
            case .Rich:
                //heatmap_layer.heatmapColor = HEATMAP_COLOR(RICH_DENSITY)
                query_layer.circleColor = RICH_COLOR
            case .None:
                //heatmap_layer.heatmapColor = HEATMAP_COLOR(ZERO_DENSITY)
                query_layer.circleColor = CLEAR_COLOR
            }
            query_layer.circleOpacity = NSExpression(forConstantValue: 0.75)

            //Fly
            if parent.staging.flying {
                let altitude = parent.staging.flyingAltitude ?? 9000000 + Double.random(in: 1...2000000)
                let location =
                    parent.staging.flyingDestination ??
                    parent.xylem.hostsmap.first?.location ??
                    parent.mapView.centerCoordinate
                
                let camera = MGLMapCamera(lookingAtCenter: location, altitude: altitude, pitch: 0, heading: 0)
                parent.mapView.fly(to: camera, withDuration: 3, completionHandler: nil)
                parent.staging.flying = false
                parent.staging.flyingDestination = nil
                parent.staging.flyingAltitude = nil
            }
        }
        
        private var time_till_idle: Double = MAX_TIME_TILL_IDLE + 2
        private var idle_timer: AnyCancellable?
        private var _is_idle: Bool = false
        private var is_idle: Bool {
            get { _is_idle }
            set {
                if _is_idle != newValue {
                    _is_idle = newValue
                    update_annotations(parent.mapView)
                } else {
                    _is_idle = newValue
                }
            }
        }
    }
}

struct MapboxView_Previews: PreviewProvider {
    static var previews: some View {
        MapboxView(xylem: DEBUG_DATA().xylem, phloem: nil)
            .environmentObject(Staging())
    }
}

extension MapboxView.Coordinator {
    func update_annotations(_ mapView: MGLMapView) {
        if is_idle {
            let predicate = NSPredicate(format: "zoom <= \(mapView.zoomLevel)")
            let features = mapView.visibleFeatures(
                in: mapView.bounds,
                styleLayerIdentifiers: Set([ANNOTATIONS_LAYER_ID]),
                predicate: predicate)
            
            let annotations = features.compactMap { feature -> EntityAnnotation? in
                if let geonode = feature.asAPIGeoNode {
                    let entity = Entity(apiGeoNode: geonode)
                    return EntityAnnotation(entity)
                }
                return nil
            }
            safely_add_annotations(annotations: annotations)
            
        } else {
            safely_clear_annotations()
        }
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        time_till_idle = MAX_TIME_TILL_IDLE
        guard parent.xylem.queryMapURL != nil else { return } //Visible Featuers may not be up to date
        let predicate = NSPredicate(format: "zoom <= \(mapView.zoomLevel)")
        let features = mapView.visibleFeatures(
            in: mapView.bounds,
            styleLayerIdentifiers: Set([QUERY_LAYER_ID]),
            predicate: predicate)
        let triggers = features.compactMap { $0.asAPIGeoTrigger?.properties.trigger_id }
        if triggers.count > 0 {
            parent.phloem?.didPull(triggers)
        }
    }

    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if let annotation = annotation as? EntityAnnotation {
            if let dequed = mapView.dequeueReusableAnnotationView(withIdentifier: ANNOTATION_VIEW_REUSE_ID) as? MapboxAnnotationView {
                let uiview = EntityPortrait(entity: annotation.entity).uiView
                dequed.configure(view: uiview)
                return dequed
            }
            return annotation.view
        }
        return nil
    }

    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if let annotation = annotation as? EntityAnnotation {
            parent.phloem?.didSelect(annotation.entity)
        }
    }
    
    @objc func mapView(didLongPress press: UILongPressGestureRecognizer) {
        let point = press.location(in: parent.mapView)
        let coordinate = parent.mapView.convert(point, toCoordinateFrom: parent.mapView)
        parent.phloem?.didLongPress(press, at: coordinate)
    }
}

fileprivate extension MapboxView.Coordinator {
    func safely_add_annotations(annotations: [EntityAnnotation]) {
        let live = parent.mapView.annotations?.compactMap { annotation -> Entity? in
            if let annotation = annotation as? EntityAnnotation {
                return annotation.entity
            }
            return nil
        } ?? []
        
        let to_add = annotations.filter { annotation in
            !live.contains(annotation.entity)
        }
        parent.mapView.addAnnotations(to_add)
    }
    
    func safely_clear_annotations() {
        let hostsmap = parent.xylem.hostsmap
        let to_remove = parent.mapView.annotations?.filter {
            if let entity_annotation = $0 as? EntityAnnotation {
                return !hostsmap.contains(entity_annotation.entity)
            }
            return true
        }
        parent.mapView.removeAnnotations(to_remove ?? [])
    }
}

fileprivate class MapboxAnnotationView: MGLAnnotationView {
    init(size: CGFloat, view: UIView) {
        super.init(reuseIdentifier: ANNOTATION_VIEW_REUSE_ID)
        isDraggable = false
        scalesWithViewingDistance = false
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        configure(view: view)
        alpha = 0
    }

    func configure(view: UIView) {
        subviews.forEach { $0.removeFromSuperview() }
        view.frame = bounds
        view.backgroundColor = .clear
        addSubview(view)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        if superview == nil {
            alpha = 0
        } else {
            fadeIn(duration: 0.7)
        }
    }
}

extension MGLStyle {
    func removeSource(id: String) {
        if let map_source = source(withIdentifier: id) as? MGLShapeSource {
            removeSource(map_source)
        }
    }

    func removeSources(ids: [String]) {
        ids.forEach(removeSource)
    }

    func removeLayer(id: String) {
        if let map_layer = layer(withIdentifier: id) {
            removeLayer(map_layer)
        }
    }

    func removeLayers(ids: [String]) {
        ids.forEach(removeLayer)
    }
}

extension UIView {
    func fadeIn(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }

    func fadeOut(duration: TimeInterval = 1.0) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
}




//MARK: Xylem
extension MapboxView {
    class Xylem: ObservableObject {
        @Published var hostsmap: [Entity] = []
        @Published var queryMapURL: URL?
        @Published var annotationsMapURL: URL?
        @Published var queryStyle: QueryStyle = .None
        @Published var mapboxStyle: MapboxStyle = .Dark
        
        enum QueryStyle {
            case Light
            case Dark
            case Rich
            case None
        }
        
        enum MapboxStyle {
            case Satellite
            case Light
            case Dark
            
            var url: URL {
                switch self {
                case .Satellite:
                    return SATELLITE_STYLE_URL
                case .Light:
                    return LIGHT_STYLE_URL
                case .Dark:
                    return DARK_STYLE_URL
                }
            }
        }
    }
}

fileprivate class EntityAnnotation: MGLPointAnnotation {
    let entity: Entity
    var view: MGLAnnotationView {
        MapboxAnnotationView(size: 50, view: EntityPortrait(entity: entity).uiView)
    }
    
    init(_ entity: Entity) {
        self.entity = entity
        super.init()
        self.coordinate = entity.location
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MGLFeature {
    var asAPIGeoNode:  APIGeoNode? {
        guard
            let id = attribute(forKey: "id") as? String,
            let name = attribute(forKey: "name") as? String,
            let description = attribute(forKey: "description") as? String,
            let zoom = attribute(forKey: "zoom") as? Double,
            let media = attribute(forKey: "media") as? [String: Any],
            let portrait_id = media["portrait_id"] as? String,
            let supplement_id = media["supplement_id"] as? String,
            let weight_str = attribute(forKey: "weight") as? String,
            let weight = APIGeoNode.Properties.Weight(rawValue: weight_str),
            let counter_weight_str = attribute(forKey: "counter_weight") as? String,
            let counter_weight = APIGeoNode.Properties.CounterWeight(rawValue: counter_weight_str)
        else {
            return nil
        }
        
        return APIGeoNode(
            type: "Feature",
            properties: APIGeoNode.Properties(
                id: id,
                name: name,
                description: description,
                live_location_enabled: attribute(forKey: "live_location_enabled") as? Bool,
                zoom: zoom,
                media: APIGeoNode.Properties.Media(
                    portrait_id: portrait_id,
                    supplement_id: supplement_id),
                weight: weight,
                counter_weight: counter_weight),
            geometry: APIGeoNode.Geometry(
                type: "Point",
                coordinates: [coordinate.longitude, coordinate.latitude]))
    }
    
    var asAPIGeoTrigger: APIGeoTrigger? {
        guard
            let trigger_id = attribute(forKey: "trigger_id") as? String,
            let zoom = attribute(forKey: "zoom") as? Double
        else {
            return nil
        }
        return APIGeoTrigger(
            type: "Feature",
            properties: APIGeoTrigger.Properties(
                trigger_id: trigger_id,
                zoom: zoom),
            geometry: APIGeoNode.Geometry(
                type: "Point",
                coordinates: [coordinate.longitude, coordinate.latitude]))
    }
}




//MARK: Phloem
protocol MapboxViewPhloem {
    func didSelect(_ entity: Entity)
    func didPull(_ triggers: [String])
    func didLongPress(_ press: UILongPressGestureRecognizer, at location: CLLocationCoordinate2D)
}




//MARK: Constants
fileprivate let SATELLITE_STYLE_URL: URL = URL(string:"mapbox://styles/rhizomenetworking/ckv1rmx0z203h14ofpuezkdhd/draft")! //TODO: Using Draft URL
fileprivate let DARK_STYLE_URL: URL = URL(string: "mapbox://styles/rhizomenetworking/cksdjzupa0src17syrljx0m6n")!
fileprivate let LIGHT_STYLE_URL: URL = URL(string: "mapbox://styles/rhizomenetworking/cksdjz4n227u418mk1ldlc56k/draft")! //TODO: Using Draft URL
fileprivate struct DEBUG_DATA {
    let xylem: MapboxView.Xylem = MapboxView.Xylem()
}
fileprivate let MAX_TIME_TILL_IDLE: Double = 0.75
fileprivate let ANNOTATION_VIEW_REUSE_ID: String = "Owl-ReusableMapAnnotationView"
fileprivate let DEFAULT_LOCATION = CLLocationCoordinate2D(latitude: 42.293564192170095, longitude: -76.640625)
fileprivate let DEFAULT_CAMERA = MGLMapCamera(lookingAtCenter: DEFAULT_LOCATION, altitude: 10000000, pitch: 0, heading: 0)

fileprivate let ANNOTATIONS_SOURCE_ID = "AnnotationsSourceId"
fileprivate let ANNOTATIONS_LAYER_ID = "AnnotationsLayerId"
fileprivate let QUERY_SOURCE_ID = "QuerySourceId"
fileprivate let QUERY_LAYER_ID = "QueryLayerId"
fileprivate let HEATMAP_LAYER_ID = "HeatmapLayerId"

fileprivate let LIGHT_COLOR: NSExpression = RICH_COLOR
fileprivate let LIGHT_DENSITY: [NSNumber: UIColor] = [
    0.0: .clear,
    0.01: UIColor(red: 145/255, green: 145/255, blue: 145/255, alpha: 1.0),
    0.15: UIColor(red: 207/255, green: 207/255, blue: 207/255, alpha: 1.0),
    0.5: UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0),
    1: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
]

fileprivate let DARK_COLOR: NSExpression = NSExpression(forConstantValue: UIColor(red: 222/255, green: 18/255, blue: 18/255, alpha: 1.0))
fileprivate let DARK_DENSITY: [NSNumber: UIColor] = [
    0.0: .clear,
    0.1: UIColor(red: 0.38, green: 0.00, blue: 0.00, alpha: 1.00),
    0.3: UIColor(red: 0.62, green: 0.00, blue: 0.00, alpha: 1.00),
    0.5: UIColor(red: 0.64, green: 0.00, blue: 0.00, alpha: 1.00),
    0.7: UIColor(red: 0.74, green: 0.00, blue: 0.00, alpha: 1.00),
    1: UIColor(red: 1.00, green: 0.00, blue: 0.00, alpha: 1.00)
]

fileprivate let RICH_COLOR: NSExpression = NSExpression(forConstantValue: UIColor(red: 251/255, green: 253/255, blue: 254/255, alpha: 1.0))
fileprivate let RICH_DENSITY: [NSNumber: UIColor] = [
    0.0: .clear,
    0.1: UIColor(red: 0.25, green: 0.41, blue: 0.88, alpha: 1.00),
    0.3: UIColor(red: 0.00, green: 1.00, blue: 1.00, alpha: 1.00),
    0.5: UIColor(red: 0.06, green: 1.00, blue: 0.00, alpha: 1.00),
    0.7: UIColor(red: 1.00, green: 1.00, blue: 0.00, alpha: 1.00),
    1: UIColor(red: 1.00, green: 0.00, blue: 0.00, alpha: 1.00)
]

fileprivate let CLEAR_COLOR: NSExpression = NSExpression(forConstantValue: UIColor.clear)
fileprivate let ZERO_DENSITY: [NSNumber: UIColor] = [
    0.0: .clear,
    1: .clear
]

fileprivate func HEATMAP_COLOR(_ DENSITY: [NSNumber: UIColor]) -> NSExpression {
    NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($heatmapDensity, 'linear', nil, %@)", DENSITY)
}

fileprivate func HEATMAP_LAYER(_ SOURCE: MGLShapeSource, _ DENSITY: [NSNumber: UIColor], _ ID: String) -> MGLHeatmapStyleLayer {
    let layer = MGLHeatmapStyleLayer(identifier: ID, source: SOURCE)
    layer.heatmapWeight = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:(mag, 'linear', nil, %@)", [0: 0, 6: 1]) //TODO: Replace 'mag'
    layer.heatmapIntensity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [0: 1, 9: 3])
    layer.heatmapRadius = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [0: 4,9: 30])
    layer.heatmapOpacity = NSExpression(format: "mgl_step:from:stops:($zoomLevel, 0.75, %@)", [0: 0.75, 14: 0.25])
    layer.heatmapColor = HEATMAP_COLOR(DENSITY)
    return layer
}

fileprivate func FEATURE_LAYER(_ SOURCE: MGLShapeSource, ID: String) -> MGLCircleStyleLayer {
    let layer = MGLCircleStyleLayer(identifier: ID, source: SOURCE)
    layer.circleColor = NSExpression(forConstantValue: UIColor.clear)
    layer.circleOpacity = NSExpression(format: "mgl_step:from:stops:($zoomLevel, 0, %@)", [0: 0, 14: 0.75])
    layer.circleRadius = NSExpression(forConstantValue: 5)
    return layer
}

fileprivate func DEBUG_FEATURE_LAYER(_ SOURCE: MGLShapeSource, ID: String) -> MGLCircleStyleLayer {
    let layer = MGLCircleStyleLayer(identifier: ID, source: SOURCE)
    layer.circleColor = NSExpression(forConstantValue: UIColor.green)
    layer.circleOpacity = NSExpression(format: "mgl_step:from:stops:($zoomLevel, 0, %@)", [0: 1, 14: 1])
    layer.circleRadius = NSExpression(forConstantValue: 5)
    return layer
}

