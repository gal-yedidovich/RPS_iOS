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
				NetworkClient.Game.connect(with: Shared.token)
			} else {
				//TODO: disconnect
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
		
		let json = ["token": Shared.token, "gameId": gameId]
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
		let sq = board[from.row][from.col]
		let type = sq.type
		let isMine = sq.isMine
		board[from.row][from.col].type = .None
		board[from.row][from.col].isMine = false
		board[to.row][to.col].type = type
		board[to.row][to.col].isMine = isMine
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
				self.board[from.row][from.col].type = fromType
				self.board[to.row][to.col].type = toType
			}
		}
		
		post(delay: 2.5) {
			withAnimation {
				self.draw = DrawModel() //resets the model
				if drawResult.result > 0 {
					self.move(from: from, to: to)
				} else if drawResult.result < 0 {
					self.board[from.row][from.col].type = .None
					self.board[from.row][from.col].isMine = false
				} else {
					self.draw.show(from: from, to: to, myTurn: self.draw.myTurn)
				}
			}
		}
	}
	
	private static var initialBaord: [[Square]] {
		var board: [[Square]] = []
		
		for i in 0..<7 {
			var row: [Square] = []
			
			for j in 0..<7 {
				row.append(Square(position: (i, j), isMine: i >= 5, type: i < 2 ? .Hidden : .None))
			}
			
			board.append(row)
		}
		
		return board
	}
}
