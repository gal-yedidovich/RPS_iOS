//
//  Game.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import Foundation
import BasicExtensions

class LobbyModel: ObservableObject {
	static let instance = LobbyModel()
	
	@Published var messages: [Message] = []
	@Published var lobbyPlayers: [LobbyPlayer] = []
	@Published var token: Int?
	@Published var name: String? = UserDefaults.standard.string(forKey: "name")
	@Published var invitation: NewInvitationDto?
	@Published var showInvitation = false
	@Published var invitationPending = false
	
	private init() {
		NetworkClient.Lobby.callback = onReceived(data:)
	}
	
	func onReceived(data: Data) {
		switch lobbyMsgType(from: data) {
		case .newUser:
			let newPlayer: LobbyPlayer = try! .from(json: data)
			if !lobbyPlayers.contains(where: { $0.token == newPlayer.token }) {
				lobbyPlayers.append(newPlayer)
			}
		case .userLeft:
			let p: TokenMsg = try! .from(json: data)
			lobbyPlayers.removeAll(where: { $0.token == p.token })
		case .newChatMsg:
			let msgDto: ReceiveMessageDto = try! .from(json: data)
			let msg = Message(text: msgDto.msg, sender: msgDto.name, isMe: false, date: msgDto.time)
			messages.append(msg)
		case .invite:
			invitation = try! .from(json: data)
			showInvitation = true
		case .answer:
			invitationPending = false
			let answer: AnswerDto = try! .from(json: data)
			if answer.accept {
				GameModel.instance.gameId = answer.game_id
			}
		case nil:
			print("nothing")
		}
	}
}

class GameModel: ObservableObject {
	static let instance = GameModel()
	
	@Published var board: [[Square]] = initialBaord 
	@Published var state: GameState = SelectFlagState()
	@Published var gameId: Int = -1 {
		didSet {
			if gameId != -1 {
				NetworkClient.Game.connect(with: Shared.token)
			}
		}
	}
	@Published var loading = false
	@Published var opponentReady = false
	var won = false
	var randomized = false
	
	private init() {
		NetworkClient.Game.callback = onReceive(data:)
	}
	
	func onReceive(data: Data) {
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
						self.board[position / 10][position % 10].type = self.pawnFrom(dict["type"] as! String)
					}
				}
			}
		}
	}
	
	var showRandomBtn: Bool { state.showRandomBtn }
	
	var message: String { state.textMsg }
	
	func pawnFrom(_ type: String) -> PawnType {
		switch type {
		case "rock": return .Rock
		case "paper": return .Paper
		case "scissors": return .Scissors
		default: return .None
		}
	}
	
	func move(from src: Square, to dest: Square) {
		move(from: src.position, to: dest.position)
	}
	
	func move(from: (row: Int, col: Int), to: (row: Int, col: Int)) {
		let sq = board[from.row][from.col]
		let type = sq.type
		let isMine = sq.isMine
		board[from.row][from.col].type = .None
		board[from.row][from.col].isMine = false
		board[to.row][to.col].type = type
		board[to.row][to.col].isMine = isMine
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

struct Square: Identifiable {
	let id = UUID()
	var position: (row: Int, col: Int)
	var isMine: Bool
	var type: PawnType
	var highlighted = false
	var hidden = false
}

enum PawnType: String {
	case Rock = "hexagon.fill",
		 Paper = "doc.fill",
		 Scissors = "scissors",
		 Flag = "flag",
		 Trap = "xmark.seal",
		 Hidden = " ",
		 None = ""
}
