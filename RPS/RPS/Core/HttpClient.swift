//
//  HttpClient.swift
//  RPS
//
//  Created by Gal Yedidovich on 19/09/2020.
//

import Foundation
import BasicExtensions
enum HttpClient {
	case Game, Lobby
	
	private var port: String { self == .Lobby ? "8003" : "8004" }
	
	private var baseUrl: String { "http://127.0.0.1:\(port)" }
	
	func send<Response: Decodable>(to endpoint: EndPoint, body: Encodable, completion: @escaping (Result<Response>)->()) {
		let req = URLRequest(url: "\(baseUrl)\(endpoint.rawValue)")
			.set(method: .POST)
			.set(body: body.json())
		
		URLSession.shared.dataTask(with: req, completion: { result in
			post {
				switch result {
				case .success(let data):
					completion(.success(try! .from(json: data)))
				case .failure(let status, let data):
					print("Failed: status: \(status)")
					print("data:", String(decoding: data, as: UTF8.self))
					completion(.error(Errors.text(String(decoding: data, as: UTF8.self))))
				case .error(let error):
					print("\(#function) error, \(error)")
					completion(.error(error))
				}
			}
		}).resume()
	}
	
	func send(to endpoint: EndPoint, body: Encodable, completion: @escaping (Result<Data>)->()) {
		let req = URLRequest(url: "\(baseUrl)\(endpoint.rawValue)")
			.set(method: .POST)
			.set(body: body.json())
		
		URLSession.shared.dataTask(with: req, completion: { result in
			post {
				switch result {
				case .success(let data):
					completion(.success(data))
				case .failure(let status, let data):
					print("Failed: status: \(status)")
					print("data:", String(decoding: data, as: UTF8.self))
					completion(.error(Errors.text(String(decoding: data, as: UTF8.self))))
				case .error(let error):
					print("\(#function) error, \(error)")
					completion(.error(error))
				}
			}
		}).resume()
	}
	
	enum EndPoint: String {
		case login = "/login",
			 logout = "/logout",
			 lobbyPlayers = "/lobby/players",
			 chat = "/lobby/chat",
			 invite = "/lobby/invite",
			 flag = "/game/flag",
			 trap = "/game/trap",
			 random = "/game/random",
			 ready = "/game/ready",
			 move = "/game/move",
			 draw = "/game/draw",
			 forfeit = "/game/forfeit",
			 newGame = "/game/new"
	}
}

struct SocketMessageType: Decodable {
	let type: String
}

enum LobbyMsgType: String {
	case newUser = "new_user",
		 userLeft = "user_left",
		 newChatMsg = "msg",
		 invite = "invite",
		 answer = "answer"
	
	static func from(data: Data) -> LobbyMsgType? {
		guard let type: SocketMessageType = try? .from(json: data) else { return nil }
		return LobbyMsgType(rawValue: type.type)
	}
}

enum GameMsgType: String {
	case opponentReady = "opponent ready"
	case move = "move"
	case draw = "draw"
	case newGame = "new_game"
	case newGameAnswer = "new_game_answer"
	
	static func from(data: Data) -> GameMsgType? {
		guard let type: SocketMessageType = try? .from(json: data) else { return nil }
		return GameMsgType(rawValue: type.type)
	}
}

enum Errors: Error {
	case text(String)
}

enum Result<Type> {
	case success(Type)
	case error(Error)
}
