//
//  ContentView.swift
//  TimeClip
//
//  View principal com navegação por tabs
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            CameraView()
                .tabItem {
                    Label("Câmera", systemImage: "camera.fill")
                }
                .tag(AppState.Tab.camera)
            
            GalleryView()
                .tabItem {
                    Label("Galeria", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppState.Tab.gallery)
            
            CompileView()
                .tabItem {
                    Label("Compilar", systemImage: "film.fill")
                }
                .tag(AppState.Tab.compile)
            
            SettingsView()
                .tabItem {
                    Label("Config", systemImage: "gearshape.fill")
                }
                .tag(AppState.Tab.settings)
        }
        .accentColor(Theme.lavender)
    }
}
