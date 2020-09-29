//
//  LobbyDTOs.swift
//  RPS
//
//  Created by Gal Yedidovich on 26/09/2020.
//

import Foundation

struct LoginDto: Decodable {
	let success: Bool
	let token: Int
}

struct LobbyPlayersDto: Decodable {
	let success: Bool
	let player_list: [LobbyPlayer]
}

//Request + Response + ViewModel
struct LobbyPlayer: Codable, Identifiable {
	let token: Int
	let name: String
	
	var id: Int { token }
}

struct NewMessageDto: Encodable {
	let token: Int
	let time: Int64
	let msg: String
}

struct ReceiveMessageDto: Decodable {
	let time: Date
	let name: String
	let msg: String
}

struct TokenMsg: Decodable {
	let token: Int
}

struct SuccessDto: Decodable {
	let success: Bool
}

struct SendInvatationDto: Encodable {
	let sender_token: Int
	let target_token: Int
	let req_type: String
	let name: String
}

struct InvitationResponseDto: Decodable {
	let game_id: Int
}

struct NewInvitationDto: Decodable {
	let sender_name: String
	let sender_token: Int
	let game_id: Int
}

struct AnswerDto: Codable {
	init(invitation: NewInvitationDto, accept: Bool) {
		self.sender_token = invitation.sender_token
		self.game_id = invitation.game_id
		self.accept = accept
	}
	
	let sender_token: Int
	let game_id: Int
	let accept: Bool
	var type = "answer"
	var target_token = Global.token
}
