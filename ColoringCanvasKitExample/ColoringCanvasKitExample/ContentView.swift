//
//  ContentView.swift
//  ColoringCanvasKitExample
//
//  Created by Hong Seong Ho on 8/11/24.
//

import SwiftUI
import ColoringCanvasKit

struct ContentView: View {

    let canvasImage: CanvasImage
    @StateObject private var viewModel = CanvasViewModel()

    var body: some View {
        VStack {
            ColoringCanvasViewRepresentable(
                canvasImage: canvasImage,
                viewModel: viewModel
            )

            Slider(
                value: $viewModel.brushSize,
                in: 1...100,
                label: { Text("Brush Size") }
            )

            ColorPicker("Select Color", selection: Binding(
                get: { Color(viewModel.color) },
                set: { viewModel.color = UIColor($0) }
            ))
            .padding()

            Picker("Tool", selection: $viewModel.toolKind) {
                Text("Autograph").tag(ToolKind.autograph)
                Text("Brush").tag(ToolKind.brush)
                Text("Crayon").tag(ToolKind.crayon)
                Text("fill").tag(ToolKind.fill)
                Text("Eraser").tag(ToolKind.eraser)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            HStack {
                Button(action: {
                    viewModel.backward()
                }) {
                    Text("Back")
                }
                .disabled(!viewModel.isBackwardEnabled)

                Button(action: {
                    viewModel.forward()
                }) {
                    Text("forwarod")
                }
                .disabled(!viewModel.isForwardEnabled)
            }
        }
        .padding()
    }
}
