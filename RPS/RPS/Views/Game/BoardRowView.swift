//
//  BoardRowView.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import SwiftUI

struct BoardRowView: View {
	var squares: [Square]
	var onClick: (Square)->()
	
    var body: some View {
		HStack(spacing: boardMargin) {
			ForEach(squares) { square in
				BoardSquareView(onClick: onClick, square: square)
			}
		}
    }
}

struct BoardRowView1_Previews: PreviewProvider {
    static var previews: some View {
		let arr = [
			Square(position: (0, 0), isMine: true, type: .None),
			Square(position: (0, 1), isMine: false, type: .Flag),
			Square(position: (0, 2), isMine: false, type: .Trap),
			Square(position: (0, 3), isMine: true, type: .Scissors),
			Square(position: (0, 4), isMine: true, type: .Rock),
			Square(position: (0, 5), isMine: true, type: .Paper),
			Square(position: (0, 6), isMine: false, type: .None),
		]
		BoardRowView(squares: arr, onClick: { _ in })
    }
}
