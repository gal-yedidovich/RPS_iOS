//
//  GameView.swift
//  RPS
//
//  Created by Gal Yedidovich on 22/09/2020.
//

import SwiftUI
import BasicExtensions

struct GameView: View {
	@ObservedObject var model: GameModel
	@Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
//	@Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
	
	var body: some View {
		NavigationView {
			ZStack {
				VStack(spacing: 30) {
					BoardView(board: model.board, onClick: model.onClick)
						.padding()
					
					GameMenuView(model: model)
						.frame(height: 150, alignment: .top)
				}
				
				if model.draw.showDraw {
					DrawView(model: model, draw: $model.draw)
				}
				
			}
			.navigationBarItems(leading: Button("Quit", action: {
				model.activeAlert = .quit
			}))
		}
		.alert(item: $model.activeAlert, content: { alert in
			switch model.activeAlert {
			case .refusedInvite:
				return Alert(title: Text("Opponent refused to play again."), dismissButton: .default(Text("OK"), action: model.finish))
			case .newGameInvite:
				let handler = { (accept: Bool) in
					let body = SendNewGameAnswerDto(accept: accept, gameId: model.gameId)
					HttpClient.Game.send(to: .newGame, body: body) { _ in }
				}
				
				return Alert(title: Text("Opponent wants play again."), message: nil,
							 primaryButton: .default(Text("Yes"), action: {
								handler(true)
								model.resetGame()
							 }), secondaryButton: .cancel({
								handler(false)
								model.finish()
							}))
			case .opponentQuit:
				return Alert(title: Text("Opponent forfeited the game"), dismissButton: .default(Text("Go Back"), action: {
					withAnimation { model.finish() }
				}))
			default:
				return Alert(title: Text("Are you sure you want to quit?"), primaryButton: .default(Text("Yes"), action: model.forfeit), secondaryButton: .cancel())
			}
		})
	}
}

struct GameView_Previews: PreviewProvider {
	static var previews: some View {
		GameView(model: .instance)
			.environment(\.colorScheme, .dark)
	}
}
