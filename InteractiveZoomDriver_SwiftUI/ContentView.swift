//
//  ContentView.swift
//  InteractiveZoomDriver_SwiftUI
//
//  Created by Jinsei Shima on 2022/12/07.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    // TODO: タブを切り替えるとZoomが動かなくなる
    TabView {
      NavigationView {
        ZStack {

          Color.white.edgesIgnoringSafeArea(.all)

          ScrollView(showsIndicators: false) {

            VStack(spacing: 40) {

              Image("sample")
                .resizable()
                .frame(
                  width: UIScreen.main.bounds.width * 0.8,
                  height: UIScreen.main.bounds.width * 0.8
                )
                .addPinchZoom()

              Color.gray
                .frame(
                  width: UIScreen.main.bounds.width * 0.8,
                  height: UIScreen.main.bounds.width * 0.8
                )

              Color.gray
                .frame(
                  width: UIScreen.main.bounds.width * 0.8,
                  height: UIScreen.main.bounds.width * 0.8
                )

              Color.gray
                .frame(
                  width: UIScreen.main.bounds.width * 0.8,
                  height: UIScreen.main.bounds.width * 0.8
                )

            }
            .padding(.vertical, 24)
          }
        }
        .navigationTitle(Text("Title"))
        .navigationBarTitleDisplayMode(.inline)
      }
      .tabItem {
        Text("Tab1")
      }
      Color.white.tabItem {
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
