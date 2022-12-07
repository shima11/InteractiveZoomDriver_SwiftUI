//
//  InteractiveZoomDriver_SwiftUIApp.swift
//  InteractiveZoomDriver_SwiftUI
//
//  Created by Jinsei Shima on 2022/12/07.
//

import SwiftUI

@main
struct InteractiveZoomDriver_SwiftUIApp: App {

  @Namespace var space

  @State var zoomScale: CGFloat = 1
  @State var originalFrame: CGRect = .zero
  @State var offset: CGSize = .zero
  @State var overlayView: AnyView? = nil
  @State var zooming: Bool = false
  @State var pinching: Bool = false

  var body: some Scene {
    WindowGroup {
      ZStack {

        ContentView()

        Color.black.opacity(min((zoomScale - 1) * 0.5, 0.5))
          .ignoresSafeArea()
          .allowsHitTesting(false)

        overlayView?
          .opacity(zooming ? 1 : 0)
        // TODO: 微妙に元のViewと位置がずれてしまう(12ずれてるっぽい)
          .offset(
            x: offset.width/2 + originalFrame.midX - UIScreen.main.bounds.width/2,
            y: offset.height/2 + originalFrame.midY - UIScreen.main.bounds.height/2 - 12
          )
          .scaleEffect(zoomScale)
          .animation(pinching ? nil : .spring(), value: zoomScale)
          .animation(pinching ? nil : .spring(), value: offset)
          .ignoresSafeArea()
          .allowsHitTesting(false)
      }
      .onPreferenceChange(OffsetPreferenceKey.self) { value in
        print("ofset:", value ?? .zero)
        offset = value ?? .zero
      }
      .onPreferenceChange(ScalePreferenceKey.self) { value in
        print("scale:", value ?? .zero)
        zoomScale = value ?? 1
      }
      .onPreferenceChange(AnyViewPreferenceKey.self) { value in
        print("view:", value?.view ?? "")
        overlayView = value?.view
      }
      .onPreferenceChange(FramePreferenceKey.self) { value in
        print("frame:", value ?? "")
        originalFrame = value ?? .zero
      }
      .onPreferenceChange(ZoomingPreferenceKey.self) { value in
        print("zooming:", value ?? "")
        zooming = value ?? false
      }
      .onPreferenceChange(PinchingPreferenceKey.self) { value in
        print("pinching:", value ?? "")
        pinching = value ?? false
      }

    }
  }
}


struct ZoomGestureView: UIViewRepresentable {

  @Binding var scale: CGFloat
  @Binding var offset: CGPoint
  @Binding var scalePosition: CGPoint
  @Binding var isPinching: Bool

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    let pinchGesture = UIPinchGestureRecognizer(
      target: context.coordinator,
      action: #selector(context.coordinator.hundlePinch(sender:))
    )
    view.addGestureRecognizer(pinchGesture)
    let panGesture = UIPanGestureRecognizer(
      target: context.coordinator,
      action: #selector(context.coordinator.hundlePan(sender:))
    )
    panGesture.maximumNumberOfTouches = 2
    panGesture.delegate = context.coordinator
    view.addGestureRecognizer(panGesture)
    return view
  }

  func updateUIView(_ uiView: UIViewType, context: Context) {
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {

    private var parent: ZoomGestureView

    init(parent: ZoomGestureView) {
      self.parent = parent
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      return true
    }

    @objc func hundlePinch(sender: UIPinchGestureRecognizer) {

      if sender.state == .began || sender.state == .changed, sender.scale > 1 {

        parent.isPinching = true

        withAnimation(.spring()) {
          parent.scale = sender.scale
        }

        if parent.scalePosition == .zero {
          let scalePoint: CGPoint =  .init(
            x: sender.location(in: sender.view).x / sender.view!.bounds.width,
            y: sender.location(in: sender.view).y / sender.view!.bounds.height
          )
          parent.scalePosition = scalePoint
        }

      } else {

        parent.isPinching = false

        withAnimation(.spring()) {
          parent.scale = 1
          parent.scalePosition = .zero
        }
      }
    }

    @objc func hundlePan(sender: UIPanGestureRecognizer) {
      if sender.state == .began || sender.state == .changed && parent.scale > 1 {
        withAnimation(.spring()) {
          parent.offset = sender.translation(in: sender.view)
        }
      } else {
        withAnimation(.spring()) {
          parent.offset = .zero
          parent.scalePosition = .zero
        }
      }
    }
  }
}

// withAnimationのcompletionを取得するため
struct AnimatableModifierDouble: AnimatableModifier {

  private var targetValue: Double

  // SwiftUI gradually varies it from old value to the new value
  var animatableData: Double {
    didSet {
      checkIfFinished()
    }
  }

  var completion: () -> ()

  // Re-created every time the control argument changes
  init(bindedValue: Double, completion: @escaping () -> ()) {
    self.completion = completion
    self.animatableData = bindedValue
    targetValue = bindedValue
//    print("init value: \(animatableData), \(targetValue)")
  }

  func checkIfFinished() -> () {
//    print("Current value: \(animatableData), \(targetValue)")
    if (animatableData == targetValue) {
      DispatchQueue.main.async {
        self.completion()
      }
    }
  }

  // Called after each gradual change in animatableData to allow the
  // modifier to animate
  func body(content: Content) -> some View {
    // content is the view on which .modifier is applied
    content
    // We don't want the system also to
    // implicitly animate default system animatons it each time we set it. It will also cancel
    // out other implicit animations now present on the content.
      .animation(nil)
  }
}


@available(iOS 14.0, *)
struct AppNamespace: EnvironmentKey {
  static var defaultValue: Namespace.ID? {
    return nil
  }
}

@available(iOS 14.0, *)
extension EnvironmentValues {
  var appNamespace: Namespace.ID? {
    get {
      return self[AppNamespace.self]
    }
    set {
      self[AppNamespace.self] = newValue
    }
  }
}

struct FramePreferenceKey: PreferenceKey {
  typealias Value = CGRect?
  static var defaultValue: Value = nil
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}

struct OffsetPreferenceKey: PreferenceKey {
  typealias Value = CGSize?
  static var defaultValue: Value = nil
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}
struct ScalePreferenceKey: PreferenceKey {
  typealias Value = CGFloat?
  static var defaultValue: Value = nil
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}

struct EquatableViewContainer: Equatable {
  let id = UUID().uuidString
  let view: AnyView?
  static func == (lhs: EquatableViewContainer, rhs: EquatableViewContainer) -> Bool {
    return lhs.id == rhs.id
  }
}
struct AnyViewPreferenceKey: PreferenceKey {
  typealias Value = EquatableViewContainer?
  static var defaultValue: Value = nil
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}

struct ZoomingPreferenceKey: PreferenceKey {
  typealias Value = Bool?
  static var defaultValue: Value = nil
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}

struct PinchingPreferenceKey: PreferenceKey {
  typealias Value = Bool?
  static var defaultValue: Value = nil
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value = nextValue()
  }
}
