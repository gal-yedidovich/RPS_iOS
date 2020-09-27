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
		
		VStack(spacing: 30) {
			BoardView(board: model.board, onClick: model.onClick)
			
			VStack {
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
					
					Button {
						model.next()
					} label: {
						Text("Next")
					}
					.padding(10)
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(10)
				}.padding(.horizontal)
				
				Text(model.message)
					.foregroundColor(.secondary)
				
				if model.loading {
					ProgressView()
				}
				
				Spacer()
			}
		}
	}
}

struct GameView_Previews: PreviewProvider {
	static var previews: some View {
		GameView(model: GameModel.instance)
	}
}
