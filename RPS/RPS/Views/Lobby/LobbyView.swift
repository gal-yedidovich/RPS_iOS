//
//  LobbyView.swift
//  RPS
//
//  Created by Gal Yedidovich on 19/09/2020.
//

import SwiftUI
import BasicExtensions
import Network

struct LobbyView: View {
	@ObservedObject var model: LobbyModel
	
	var body: some View {
		if let name = model.name {
			if let token = model.token {
				TabView {
					PlayersView(model: model)
						.onAppear {
							requestLobby(token: token)
						}
						.tabItem {
							Text("Lobby")
							Image(systemName: "person.3.fill")
						}
					
					ChatView(token: token, messages: $model.messages)
						.tabItem {
							Text("Chat")
							Image(systemName: "bubble.left.fill")
						}
				}.alert(isPresented: $model.showInvitation, content: invitationAlert)
			} else {
				ProgressView()
					.onAppear {
						HttpClient.Lobby.send(to: .login, body: ["name": name]) { (result: Result<LoginDto>) in
							
							if case let .success(login) = result {
								withAnimation {
									model.token = login.token
									Global.token = login.token
								}
								NetworkClient.Lobby.connect(with: login.token)
							}
						}
					}
			}
		} else {
			LoginView(token: $model.token, name: $model.name)
		}
	}
	
	func invitationAlert() -> Alert {
		return Alert(
			title: Text("Invited"),
			message: Text("You are invited to play with \(model.invitation!.sender_name). Do you want to play?"),
			primaryButton: .default(Text("Yes"), action: {
				HttpClient.Lobby.send(to: .invite, body: AnswerDto(invitation: model.invitation!, accept: true)) { result in
					if case .success = result {
						GameModel.instance.gameId = model.invitation!.game_id
					}
				}
			}),
			secondaryButton: .cancel {
				let json = AnswerDto(invitation: model.invitation!, accept: false)
				HttpClient.Lobby.send(to: .invite, body: json) { _ in }
			})
	}
	
	func requestLobby(token: Int) {
		HttpClient.Lobby.send(to: .lobbyPlayers, body: ["token": token]) { (result: Result<LobbyPlayersDto>) in
			if case let .success(lobby) = result {
				model.lobbyPlayers = lobby.player_list
			}
		}
	}
}

struct LobbyView_Previews: PreviewProvider {
	static var previews: some View {
		LobbyView(model: .instance)
	}
}
