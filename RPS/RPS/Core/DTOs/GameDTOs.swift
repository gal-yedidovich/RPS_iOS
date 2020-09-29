//
//  GameDTOs.swift
//  RPS
//
//  Created by Gal Yedidovich on 26/09/2020.
//

import Foundation

struct SelectSquareDto: Encodable {
	let token: Int
	let gameId: Int
	let row: Int
	let col: Int
}

struct ReadyDto: Encodable {
	let token: Int
	let gameId: Int
}

struct ReadyResponseDto: Decodable {
	let success: Bool
	let turn: Int
}

struct OpponentMoveDto: Decodable {
	let type: String
	let from: SquarePosition
	let to: SquarePosition
	let battle: Int?
	let s_type: String?
	let winner: Int?
}

struct SquarePosition: Codable {
	let row: Int
	let col: Int
}

struct MoveDto: Encodable {
	let type = "move"
	let token: Int
	let gameId: Int
	let from: SquarePosition
	let to: SquarePosition
}

struct MoveRespDto: Decodable {
	let battle: Int?
	let s_type: String?
	let winner: Int?
}

struct DrawDecision: Encodable {
	let token = Shared.token
	let gameId = GameModel.instance.gameId
	let decision: String
}

struct DrawResult: Decodable {
	let opponent: String
	let result: Int
}
