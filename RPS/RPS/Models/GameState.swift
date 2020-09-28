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
				model.board[row][col].type = .Flag
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
				model.board[row][col].type = .Trap
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
				let (row, col) = squares[i].position
				model.board[row][col].hidden = true
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
		if x > 0 && !board[x - 1][y].isMine {
			model.board[x - 1][y].highlighted = true
			highlighted.append(model.board[x - 1][y])
		}
		if x < BOARD_SIZE - 1 && !board[x + 1][y].isMine {
			model.board[x + 1][y].highlighted = true
			highlighted.append(model.board[x + 1][y])
		}
		if y > 0 && !board[x][y - 1].isMine {
			model.board[x][y - 1].highlighted = true
			highlighted.append(model.board[x][y - 1])
		}
		if y < BOARD_SIZE - 1 && !board[x][y + 1].isMine {
			model.board[x][y + 1].highlighted = true
			highlighted.append(model.board[x][y + 1])
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
			let (x, y) = s.position
			model.board[x][y].highlighted = false
		}
		
		if isHighlighted {
			let from =  SquarePosition(row: selected.position.row, col: selected.position.col)
			let to =  SquarePosition(row: square.position.row, col: square.position.col)
			let body = MoveDto(token: Shared.token, gameId: model.gameId, from: from, to: to)
			
			HttpClient.Game.send(to: .move, body: body) { (result: Result<MoveRespDto>) in
				guard case let .success(payload) = result else { return }
				
				if let battle = payload.battle { //do battle
					if selected.hidden {
						let (row, col) = selected.position
						withAnimation {
							model.board[row][col].hidden = false
						}
					}
					
					var delay: TimeInterval = 0.4
					if let sType = payload.s_type { //reveal
						delay *= 2
						let type: PawnType = .from(string: sType)
						withAnimation {
							model.board[to.row][to.col].type = type
						}
					}
					
					post(delay: delay) {
						withAnimation {
							if battle > 0 { //win
								model.move(from: selected, to: square)
							} else if battle < 0 { //lose
								let from = selected.position
								model.board[from.row][from.col].type = .None
								model.board[from.row][from.col].isMine = false
							} else { //draw
								model.draw.show(from: selected.position, to: square.position, myTurn: true)
							}
						}
					}
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
			if model.board[to.row][to.col].hidden {
				let (row, col) = to
				withAnimation {
					model.board[row][col].hidden = false
				}
			}
			
			var delay: TimeInterval = 0.4
			if let sType = move.s_type { //reveal
				delay *= 2
				let type: PawnType = .from(string: sType)
				withAnimation {
					model.board[from.row][from.col].type = type
				}
			}
			
			post(delay: delay) {
				withAnimation {
					if battle > 0 { //win
						model.move(from: from, to: to)
					} else if battle < 0 { //lose
						model.board[from.row][from.col].type = .None
					} else { //draw
						model.draw.show(from: from, to: to, myTurn: false)
					}
				}
			}
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
 
