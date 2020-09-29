//
//  GameModel.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import SwiftUI
import Foundation
import BasicExtensions

class GameModel: ObservableObject {
	static let instance = GameModel()
	
	@Published var board: [[Square]] = initialBaord 
	@Published var state: GameState = SelectFlagState()
	@Published var loading = false
	@Published var opponentReady = false
	@Published var draw = DrawModel()
	@Published var gameId: Int = -1 {
		didSet {
			if gameId != -1 {
				NetworkClient.Game.connect(with: Global.token)
				NetworkClient.Lobby.disconnect()
			} else {
				NetworkClient.Lobby.connect(with: Global.token)
				NetworkClient.Game.disconnect()
			}
		}
	}
	var won = false
	var randomized = false
	
	private init() {
		NetworkClient.Game.callback = onReceive(data:)
	}
	
	func onReceive(data: Data) {
		if GameMsgType.from(data: data) == .draw {
			onReceivedDraw(data: data)
			return
		}
		state.onReceive(data: data)
	}
	
	func onClick(square: Square) {
		state.onClick(square: square)
	}
	
	func next() {
		state.next()
	}
	
	func randomRPS() {
		loading = true
		
		let json = ["token": Global.token, "gameId": gameId]
		HttpClient.Game.send(to: .random, body: json) { result in
			self.loading = false
			self.randomized = true
			
			if case let .success(data) = result {
				let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
				print(json)
				for (key, value) in json {
					if let position = Int(key) {
						let dict = value as! [String: Any]
						self.board[position / 10][position % 10].type = .from(string: dict["type"] as! String)
					}
				}
			}
		}
	}
	
	var showRandomBtn: Bool { state.showRandomBtn }
	
	var showNextBtn: Bool { state.showNextBtn }
	
	var message: String { state.textMsg }
	
	func move(from src: Square, to dest: Square) {
		move(from: src.position, to: dest.position)
	}
	
	func move(from: Position, to: Position) {
		let copy = board[from]
		
		board.mutate(at: from) {
			$0.type = .None
			$0.hidden = false
			$0.isMine = false
		}
		board.mutate(at: to) {
			$0.type = copy.type
			$0.hidden = copy.hidden
			$0.isMine = copy.isMine
		}
	}
	
	func battle(attacker: Position, target: Position, result: Int, reveal: String?, winner winnerToken: Int?) {
		let myTurn = board[attacker].isMine
		
		withAnimation {
			board[attacker].hidden = false
			board[target].hidden = false
		}
		
		var delay: TimeInterval = 0.4
		if let sType = reveal { //reveal
			delay *= 2 //increase delay for UX
			let type: PawnType = .from(string: sType)
			
			withAnimation {
				board[myTurn ? target : attacker].type = type
			}
		}
		
		post(delay: delay) {
			withAnimation {
				if result > 0 { //win
					self.move(from: attacker, to: target)
				} else if result < 0 { //lose
					self.board.mutate(at: attacker) {
						$0.type = .None
						$0.isMine = false
					}
				} else { //draw
					self.draw.show(from: attacker, to: target, myTurn: myTurn)
				}
			}
			
			if let _ = winnerToken {
				self.gameOver(won: myTurn)
			} else {
				self.state = myTurn ? WaitingState() : MyTurnState()
			}
		}
	}
	
	func sendDrawDecision(type: PawnType) {
		let body = DrawDecision(decision: type.string)
		
		HttpClient.Game.send(to: .draw, body: body) { result in
			guard case let .success(payload) = result else { return }
			
			self.onReceivedDraw(data: payload)
		}
	}
	
	func onReceivedDraw(data: Data) {
		guard let drawResult: DrawResult = try? .from(json: data) else { return }
		
		let from = self.draw.from!
		let to = self.draw.to!
		
		withAnimation() {
			self.draw.hidingOpponentSelection = false
		}
		
		post(delay: 0.5) {
			withAnimation() {
				self.draw.opponentSelection = .from(string: drawResult.opponent)
			}
		}
		
		post(delay: 1.5) {
			withAnimation() {
				self.draw.showDraw = false
			}
		}
		
		post(delay: 2) {
			withAnimation {
				let (fromType, toType) = self.draw.myTurn
					? (self.draw.selection, self.draw.opponentSelection)
					: (self.draw.opponentSelection, self.draw.selection)
				self.board[from].type = fromType
				self.board[to].type = toType
			}
		}
		
		post(delay: 2.5) {
			let myTurn = self.draw.myTurn!
			self.draw = DrawModel() //resets the model
			withAnimation {
				if drawResult.result > 0 {
					self.move(from: from, to: to)
				} else if drawResult.result < 0 {
					self.board.mutate(at: from) {
						$0.type = .None
						$0.isMine = false
					}
				} else {
					self.draw.show(from: from, to: to, myTurn: myTurn)
				}
			}
		}
	}
	
	func gameOver(won: Bool) {
		self.won = won
		state = GameOverState(won: won)
		killSquares(mine: !won)
	}
	
	private func killSquares(mine: Bool) {
		let positions = board.flatMap { row in
			row.filter { square in
				if won {
					return !square.isMine && square.type != .None
				} else {
					return square.isMine
				}
			}.map { $0.position }
		}
		
		for i in 0..<positions.count {
			withAnimation(Animation.default.delay(Double(i) / 8)) {
				self.board.mutate(at: positions[i]) { square in
					square.type = .None
					square.isMine = false
				}
			}
		}
	}
	
	private static var initialBaord: [[Square]] {
		var board: [[Square]] = []
		
		for i in 0..<BOARD_SIZE {
			var row: [Square] = []
			
			for j in 0..<BOARD_SIZE {
				row.append(Square(position: (i, j), isMine: i >= 5, type: i < 2 ? .Hidden : .None))
			}
			
			board.append(row)
		}
		
		return board
	}
}


extension Array where Element == Array<Square> {
	mutating func mutate(at position: Position, block: (inout Square)->()) {
		let (row, col) = position
		var square = self[row][col]
		block(&square)
		self[row][col] = square
	}
	
	subscript(position: Position) -> Square {
		get {
			self[position.row][position.col]
		}
		set {
			self[position.row][position.col] = newValue
		}
	}
}
