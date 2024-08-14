//
//  CanvasImage.swift
//
//
//  Created by Hong Seong Ho on 8/11/24.
//

import Foundation

public struct CanvasImage {

    public let originImage: Data
    public var mergedImage: Data
    public var bgImage: Data?
    public var fgImage: Data?

    public init(imageData: Data) {
        self.originImage = imageData
        self.mergedImage = imageData
    }
}
