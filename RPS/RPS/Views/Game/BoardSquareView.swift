//
//  BoardSquareView.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import SwiftUI

struct BoardSquareView: View {
	var onClick: (Square)->()
	var square: Square
	
	var body: some View {
		Button { onClick(square) } label: {
			if square.type == .None || square.type == .Hidden {
				backColor
			} else {
				Image(systemName: square.type.rawValue)
					.resizable()
					.scaledToFit()
					.padding(5)
					.foregroundColor(color)
			}
		}
		.frame(width: 45, height: 45)
		.disabled(!square.isMine && !square.highlighted)
	}
	
	var color: Color {
		square.isMine ? square.hidden ? .pink : .red
			: square.type != .None ? .blue
			: .clear
	}
	
	var backColor: Color {
		if square.highlighted && square.type != .Hidden { return .green }

		switch (square.isMine, square.type) {
		case (_, .Hidden): return .blue
		case (let mine, .None): return mine ? .red : .gray
		default: return .clear
		}
	}
}

struct BoardSquareView_Previews: PreviewProvider {
	static var previews: some View {
		BoardSquareView(onClick: {_ in}, square: Square(position: (0,0), isMine: true, type: .None, highlighted: true))
	}
}
