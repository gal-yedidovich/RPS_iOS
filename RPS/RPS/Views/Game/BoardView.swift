//
//  BoardView.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import SwiftUI

let boardMargin: CGFloat = 6

//TODO: responsive UI
func test(geometry: GeometryProxy) -> CGFloat {
	let insets = geometry.safeAreaInsets
	let windowSize = geometry.size
	let width = windowSize.width - (insets.leading + insets.trailing)
	let height = windowSize.height - (insets.bottom + insets.top)
	
	let minValue = min(width, height)
	return (minValue / 7) - boardMargin
}

struct BoardView: View {
	var board: [[Square]]
	var onClick: (Square)->()
	
    var body: some View {
		VStack(spacing: boardMargin) {
			ForEach(0..<board.count) { row in
				BoardRowView(squares: board[row], onClick: onClick)
			}
		}
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
		BoardView(board: createSquares(), onClick: {_ in})
    }
	
	static func createSquares() -> [[Square]] {
		var board: [[Square]] = []
		
		for i in 0..<7 {
			var row: [Square] = []
			
			for j in 0..<7 {
				let type: PawnType = i < 2 ? .Trap : i < 5 ? .None : .Flag
				row.append(Square(position: (i, j), isMine: i >= 5, type: type))
			}
			
			board.append(row)
		}
		
		return board
	}
}
