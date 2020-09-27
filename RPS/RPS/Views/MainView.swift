//
//  MainView.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import SwiftUI

struct Shared {
	static var token: Int!
}

struct MainView: View {
	@ObservedObject var gameModel = GameModel.instance
	@ObservedObject var lobbyModel = LobbyModel.instance
	
    var body: some View {
		if gameModel.gameId != -1 {
			GameView(model: gameModel)
		} else {
			LobbyView(model: lobbyModel)
				.sheet(isPresented: $lobbyModel.invitationPending, content: {
					VStack {
						Text("Waiting for Bubu...")
						ProgressView()
					}
				})
		}
	}
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
