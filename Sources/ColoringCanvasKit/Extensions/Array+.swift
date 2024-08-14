//
//  Array+.swift
//  
//
//  Created by Hong Seong Ho on 8/11/24.
//

import Foundation

extension Array {

    subscript (safe index: Array.Index) -> Element? {
        get { indices ~= index ? self[index] : nil }
        set {
            guard let element = newValue else { return }
            self[index] = element
        }
    }
}

