//
//  Environment.swift
//  RPS
//
//  Created by Gal Yedidovich on 29/09/2020.
//

import SwiftUI

struct SquareSize: EnvironmentKey {
	static var defaultValue: CGFloat = 45
}

extension EnvironmentValues {
	var squareSize: CGFloat {
		get { self[SquareSize] }
		set {
			if newValue > 0 {
				self[SquareSize] = newValue
			}
		}
	}
}

extension View {
	func squareSize(_ size: CGFloat) -> some View {
		environment(\.squareSize, size)
	}
}
