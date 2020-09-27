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
	var showDraw = true
	var hidingOpponentSelection = true
	var result: Int? = nil
}
