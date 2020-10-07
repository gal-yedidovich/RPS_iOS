//
//  ChatView.swift
//  RPS
//
//  Created by Gal Yedidovich on 21/09/2020.
//

import SwiftUI
import BasicExtensions

struct ChatView: View {
	var token: Int
	@Binding var messages: [Message]
	@State var newMessage: String = ""
	
    var body: some View {
		VStack {
			ScrollView {
				LazyVStack {
					ForEach(messages) {
						ChatMessageView(message: $0)
					}
				}
			}
			
			HStack {
				TextField("Enter text", text: $newMessage, onCommit: send)
					.disabled(newMessage.isEmpty)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.padding([.leading, .vertical])
				
				Button(action: send, label: {
					Image(systemName: "paperplane")
				})
				.padding()
				.padding(.trailing, 8)
			}
		}
    }
	
	func send() {
		let date = Date()
		let body = NewMessageDto(token: token, time: Int64(date.timeIntervalSince1970), msg: newMessage)
		HttpClient.Lobby.send(to: .chat, body: body) { result in
			if case .success = result {
				messages += [Message(text: newMessage, sender: "", isMe: true, date: date)]
				newMessage = ""
			}
		}
	}
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
		ChatView(token: 0, messages: Binding.constant([
			Message(text: "Bubu is the king", sender: "Gal", isMe: true, date: Date()),
			Message(text: "Bubu is the king", sender: "Gal", isMe: false, date: Date()),
			Message(text: "Bubu is the king", sender: "Gal", isMe: true, date: Date()),
			Message(text: "Bubu is the king", sender: "Gal", isMe: true, date: Date()),
			Message(text: "Bubu is the king", sender: "Gal", isMe: true, date: Date()),
		]))
    }
}
