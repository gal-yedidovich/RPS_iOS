//
//  DrawView.swift
//  RPS
//
//  Created by Gal Yedidovich on 27/09/2020.
//

import SwiftUI
import BasicExtensions

struct DrawView: View {
	@Binding var draw: DrawModel
	
	var body: some View {
		ZStack {
			Color(UIColor.black.withAlphaComponent(0.5))
			
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
			.padding()
			.background(Color(UIColor.darkGray))
			.cornerRadius(10)
			.animation(.default)
		}
		.edgesIgnoringSafeArea(.all)
		.id("drawAlert")
	}
	
	func drawButton(type: PawnType, isMine: Bool = true) -> some View {
		Button {
			draw.selection = type
			sendDraw(type: type)
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
	
	func sendDraw(type: PawnType) {
		let body = DrawDecision(decision: type.string)
		
		HttpClient.Game.send(to: .draw, body: body) { result in
			guard case let .success(payload) = result,
				  let drawResult: DrawResult = try? .from(json: payload) else { return }
			
			withAnimation() {
				draw.hidingOpponentSelection = false
			}
			
			post(delay: 0.5) {
				withAnimation() {
					draw.opponentSelection = .from(string: drawResult.opponent)
				}
			}
			
			post(delay: 1.5) {
				withAnimation() {
					draw.showDraw = false
					draw.result = drawResult.result
				}
			}
			
		}
	}
}

struct DrawView_Previews: PreviewProvider {
	static var previews: some View {
		DrawView(draw: Binding.constant(DrawModel()))
	}
}

