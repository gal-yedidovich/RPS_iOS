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
	
	func onClick(square: Square)
	
	func next()
	
	func onReceive(data: Data)
}

extension GameState {
	var model: GameModel { GameModel.instance }
	
	var mainButtonText: String? { nil }
	
	var showRandomBtn: Bool { false }
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
		if gameMsgType(from: data) == .opponentReady {
			model.opponentReady = true
		}
	}
	
	func next() {}
}

struct SelectTrapState: GameState {
	let textMsg = "Select Trap"
	
	func onClick(square: Square) {
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
		if gameMsgType(from: data) == .opponentReady {
			model.opponentReady = true
		}
	}
}

struct RandomRpsState: GameState {
	let textMsg = "randomize RPS, then click next"
	let mainButtonText = "Next"
	let showRandomBtn: Bool = true
	
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
		}
	}
	
	func onReceive(data: Data) {
		if gameMsgType(from: data) == .opponentReady {
			model.opponentReady = true
		}
	}
}

struct ReadyState: GameState {
	var myTurn: Bool
	let textMsg = "Waiting for opponent"
	
	func onClick(square: Square) {}
	
	func next() {}
	
	func onReceive(data: Data) {
		if gameMsgType(from: data) == .opponentReady {
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
					var delay: TimeInterval = 0.3
					if let sType = payload.s_type { //reveal
						delay *= 2
						let type = model.pawnFrom(sType)
						withAnimation {
							model.board[to.row][to.col].type = type
						}
					}
					
					post(delay: delay) {
						if battle > 0 { //win
							withAnimation {
								model.move(from: selected, to: square)
							}
						} else if battle < 0 { //lose
							let from = selected.position
							withAnimation {
								model.board[from.row][from.col].type = .None
								model.board[from.row][from.col].isMine = false
							}
						} else { //draw
							//TODO: implement
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
		guard gameMsgType(from: data) == .move else { return }
		let move: OpponentMoveDto = try! .from(json: data)
		
		//rotate position
		let size = BOARD_SIZE
		let from = (row: size - 1 - move.from.row, col: size - 1 - move.from.col)
		let to = (row: size - 1 - move.to.row, col: size - 1 - move.to.col)
		
		if let battle = move.battle {
			var delay: TimeInterval = 0.3
			if let sType = move.s_type { //reveal
				delay *= 2
				let type = model.pawnFrom(sType)
				withAnimation {
					model.board[from.row][from.col].type = type
				}
			}
			
			post(delay: delay) {
				if battle > 0 { //win
					withAnimation {
						model.move(from: from, to: to)
					}
				} else if battle < 0 { //lose
					withAnimation {
						model.board[from.row][from.col].type = .None
//						model.board[from.row][from.col].isMine = false
					}
				} else { //draw
					//TODO: implement
				}
			}
		} else {
			withAnimation {
				model.move(from: from, to: to)
			}
		}
		
		model.state = MyTurnState()
		
		/*
		//reusable inner function
		fun battle(result: Int) {
		context.doneBtn.postDelayed({
		Moves.battle(result, fromSquare, toSquare, context.gameId)
		
		if (json.has("winner")) context.gameOver(false)
		else context.state = MyTurnState(context)
		}, 500) //wait then receive attack
		}
		
		if (json.has("battle")) {
		val result = json["battle"] as Int
		
		toSquare.img.colorFilter?.let { context.doneBtn.post { Moves.clearColorFilter(toSquare.img) } }//indicate my RPS is visible to opponent(if not already)
		if (json.has("s_type")) { //reveal unknown opponent
		fromSquare.type = Square.Type.valueOf(json["s_type"].toString().toLowerCase().capitalize())
		fromSquare.img.post {
		Moves.reveal(fromSquare) {
		battle(result)
		}
		}
		} else battle(result)
		} else context.doneBtn.post {
		Moves.moveTo(fromSquare, toSquare)
		context.state = MyTurnState(context)
		}
		}
		*/
	}
}

struct GameOverState: GameState {
	var textMsg: String { "Game Over, you \(model.won ? "won!" : "lost...")" }
	
	func onClick(square: Square) {}
	
	func next() {}
	
	func onReceive(data: Data) {
		
	}
}
 
