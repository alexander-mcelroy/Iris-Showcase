//
//  Sheet.swift
//  Xylem-Frontend-Apple (iOS)
//
//  Created by Developer on 6/4/21.
//

import SwiftUI
import Combine


//MARK: Leaf
struct Sheet: UIViewRepresentable {
    @ObservedObject var xylem: Xylem
    let phloem: SheetPhloem?
    
    func makeUIView(context: UIViewRepresentableContext<Sheet>) -> UIScrollView {
        let scroll_view = UIScrollView()
        scroll_view.delegate = context.coordinator
        scroll_view.minimumZoomScale = 1
        scroll_view.maximumZoomScale = 5
        scroll_view.showsVerticalScrollIndicator = false
        scroll_view.showsHorizontalScrollIndicator = false
        scroll_view.backgroundColor = UIColor.clear
        scroll_view.contentInsetAdjustmentBehavior = .never
        
        let dx = UIScreen.main.bounds.width
        let dy = UIScreen.main.bounds.height
        scroll_view.contentInset = .init(top: dy / 2, left: dx / 2, bottom: dy / 2, right: dx / 2)
        
        let content_view = UIView()
        content_view.frame = .init(origin: .zero, size: CONTENT_VIEW_SIZE)
        content_view.backgroundColor = .clear
        content_view.clipsToBounds = true
        content_view.layer.cornerRadius = content_view.frame.height / 2
        content_view.layer.masksToBounds = true
        content_view.layer.borderWidth = 3
        content_view.layer.borderColor = UIColor(Color.orange).cgColor
        
        let blur_view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur_view.frame = content_view.bounds
        content_view.addSubview(blur_view)
        
        let mask = UIView()
        mask.frame = content_view.bounds
        mask.layer.cornerRadius = mask.frame.height / 2
        mask.layer.masksToBounds = true
        mask.backgroundColor = .red
        content_view.mask = mask

        scroll_view.addSubview(content_view)
        scroll_view.zoomScale = 1
        scroll_view.presentContentCenter()
        
        return scroll_view
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: UIViewRepresentableContext<Sheet>) {
        context.coordinator.update(scrollView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: Sheet
        private var live_annotations: [Annotation] = []

        init(_ parent: Sheet) {
            self.parent = parent
        }
        
        func update(_ scrollView: UIScrollView) {
            if !parent.xylem.needsUpdate {
                return
            }
            guard let content_view = scrollView.subviews.first else {return}
        
            content_view.subviews.forEach { $0.removeFromSuperview() }
            live_annotations = []
            
            let blur_view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
            blur_view.frame = content_view.bounds
            content_view.addSubview(blur_view)
            
            let drops = parent.xylem.drops.sortedByLayoutPriority(decreasing: true)
            drops.forEach { drop in
                if let abstraction = drop as? DroppedAbstraction {
                    let annotation = Sheet.Annotation(drop: abstraction)
                    content_view.addSubview(annotation.uiView)
                    live_annotations.append(annotation)
                    
                } else if let portal = drop as? DroppedPortal {
                    let annotation = Sheet.Annotation(drop: portal, parent.phloem?.didSelect ?? {_ in })
                    content_view.addSubview(annotation.uiView)
                    live_annotations.append(annotation)
                    
                } else if let dropped_entity = drop as? DroppedEntity {
                    let annotation = Sheet.Annotation(drop: dropped_entity, parent.phloem?.didSelect ?? {_ in })
                    content_view.addSubview(annotation.uiView)
                    live_annotations.append(annotation)
                }
            }
            parent.xylem.needsUpdate = false
            
            scrollView.presentContentCenter()
        }
    }
}

extension Sheet.Coordinator {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        scrollView.subviews.first
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let content_view = scrollView.subviews.first, scrollView.frame != .zero else { return }
        
        let z = scrollView.zoomScale

        let center_x = scrollView.contentOffset.x + (scrollView.bounds.width / 2)
        let center_y = scrollView.contentOffset.y + (scrollView.bounds.height / 2)
        let converted = scrollView.convert(CGPoint(x: center_x, y: center_y), to: content_view)
        
        let location = Location3D(x: converted.x, y: converted.y, z: z)

        parent.phloem?.didMove(to: location)
        
        live_annotations.forEach { annotation in
            let dz = annotation.drop.location.z - scrollView.zoomScale
            if dz < -1 {
                annotation.uiView.alpha = 0
            } else if -1 <= dz && dz <= 0 {
                annotation.uiView.alpha = 1 + dz
            } else if 0 < dz {
                annotation.uiView.alpha = 1
            }
        }
    }
}

fileprivate extension UIScrollView {
    func presentContentCenter() {
        setZoomScale(minimumZoomScale, animated: true)
        let width = frame != .zero ? frame.width : UIScreen.main.bounds.width
        let height = frame != .zero ? frame.height : UIScreen.main.bounds.height
        let x = (contentSize.width - width) / 2
        let y = (contentSize.height - height) / 2
        let offset = CGPoint(x: x, y: y)
        setContentOffset(offset, animated: true)
    }
}

extension Sheet {
    private struct Annotation {
        let uiView: UIView
        let drop: Dropped
        
