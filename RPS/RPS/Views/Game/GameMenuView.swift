//
//  GameMenuView.swift
//  RPS
//
//  Created by Gal Yedidovich on 08/10/2020.
//

import SwiftUI

struct GameMenuView: View {
	@ObservedObject var model: GameModel
	
	var body: some View {
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
		}
	}
}

struct GameMenuView_Previews: PreviewProvider {
    static var previews: some View {
		GameMenuView(model: .instance)
    }
}
