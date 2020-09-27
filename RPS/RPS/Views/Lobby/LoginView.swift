//
//  LoginView.swift
//  RPS
//
//  Created by Gal Yedidovich on 19/09/2020.
//

import SwiftUI
import BasicExtensions

struct LoginView: View {
	@Binding var token: Int?
	@Binding var name: String?
	@State var loginName: String = ""
	@State private var requesting = false
	
    var body: some View {
		HStack {
			TextField("Enter Your name", text: $loginName, onCommit: requestLogin)
				.padding()
			Button("Login", action: requestLogin)
				.disabled(requesting)
		}.padding()
    }
	
	func requestLogin() {
//		guard !requesting else { return }
		
		UserDefaults.standard.set(loginName, forKey: "name")
		withAnimation {
			name = loginName
		}
//		requesting = true
//		HttpClient.login(name: loginName) { result in
//			post {
//				requesting = false
//				switch result {
//				case .success(let login):
//					withAnimation {
//						name = loginName
//						token = login.token
//					}
//
//					NetworkClient.Lobby.connect(with: login.token)
//				case .failure(_, _): break
//				case .error(let error): print("\(#function) error, \(error)")
//				}
//			}
//		}
	}
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
		LoginView(token: Binding.constant(0), name: Binding.constant(""))
    }
}
