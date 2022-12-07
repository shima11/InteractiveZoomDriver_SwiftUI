//
//  InteractiveZoomDriver.swift
//  InteractiveZoomDriver_SwiftUI
//
//  Created by Jinsei Shima on 2022/12/07.
//

import SwiftUI

struct InteractiveZoomContainer<Content: View>: View {

  @State var zoomScale: CGFloat = 1
  @State var originalFrame: CGRect = .zero
  @State var offset: CGSize = .zero
  @State var overlayView: AnyView? = nil
  @State var zooming: Bool = false
  @State var pinching: Bool = false

  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ZStack {

      content

      Color.black.opacity(min((zoomScale - 1) * 0.5, 0.5))
        .allowsHitTesting(false)

      overlayView?
        .opacity(zooming ? 1 : 0)
        .scaleEffect(zoomScale)
        .offset(
          x: offset.width + originalFrame.midX - UIScreen.main.bounds.width/2,
          y: offset.height + originalFrame.midY - UIScreen.main.bounds.height/2
        )
        .animation(pinching ? nil : .spring(), value: zoomScale)
        .animation(pinching ? nil : .spring(), value: offset)
        .allowsHitTesting(false)
    }
    .ignoresSafeArea()
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

extension View {
  func addPinchZoom() -> some View {
    PinchZoomContext {
      self
    }
  }
}

struct PinchZoomContext<Content: View>: View {

  private let content: Content

  @State private var originalFrame: CGRect = .zero
  @State private var localOffset: CGPoint = .zero
  @State private var scale: CGFloat = 1
  @State private var isPinching: Bool = false
  @State private var show: Bool = false
  @State private var overlayView: EquatableViewContainer? = nil
  @State private var opacity: CGFloat = 1

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .overlay(
        ZoomGestureView(scale: $scale, offset: $localOffset, isPinching: $isPinching)
      )
    // overlayとbackgroundの組み合わせでgeometryreaderが動かないケースがあるみたい
      .overlay(GeometryReader { proxy in
        Color.clear
          .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .global))
      })
      .opacity(opacity)
    // ちらつきを防止するためにdelayを入れている
      .animation(opacity > 0 ? nil : .default.delay(0.1), value: opacity)
    // scaleのアニメーションの終了を取得して、全画面の表示の終了を判断
      .modifier(AnimatableModifierDouble(bindedValue: scale, completion: {
        show = (scale > 1) || isPinching
      }))
    // Pinchが開始したら全画面表示を開始する
      .onChange(of: scale, perform: { newValue in
        guard show == false else { return }
        show = (newValue > 1) || isPinching
      })
    // TODO: 元に戻るためのアニメーションのCompletionを取得するためにscaleのanimationをInteractiveZoomContainerとは別で管理しているのが良くない
      .animation(.spring(), value: scale)
      .onChange(of: show, perform: { newValue in
        overlayView = newValue ? .init(view: AnyView(content)) : nil
        opacity = newValue ? 0 : 1
      })
      .preference(key: OffsetPreferenceKey.self, value: .init(width: localOffset.x, height: localOffset.y))
      .preference(key: ScalePreferenceKey.self, value: scale)
      .preference(key: AnyViewPreferenceKey.self, value: overlayView)
      .preference(key: ZoomingPreferenceKey.self, value: show)
      .preference(key: PinchingPreferenceKey.self, value: isPinching)
  }
}

struct ZoomGestureView: UIViewRepresentable {

  @Binding var scale: CGFloat
  @Binding var offset: CGPoint
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
        parent.scale = sender.scale

      } else {

        parent.isPinching = false
        parent.scale = 1
      }
    }

    @objc func hundlePan(sender: UIPanGestureRecognizer) {
      if sender.state == .began || sender.state == .changed && parent.scale > 1 {
        parent.offset = sender.translation(in: sender.view)
      } else {
        parent.offset = .zero
      }
    }
  }
}

// withAnimationのcompletionを取得するため
struct AnimatableModifierDouble: AnimatableModifier {

  private var targetValue: Double

  var animatableData: Double {
    didSet {
      checkIfFinished()
    }
  }

  var completion: () -> ()

  init(bindedValue: Double, completion: @escaping () -> ()) {
    self.completion = completion
    self.animatableData = bindedValue
    targetValue = bindedValue
  }

  func checkIfFinished() -> () {
    if (animatableData == targetValue) {
      DispatchQueue.main.async {
        self.completion()
      }
    }
  }

  func body(content: Content) -> some View {
    content
      .animation(nil)
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

