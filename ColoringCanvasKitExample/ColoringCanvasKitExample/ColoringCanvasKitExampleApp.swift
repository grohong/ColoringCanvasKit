//
//  ColoringCanvasKitExampleApp.swift
//  ColoringCanvasKitExample
//
//  Created by Hong Seong Ho on 8/11/24.
//

import SwiftUI
import ColoringCanvasKit

@main
struct ColoringCanvasKitExampleApp: App {

    @State private var canvasImage: CanvasImage = {
        if let image = UIImage(named: "example"),
           let imageData = image.pngData() {
            return CanvasImage(imageData: imageData)
        }
        return CanvasImage(imageData: Data())
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(canvasImage: canvasImage)
        }
    }
}
