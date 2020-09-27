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
								Text("Next")
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
				DrawView(draw: $model.draw)
			}
		}
	}
}

struct GameView_Previews: PreviewProvider {
	static var previews: some View {
		GameView(model: GameModel.instance)
	}
}
