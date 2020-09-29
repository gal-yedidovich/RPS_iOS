//
//  BoardView.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import SwiftUI

let boardMargin: CGFloat = 6

func calcSize(from geometry: GeometryProxy) -> CGFloat {
	let windowSize = geometry.size
	let minValue = min(windowSize.width, windowSize.height)
	
	let boardSize = CGFloat(BOARD_SIZE)
	return (minValue - (boardMargin * (boardSize + 1))) / boardSize
}

struct BoardView: View {
	var board: [[Square]]
	var onClick: (Square)->()
//	@Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
//	@Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

	
    var body: some View {
		GeometryReader(content: { geometry in
			VStack(spacing: boardMargin) {
				ForEach(0..<board.count) { row in
					BoardRowView(squares: board[row], onClick: onClick)
				}
			}
			.position(x: geometry.size.width / 2, y: geometry.size.width / 2)
			.squareSize(calcSize(from: geometry))
		})
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
		BoardView(board: createSquares(), onClick: {_ in})
    }
	
	static func createSquares() -> [[Square]] {
		var board: [[Square]] = []
		
		for i in 0..<BOARD_SIZE {
			var row: [Square] = []
			
			for j in 0..<BOARD_SIZE {
				let type: PawnType = i < 2 ? .Hidden : .None
				row.append(Square(position: (i, j), isMine: i >= 5, type: type))
			}
			
			board.append(row)
		}
		
		return board
	}
}
