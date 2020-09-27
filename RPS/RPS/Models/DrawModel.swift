//
//  DrawModel.swift
//  RPS
//
//  Created by Gal Yedidovich on 28/09/2020.
//

import Foundation

struct DrawModel {
	var selection: PawnType = .None
	var opponentSelection: PawnType = .None
	var showDraw = false
	var hidingOpponentSelection = true
	var from, to: Position!
	var myTurn: Bool!
	
	mutating func show(from: Position, to: Position, myTurn: Bool) {
		showDraw = true
		self.myTurn = myTurn
		self.from = from
		self.to = to
	}
}

typealias Position = (row: Int, col: Int)
