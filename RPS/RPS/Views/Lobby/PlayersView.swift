//
//  LobbyView.swift
//  RPS
//
//  Created by Gal Yedidovich on 19/09/2020.
//

import SwiftUI
//import BasicExtensions

struct PlayersView: View {
	@ObservedObject var model: LobbyModel
	@State var selected: LobbyPlayer? = nil
	
	var body: some View {
		NavigationView {
			List(model.lobbyPlayers) { player in
				Button(player.name) {
					selected = player
					sendInvatation(invitee: player)
				}
			}
			.navigationTitle("Lobby")
		}
	}
	
	func sendInvatation(invitee: LobbyPlayer)  {
		let invitation = SendInvatationDto(sender_token: model.token!, target_token: invitee.token, req_type: "invite", name: model.name!)
		HttpClient.Lobby.send(to: .invite, body: invitation) { (result: Result<InvitationResponseDto>) in
			if case .success = result {
				model.invitationPending = true
			}
//			post {
//				switch result {
//				case .success(_):
//					model.invitationPending = true
//				case .failure(_, _): break
//				case .error(let error): print("\(#function) error, \(error)")
//				}
//			}
		}
	}
}

struct PlayersView_Previews: PreviewProvider {
	static var previews: some View {
		PlayersView(model: LobbyModel.instance)
	}
}
