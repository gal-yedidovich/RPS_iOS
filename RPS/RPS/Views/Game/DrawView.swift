//
//  DrawView.swift
//  RPS
//
//  Created by Gal Yedidovich on 27/09/2020.
//

import SwiftUI
import BasicExtensions

struct DrawView: View {
	let model: GameModel
	@Binding var draw: DrawModel
	
	var body: some View {
		BasicAlertView {
			VStack {
				HStack {
					ForEach([PawnType.Rock, .Paper, .Scissors]) { type in
						if draw.opponentSelection == type {
							drawButton(type: type, isMine: false)
						} else {
							(draw.hidingOpponentSelection ? Color.blue : Color.clear)
								.frame(width: 100, height: 100)
						}
					}
				}
				
				if draw.selection != .None && draw.hidingOpponentSelection {
					ProgressView()
						.frame(width: 30, height: 30)
				} else {
					Color.clear
						.frame(width: 30, height: 23)
				}
				
				HStack {
					drawButton(type: .Rock)
					drawButton(type: .Paper)
					drawButton(type: .Scissors)
				}
			}
		}
	}
	
	func drawButton(type: PawnType, isMine: Bool = true) -> some View {
		Button {
			draw.selection = type
			model.sendDrawDecision(type: type)
		} label: {
			Image(systemName: type.rawValue)
				.resizable()
				.scaledToFit()
				.padding()
				.foregroundColor(isMine ? .red : .blue)
				.frame(width: 100, height: 100)
				.background(draw.selection == type && isMine ? Color.green : .clear)
		}
		.disabled(!isMine || draw.selection != .None)
	}
}

struct DrawView_Previews: PreviewProvider {
	static var previews: some View {
		DrawView(model: .instance, draw: Binding.constant(DrawModel()))
	}
}

