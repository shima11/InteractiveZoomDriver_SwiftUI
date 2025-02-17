//
//  ContentView.swift
//  InteractiveZoomDriver_SwiftUI
//
//  Created by Jinsei Shima on 2022/12/07.
//

import SwiftUI
import InteractiveZoomDriver_SwiftUI

struct ContentView: View {
  var body: some View {
    TabView {

      NavigationView {
        ZStack {

          Color.white.edgesIgnoringSafeArea(.all)

          ScrollView(showsIndicators: false) {

            VStack(spacing: 40) {

              Image("sample")
                .resizable()
                .scaledToFit()
                .frame(height: 400)
                .padding(24)
                .addInteractiveZoom()

              Color.gray
                .frame(width: 300, height: 300)

              Color.gray
                .frame(width: 300, height: 300)

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
