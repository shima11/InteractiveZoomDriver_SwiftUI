//
//  ContentView.swift
//  InteractiveZoomDriver_SwiftUI
//
//  Created by Jinsei Shima on 2022/12/07.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    TabView {
      NavigationView {
        ZStack {

          Color.white.edgesIgnoringSafeArea(.all)

          ScrollView(showsIndicators: false) {

            VStack(spacing: 40) {

              // TODO: 今のところ複数同時に存在しているとうまく動かない（PreferenceKeyがうまく対応できていない）
              Color.blue
                .frame(width: 200, height: 100)
                .addPinchZoom()

              Color.orange
                .frame(width: 200, height: 200)
                .addPinchZoom()

              Color.blue
                .frame(width: 200, height: 300)

              Color.blue
                .frame(width: 200, height: 300)

              Color.blue
                .frame(width: 200, height: 300)

            }
          }
        }
        .navigationTitle(Text("Title"))
      }
      .tabItem {
        Text("Tab1")
      }
      Color.orange.tabItem {
        Text("Tab2")
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
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

  @State private var localOriginalFrame: CGRect = .zero
  @State private var originalFrame: CGRect = .zero

  @State private var localOffset: CGPoint = .zero
  @State private var offset: CGSize = .zero

  @State private var scale: CGFloat = 1

  @State private var scalePosition: CGPoint = .zero
  @State private var isPinching: Bool = false

  @State private var show: Bool = false

  @State var overlayView: EquatableViewContainer? = nil

  @State var opacity: CGFloat = 1

  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content()
  }

  var body: some View {
    content
      .overlay(
        ZoomGestureView(scale: $scale, offset: $localOffset, scalePosition: $scalePosition, isPinching: $isPinching)
      )
    // overlayとbackgroundの組み合わせでgeometryreaderが動かないケースがあるみたい
      .overlay(GeometryReader { proxy in
        Color.clear
          .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .global))
      })
      .opacity(opacity)
    // ちらつきを防止するためにdelayを入れている
      .animation(opacity > 0 ? nil : .default.delay(0.1), value: opacity)
      .animation(isPinching ? nil : .spring(), value: scale)
      .animation(isPinching ? nil : .spring(), value: offset)
    // scaleのアニメーションの終了を取得して、全画面の表示の終了を判断
      .modifier(AnimatableModifierDouble(bindedValue: scale, completion: {
        show = (scale > 1) || isPinching
      }))
    // Pinchが開始したら全画面表示を開始する
      .onChange(of: scale, perform: { newValue in
        guard show == false else { return }
        show = (newValue > 1) || isPinching
      })
      .onChange(of: show, perform: { newValue in
        overlayView = newValue ? .init(view: AnyView(content)) : nil
        opacity = newValue ? 0 : 1
        offset = .init(width: localOffset.x, height: localOffset.y)
        originalFrame = localOriginalFrame
      })
      .preference(key: OffsetPreferenceKey.self, value: offset)
      .preference(key: ScalePreferenceKey.self, value: scale)
      .preference(key: AnyViewPreferenceKey.self, value: overlayView)
      .preference(key: ZoomingPreferenceKey.self, value: show)
      .preference(key: PinchingPreferenceKey.self, value: isPinching)
  }
}
