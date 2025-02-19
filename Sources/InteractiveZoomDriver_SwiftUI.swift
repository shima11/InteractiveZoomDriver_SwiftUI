// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public struct InteractiveZoomModifier: ViewModifier {

  @State private var currentScale: CGFloat = 1.0
  @State private var currentOffset: CGSize = .zero
  @State private var isPinching: Bool = false

  public init() {

  }

  public func body(content: Content) -> some View {
    content
      .zIndex(Double.greatestFiniteMagnitude)
      .overlay(ZoomGestureView(scale: $currentScale, offset: $currentOffset, isPinching: $isPinching))
      .scaleEffect(currentScale)
      .offset(currentOffset)
      .animation(.bouncy, value: currentScale)
      .animation(.bouncy, value: currentOffset)
      .transaction { transaction in
        transaction.disablesAnimations = isPinching
      }
  }
}

struct ZoomGestureView: UIViewRepresentable {

  @Binding var scale: CGFloat
  @Binding var offset: CGSize
  @Binding var isPinching: Bool

  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    let pinchGesture = UIPinchGestureRecognizer(
      target: context.coordinator,
      action: #selector(context.coordinator.hundlePinchGesture(sender:))
    )
    view.addGestureRecognizer(pinchGesture)
    let panGesture = UIPanGestureRecognizer(
      target: context.coordinator,
      action: #selector(context.coordinator.hundlePanGesture(sender:))
    )
    panGesture.maximumNumberOfTouches = 2
    panGesture.minimumNumberOfTouches = 2
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

    @objc func hundlePinchGesture(sender: UIPinchGestureRecognizer) {

      if sender.state == .began || sender.state == .changed, sender.scale > 1 {

        parent.isPinching = true
        parent.scale = sender.scale

      } else {

        parent.isPinching = false
        parent.scale = 1
      }
    }

    @objc func hundlePanGesture(sender: UIPanGestureRecognizer) {
      if sender.state == .began || sender.state == .changed && parent.scale > 1 {
        let translation = sender.translation(in: sender.view)
        parent.offset = .init(width: translation.x, height: translation.y)
      } else {
        parent.offset = .zero
      }
    }
  }
}

extension View {
  public func addInteractiveZoom() -> some View {
    self.modifier(InteractiveZoomModifier())
  }
}

import UIKit

struct FullScreenOverlay<Content: View>: UIViewRepresentable {

  let content: Content

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIView(context: Context) -> UIView {
    let container = UIView(frame: .zero)
    container.backgroundColor = .clear
    container.isUserInteractionEnabled = false
    context.coordinator.setupHostingController(with: content)

    return container
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    context.coordinator.hostingController?.rootView = content
  }

  func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
    DispatchQueue.main.async {
      coordinator.hostingController?.view.removeFromSuperview()
    }
  }

  class Coordinator {
    var hostingController: UIHostingController<Content>?

    func setupHostingController(with content: Content) {

      hostingController = UIHostingController(rootView: content)
      hostingController?.view.backgroundColor = .clear

      DispatchQueue.main.async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
          self.hostingController?.view.frame = window.bounds
          self.hostingController?.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
          window.addSubview(self.hostingController!.view)
        }
      }
    }
  }
}


#Preview(body: {
  NavigationView {
    ScrollView {
      VStack {

        Color.red
          .frame(width: 100, height: 100)
          .addInteractiveZoom()

        FullScreenOverlay(
          content:
            Color.green
            .frame(width: 100, height: 100)
            .addInteractiveZoom()
        )
        .background(Color.black.opacity(0.1))

        Color.gray
          .frame(width: 100, height: 100)

      }
    }
    // TODO: 外部の影響を受ける
    .clipped()
    .navigationTitle(Text("Title"))
    .navigationBarTitleDisplayMode(.inline)
  }
})
