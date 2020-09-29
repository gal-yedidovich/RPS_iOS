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
	
	var body: some View {
		
		ZStack {
			VStack(spacing: 30) {
				BoardView(board: model.board, onClick: model.onClick)
				
				VStack {
					Text(model.message)
						.foregroundColor(.secondary)
					
					HStack {
						if model.showRandomBtn {
							Button(action: model.randomRPS) {
								Text("Random RPS")
							}
							.padding(10)
							.background(Color.blue)
							.foregroundColor(.white)
							.cornerRadius(10)
						}
						
						Spacer()
						
						if model.showNextBtn {
							Button {
								model.next()
							} label: {
								Text(model.isGameOver ? "New Game" :  "Next")
							}
							.padding(10)
							.background(Color.blue)
							.foregroundColor(.white)
							.cornerRadius(10)
						}
					}.padding(.horizontal)
					
					if model.loading {
						ProgressView()
					}
					
					Spacer()
				}
			}
			
			if model.draw.showDraw {
				DrawView(model: GameModel.instance, draw: $model.draw)
			}
		}
		.alert(item: $model.activeAlert, content: { alert in
			switch model.activeAlert {
			case .refusedInvite:
				return Alert(title: Text("Opponent refused to play again."), dismissButton: .default(Text("OK"), action: {
					model.finish()
				}))
			default:
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
			}
			
		})
		//		.alert(isPresented: $model.showOppnentInviteNewGame, content: {
		//			let handler = { (accept: Bool) in
		//				let body = SendNewGameAnswerDto(accept: accept, gameId: model.gameId)
		//				HttpClient.Game.send(to: .newGame, body: body) { _ in }
		//			}
		//
		//			return Alert(title: Text("Opponent wants play again."), message: nil,
		//						 primaryButton: .default(Text("Yes"), action: {
		//							handler(true)
		//							model.resetGame()
		//						 }), secondaryButton: .cancel({
		//							handler(false)
		//							model.finish()
		//						}))
		//		})
		//		.alert(isPresented: $model.showOpponentRefusedNewGame) {
		//			Alert(title: Text("Opponent refused to play again."), dismissButton: .default(Text("OK"), action: {
		//				model.finish()
		//			}))
		//		}
	}
}

struct GameView_Previews: PreviewProvider {
	static var previews: some View {
		GameView(model: GameModel.instance)
	}
}
