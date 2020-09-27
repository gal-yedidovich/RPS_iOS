//
//  LobbyModel.swift
//  RPS
//
//  Created by Gal Yedidovich on 28/09/2020.
//

import SwiftUI
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
		switch LobbyMsgType.from(data: data) {
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
