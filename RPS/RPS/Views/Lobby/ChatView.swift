//
//  ChatView.swift
//  RPS
//
//  Created by Gal Yedidovich on 21/09/2020.
//

import SwiftUI
import BasicExtensions

class Testi: ObservableObject {
	@Published var testo = true
}

struct ChatView: View {
	var token: Int
	@Binding var messages: [Message] {
		didSet {
			test.testo.toggle()
		}
	}
	@State var newMessage: String = ""
	@StateObject var test = Testi()
	
    var body: some View {
		VStack {
			ScrollView {
				ScrollViewReader { scroll in
					LazyVStack {
						ForEach(messages) {
							ChatMessageView(message: $0)
						}
					}.onReceive(test.$testo, perform: { _ in
						if messages.count > 0 {
							scroll.scrollTo(messages.last!)
						}
					}).onAppear {
						if messages.count > 0 {
							scroll.scrollTo(messages.last!)
						}
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
				.padding(.trailing, 5)
			}
		}
    }
	
	func send() {
		test.testo.toggle()
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
