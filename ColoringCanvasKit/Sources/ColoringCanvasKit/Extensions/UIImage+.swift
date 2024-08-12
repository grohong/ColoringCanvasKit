//
//  UIImage+.swift
//
//
//  Created by Hong Seong Ho on 8/11/24.
//

import UIKit

extension UIImage {

    var pixelBuffer: CVPixelBuffer? { pixelBuffer(width: Int(size.width), height: Int(size.height)) }

    /**
     Resizes the image to width x height and converts it to an RGB CVPixelBuffer.
     */
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        pixelBuffer(
            width: width, height: height,
            pixelFormatType: kCVPixelFormatType_32BGRA,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            alphaInfo: .noneSkipFirst
        )
    }

    func pixelBuffer(
        width: Int,
        height: Int,
        pixelFormatType: OSType,
        colorSpace: CGColorSpace,
        alphaInfo: CGImageAlphaInfo
    ) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ] as [String: Any]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormatType,
            attrs as CFDictionary,
            &maybePixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else { return nil }
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)

        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)

        guard let context = CGContext(
            data: pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()

        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }

    func mergeWith(topImage: UIImage) -> UIImage? {
        let bottomImage = self
        UIGraphicsBeginImageContext(size)
        let areaSize = CGRect(x: 0, y: 0, width: bottomImage.size.width, height: bottomImage.size.height)
        bottomImage.draw(in: areaSize)
        topImage.draw(in: areaSize, blendMode: .normal, alpha: 1.0)
        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mergedImage
    }

    func maskWithColor(color: UIColor) -> UIImage? {
        guard let maskImage = cgImage else { return nil }

        let width = size.width
        let height = size.height
        let bounds = CGRect(x: 0, y: 0, width: width, height: height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        context.clip(to: bounds, mask: maskImage)
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        if let cgImage = context.makeImage() {
            let coloredImage = UIImage(cgImage: cgImage)
            return coloredImage
        } else {
            return nil
        }
    }
}
