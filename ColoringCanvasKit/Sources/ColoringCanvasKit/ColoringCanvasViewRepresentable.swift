//
//  ColoringCanvasViewRepresentable.swift
//
//
//  Created by Hong Seong Ho on 8/11/24.
//

import SwiftUI
import UIKit

public class CanvasViewModel: ObservableObject {

    @Published public var brushSize: Double
    @Published public var color: UIColor
    @Published public var toolKind: ToolKind

    @Published public var isBackwardEnabled: Bool = false
    @Published public var isForwardEnabled: Bool = false

    @Published fileprivate var backwardEvent: (() -> Void)?
    @Published fileprivate var forwardEvent: (() -> Void)?

    public init(brushSize: Double = 50, color: UIColor = .red, toolKind: ToolKind = .autograph) {
        self.brushSize = brushSize
        self.color = color
        self.toolKind = toolKind
    }

    public func backward() {
        backwardEvent?()
    }

    public func forward() {
        forwardEvent?()
    }
}

public struct ColoringCanvasViewRepresentable: UIViewRepresentable {

    public let canvasImage: CanvasImage
    @ObservedObject public var viewModel: CanvasViewModel

    public class Coordinator: NSObject, ColoringCanvasViewDelegate {
        var parent: ColoringCanvasViewRepresentable

        init(parent: ColoringCanvasViewRepresentable) {
            self.parent = parent
        }

        public func backwardEnabled(isEnabled: Bool) {
            parent.viewModel.isBackwardEnabled = isEnabled
        }

        public func forwardEnabled(isEnabled: Bool) {
            parent.viewModel.isForwardEnabled = isEnabled
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> ColoringCanvasView {
        let view = ColoringCanvasView()
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.contentMode = .scaleAspectFit
        view.isUserInteractionEnabled = true
        view.delegate = context.coordinator

        DispatchQueue.main.async {
            viewModel.backwardEvent = { view.back() }
            viewModel.forwardEvent = { view.forward() }
            view.updateImage(canvasImage: canvasImage)
            view.brushSize = viewModel.brushSize
            view.updateColor(from: viewModel.color)
            view.colorMode = viewModel.toolKind
        }
        return view
    }

    public func updateUIView(_ uiView: ColoringCanvasView, context: Context) {
        uiView.brushSize = viewModel.brushSize
        uiView.updateColor(from: viewModel.color)
        uiView.colorMode = viewModel.toolKind
    }

    public init(
        canvasImage: CanvasImage,
        viewModel: CanvasViewModel
    ) {
        self.canvasImage = canvasImage
        self.viewModel = viewModel
    }
}
