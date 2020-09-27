//
//  ChatMessageView.swift
//  RPS
//
//  Created by Gal Yedidovich on 21/09/2020.
//

import SwiftUI

struct Message: Identifiable, Hashable {
	let id = UUID()
	
	let text: String
	let sender: String
	let isMe: Bool
	let date: Date
}

struct ChatMessageView: View {
	var message: Message
	
	var body: some View {
		VStack(alignment: .leading, spacing: 5) {
			if !message.isMe {
				Text(message.sender)
					.font(.caption)
					.padding(.leading, 4)
			}
			
			HStack {
				if message.isMe {
					Spacer()
				}
				
				VStack(alignment: .trailing, spacing: 1) {
					Text(message.text)
						.padding(10)
						.foregroundColor(message.isMe ? Color.white : Color.black)
						.background(message.isMe ? Color.blue : Color(.secondarySystemFill))
						.cornerRadius(10)
					
					Text(dateStr)
						.font(.caption)
						.foregroundColor(Color.secondary)
						.padding(.trailing, 4)
				}
				
				if !message.isMe {
					Spacer()
				}
			}
		}
		.padding([.horizontal], 10)
		.padding([.vertical], 4)
	}
	
	var dateStr: String {
		DateFormatter(format: "HH:mm").string(from: message.date)
	}
}

struct ChatMessageView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ChatMessageView(message: Message(text: "Bubu is the king", sender: "Bubu", isMe: true, date: Date()))
			ChatMessageView(message: Message(text: "Bubu is the king", sender: "Gal", isMe: false, date: Date()))
		}
	}
}