        init(drop: DroppedEntity, _ action: @escaping (DroppedEntity) -> Void) {
            let ui_view = DroppedEntityAnnotation(droppedEntity: drop, action: action).uiView
            ui_view.clipsToBounds = false
            ui_view.backgroundColor = UIColor.clear
            let x = drop.location.x - (DROPPED_ENTITY_RADIUS / drop.location.z)
            let y = drop.location.y - (DROPPED_ENTITY_RADIUS / drop.location.z)
            let z = drop.location.z
            ui_view.frame = CGRect(x: x, y: y, width: 2 * DROPPED_ENTITY_RADIUS / z, height: 2 * DROPPED_ENTITY_RADIUS / z)
            self.uiView = ui_view
            self.drop = drop
        }
        
        init(drop: DroppedPortal, _ action: @escaping (DroppedPortal) -> Void) {
            let ui_view = DroppedPortalAnnotation(droppedPortal: drop, action: action).uiView
            ui_view.clipsToBounds = false
            ui_view.backgroundColor = UIColor.clear
            let x = drop.location.x - (DROPPED_PORTAL_RADIUS / drop.location.z)
            let y = drop.location.y - (DROPPED_PORTAL_RADIUS / drop.location.z)
            let z = drop.location.z
            ui_view.frame = CGRect(x: x, y: y, width: 2 * DROPPED_PORTAL_RADIUS / z, height: 2 * DROPPED_PORTAL_RADIUS / z)
            self.uiView = ui_view
            self.drop = drop
        }

        init(drop: DroppedAbstraction) {
            let ui_view = DroppedAbstractionAnnotation(droppedAbstraction: drop).uiView
            ui_view.clipsToBounds = false
            ui_view.backgroundColor = UIColor.clear
            let x = drop.location.x - (DROPPED_ABSTRACTION_RADIUS / drop.location.z)
            let y = drop.location.y - (DROPPED_ABSTRACTION_RADIUS / drop.location.z)
            let z = drop.location.z
            ui_view.frame = CGRect(x: x, y: y, width: 2 * DROPPED_ABSTRACTION_RADIUS / z, height: 2 * DROPPED_ABSTRACTION_RADIUS / z)
            self.uiView = ui_view
            self.drop = drop
        }
    }
}

fileprivate struct DroppedEntityAnnotation: View {
    let droppedEntity: DroppedEntity
    let action: (DroppedEntity) -> Void
    var body: some View {
        GeometryReader { geometry in
            let length = min(geometry.size.width, geometry.size.height)
            Button(action: {
                action(droppedEntity)
            }, label: {
                EntityPortrait(entity: droppedEntity.entity)
            })
            .shadow(radius: 10)
            .frame(width: length, height: length, alignment: .center)
        }
    }
}

fileprivate struct DroppedPortalAnnotation: View {
    let droppedPortal: DroppedPortal
    let action: (DroppedPortal) -> Void
    var body: some View {
        GeometryReader { geometry in
            let length = min(geometry.size.width, geometry.size.height)
            Button(action: {
                action(droppedPortal)
            }, label: {
                LinkFlavicon(url: droppedPortal.url)
            })
            .frame(width: length, height: length, alignment: .center)
        }
    }
}

fileprivate struct DroppedAbstractionAnnotation: View {
    let droppedAbstraction: DroppedAbstraction
    var body: some View {
        GeometryReader { geometry in
            let length = min(geometry.size.width, geometry.size.height)
            Circle()
                .foregroundColor(.clear)
                .overlay(
                    RemoteImage(url: droppedAbstraction.imageURL)
                        .scaledToFill()
                        .clipShape(Circle()))
                .shadow(radius: 10)
                .frame(width: length, height: length, alignment: .center)
        }
    }
}

struct Sheet_Previews: PreviewProvider {
    static var previews: some View {
        Sheet(xylem: DEBUG_DATA().xylem, phloem: nil)
            .previewDisplayName("Sheet")
    }
}




//MARK: Xylem
extension Sheet {
    class Xylem: ObservableObject {
        @Published var drops: [Dropped] = []
        fileprivate var needsUpdate: Bool = true
        
        private var drops_listener: AnyCancellable?
        init() {
            drops_listener = $drops.sink { _ in
                self.needsUpdate = true
            }
        }
    }
}




//MARK: Phloem
protocol SheetPhloem {
    func didSelect(droppedEntity: DroppedEntity)
    func didSelect(droppedPortal: DroppedPortal)
    func didSelect(droppedAbstraction: DroppedAbstraction)
    func didMove(to location: Location3D)
}
extension SheetPhloem {
    func didSelect(droppedEntity: DroppedEntity) {}
    func didSelect(droppedPortal: DroppedPortal) {}
    func didSelect(droppedAbstraction: DroppedAbstraction) {}
    func didMove(to location: Location3D) {}
}




//MARK: Constants
fileprivate struct DEBUG_DATA {
    let xylem = Sheet.Xylem()
    init() {
        xylem.drops = DEBUG_DROPPED_ENTITIES + DEBUG_DROPPED_ABSTRACTIONS + DEBUG_DROPPED_PORTALS
    }
}
let DROPPED_PORTAL_RADIUS: CGFloat = 20
let DROPPED_ENTITY_RADIUS: CGFloat = 20
let DROPPED_ABSTRACTION_RADIUS: CGFloat = 125
let CONTENT_VIEW_SIZE: CGSize = CGSize(width: 500, height: 500)
func IN_CONTENT_VIEW(_ location: Location3D, padding: CGFloat = 0) -> Bool {
    let content_radius = CONTENT_VIEW_SIZE.height / 2
    let content_midpoint = Location3D(x: content_radius, y: content_radius, z: 1)
    return location.isIntersecting2D(content_midpoint, radius: content_radius - padding)
}




