//
//  GameState.swift
//  RPS
//
//  Created by Gal Yedidovich on 24/09/2020.
//

import Foundation
import SwiftUI
import BasicExtensions

let BOARD_SIZE = 7

protocol GameState {
	var textMsg: String { get }
	
	var showRandomBtn: Bool { get }
	
	var  showNextBtn: Bool { get }
	
	func onClick(square: Square)
	
	func next()
	
	func onReceive(data: Data)
}

extension GameState {
	var model: GameModel { GameModel.instance }
	
	var mainButtonText: String? { nil }
	
	var showRandomBtn: Bool { false }
	
	var showNextBtn: Bool { false }
}

struct SelectFlagState: GameState {
	let textMsg = "Select Flag"
	
	func onClick(square: Square) {
		model.loading = true
		let (row, col) = square.position
		let body = SelectSquareDto(token: Shared.token, gameId: model.gameId, row: row, col: col)
		HttpClient.Game.send(to: .flag, body: body) { result in
			model.loading = false
			
			if case .success = result {
				model.board[square.position].type = .Flag
				model.state = SelectTrapState()
			}
		}
	}
	
	func onReceive(data: Data) {
		if GameMsgType.from(data: data) == .opponentReady {
			model.opponentReady = true
		}
	}
	
	func next() {}
}

struct SelectTrapState: GameState {
	let textMsg = "Select Trap"
	
	func onClick(square: Square) {
		guard square.type != .Flag else { return }
		
		model.loading = true
		let (row, col) = square.position
		let body = SelectSquareDto(token: Shared.token, gameId: model.gameId, row: row, col: col)
		HttpClient.Game.send(to: .trap, body: body) { result in
			model.loading = false
			
			if case .success = result {
				model.board[square.position].type = .Trap
				model.state = RandomRpsState()
			}
		}
	}
	
	func next() {}
	
	func onReceive(data: Data) {
		if GameMsgType.from(data: data) == .opponentReady {
			model.opponentReady = true
		}
	}
}

struct RandomRpsState: GameState {
	let textMsg = "randomize RPS, then click next"
	let mainButtonText = "Next"
	let showRandomBtn = true
	let showNextBtn = true
	
	func onClick(square: Square) {}
	
	func next() {
		guard model.randomized else { return }
		
		let body = ReadyDto(token: Shared.token, gameId: model.gameId)
		HttpClient.Game.send(to: .ready, body: body) { (result: Result<ReadyResponseDto>) in
			guard case let .success(payload) = result else {
				print("error")
				return
			}
			
			let myTurn = payload.turn == Shared.token
			if model.opponentReady {
				model.state = myTurn ? MyTurnState() : WaitingState()
			} else {
				model.state = ReadyState(myTurn: myTurn)
			}
			
			hideMySquares()
		}
	}
	
	func onReceive(data: Data) {
		if GameMsgType.from(data: data) == .opponentReady {
			model.opponentReady = true
		}
	}
	
	private func hideMySquares() {
		let squares = model.board[5..<7].flatMap { $0 }
		
		for i in 0..<squares.count {
			withAnimation(Animation.default.delay(Double(i) / 8)) {
				model.board[squares[i].position].hidden = true
			}
		}
	}
}

struct ReadyState: GameState {
	var myTurn: Bool
	let textMsg = "Waiting for opponent"
	
	func onClick(square: Square) {}
	
	func next() {}
	
	func onReceive(data: Data) {
		if GameMsgType.from(data: data) == .opponentReady {
			model.opponentReady = true
			model.state = myTurn ? MyTurnState() : WaitingState()
		}
		
	}
}

struct MyTurnState: GameState {
	let textMsg = "Your Turn"
	
	func onClick(square: Square) {
		guard square.type != .Flag && square.type != .Trap else { return }
		
		let (x, y) = square.position
		let board = model.board
		var highlighted: [Square] = []
		
		let topPos = (x - 1, y)
		let bottomPos = (x + 1, y)
		let leftPos = (x, y - 1)
		let rightPos = (x, y + 1)
		
		if x > 0 && !board[topPos].isMine {
			model.board[topPos].highlighted = true
			highlighted.append(model.board[topPos])
		}
		if x < BOARD_SIZE - 1 && !board[bottomPos].isMine {
			model.board[bottomPos].highlighted = true
			highlighted.append(model.board[bottomPos])
		}
		if y > 0 && !board[leftPos].isMine {
			model.board[leftPos].highlighted = true
			highlighted.append(model.board[leftPos])
		}
		if y < BOARD_SIZE - 1 && !board[rightPos].isMine {
			model.board[rightPos].highlighted = true
			highlighted.append(model.board[rightPos])
		}
		
		model.state = SelectMoveState(selected: square, highlighted: highlighted)
	}
	
	func next() {}
	
	func onReceive(data: Data) {
		
	}
}

struct SelectMoveState: GameState {
	let textMsg = "Select you move"
	
	let selected: Square
	let highlighted: [Square]
	
	func onClick(square: Square) {
		let isHighlighted = square.highlighted
		
		for s in highlighted {
			model.board[s.position].highlighted = false
		}
		
		if isHighlighted {
			let from =  SquarePosition(row: selected.position.row, col: selected.position.col)
			let to =  SquarePosition(row: square.position.row, col: square.position.col)
			let body = MoveDto(token: Shared.token, gameId: model.gameId, from: from, to: to)
			
			HttpClient.Game.send(to: .move, body: body) { (result: Result<MoveRespDto>) in
				guard case let .success(payload) = result else { return }
				
				if let battle = payload.battle { //do battle
					model.battle(attacker: selected.position, target: square.position, result: battle, reveal: payload.s_type)
				} else {
					model.move(from: selected, to: square)
				}
				
				model.state = WaitingState() //TODO: change to WaitingState
			}
		} else {
			model.state = MyTurnState()
			model.onClick(square: square)
		}
		
	}
	
	func next() {}
	
	func onReceive(data: Data) {
		
	}
}

struct WaitingState: GameState {
	let textMsg = "Opponent's Turn"
	
	func onClick(square: Square) {}
	
	func next() {}
	
	func onReceive(data: Data) {
		guard GameMsgType.from(data: data) == .move else { return }
		let move: OpponentMoveDto = try! .from(json: data)
		
		//rotate position
		let size = BOARD_SIZE
		let from = (row: size - 1 - move.from.row, col: size - 1 - move.from.col)
		let to = (row: size - 1 - move.to.row, col: size - 1 - move.to.col)
		
		if let battle = move.battle {
			model.battle(attacker: from, target: to, result: battle, reveal: move.s_type)
		} else {
			withAnimation {
				model.move(from: from, to: to)
			}
		}
		
		model.state = MyTurnState()
	}
}

struct GameOverState: GameState {
	var textMsg: String { "Game Over, you \(model.won ? "won!" : "lost...")" }
	
	func onClick(square: Square) {}
	
	func next() {}
	
	func onReceive(data: Data) {
		
	}
}
 
