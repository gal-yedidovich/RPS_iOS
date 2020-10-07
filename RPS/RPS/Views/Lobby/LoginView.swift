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
		BasicAlertView {
			VStack(alignment: .center) {
				TextField("Enter Your name", text: $loginName, onCommit: requestLogin)
					.padding()
				Button("Login", action: requestLogin)
					.disabled(requesting)
					.padding()
			}
		}
    }
	
	func requestLogin() {
		UserDefaults.standard.set(loginName, forKey: "name")
		withAnimation {
			name = loginName
		}
	}
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
		LoginView(token: .constant(0), name: .constant(""))
    }
}
