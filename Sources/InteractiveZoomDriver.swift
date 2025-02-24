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
  @State var isZoom: Bool = false
  @State var isPinch: Bool = false

  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ZStack {

      content

      Color.black.opacity(min((zoomScale - 1) * 0.5, 0.5))
        .animation(.default, value: zoomScale)
        .allowsHitTesting(false)

      // TODO: 戻る時のVelocityも考慮してAnimationさせる

      overlayView?
        .opacity(isZoom ? 1 : 0)
        .scaleEffect(zoomScale)
        .offset(
          x: offset.width + originalFrame.midX - UIScreen.main.bounds.width/2,
          y: offset.height + originalFrame.midY - UIScreen.main.bounds.height/2
        )
        .animation(isPinch ? nil : .spring(), value: zoomScale)
        .animation(isPinch ? nil : .spring(), value: offset)
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
      isZoom = value ?? false
    }
    .onPreferenceChange(PinchingPreferenceKey.self) { value in
      print("pinching:", value ?? "")
      isPinch = value ?? false
    }
  }
}

extension View {
  func addPinchZoom() -> some View {
    ZoomContext {
      self
    }
  }
}

struct ZoomContext<Content: View>: View {

  private let content: Content

  @State private var offset: CGSize = .zero
  @State private var zoomScale: CGFloat = 1
  @State private var isPinching: Bool = false
  @State private var showOverlayView: Bool = false
  @State private var overlayView: EquatableViewContainer? = nil
  @State private var opacity: CGFloat = 1

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .overlay(
        ZoomGestureView(scale: $zoomScale, offset: $offset, isPinching: $isPinching)
      )
      .overlay(GeometryReader { proxy in
        Color.clear
          .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .global))
      })
      .opacity(opacity)
    // ちらつきを防止するためにdelayを入れている
      .animation(opacity > 0 ? nil : .default.delay(0.1), value: opacity)
    // scaleのアニメーションの終了を取得して、全画面の表示の終了を判断
      .modifier(AnimatableCompletionModifier(bindedValue: zoomScale, completion: {
        showOverlayView = (zoomScale > 1) || isPinching
      }))
    // Pinchが開始したら全画面表示を開始する
      .onChange(of: zoomScale, perform: { newValue in
        guard showOverlayView == false else { return }
        showOverlayView = (newValue > 1) || isPinching
      })
    // TODO: Completionを取得するためにscaleのanimationをInteractiveZoomContainerとは別で管理しているのが良くない
      .animation(.spring(), value: zoomScale)
      .onChange(of: showOverlayView, perform: { newValue in
        overlayView = newValue ? .init(view: AnyView(content)) : nil
        opacity = newValue ? 0 : 1
      })
      .preference(key: OffsetPreferenceKey.self, value: offset)
      .preference(key: ScalePreferenceKey.self, value: zoomScale)
      .preference(key: AnyViewPreferenceKey.self, value: overlayView)
      .preference(key: ZoomingPreferenceKey.self, value: showOverlayView)
      .preference(key: PinchingPreferenceKey.self, value: isPinching)
  }
}

// withAnimationのcompletionを取得するため
struct AnimatableCompletionModifier: AnimatableModifier {

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

