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

              Color.blue
                .frame(width: 200, height: 100)

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
