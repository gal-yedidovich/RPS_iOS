//
//  BasicAlertView.swift
//  RPS
//
//  Created by Gal Yedidovich on 08/10/2020.
//

import SwiftUI

struct BasicAlertView<Content>: View where Content : View {
	var content: Content
	
	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}
	
	var body: some View {
		ZStack {
			Color(UIColor.black.withAlphaComponent(0.5))
			
			content
				.padding()
				.background(Color(UIColor.darkGray))
				.cornerRadius(10)
				.padding()
				.frame(idealWidth: 300, maxWidth: 400)
		}
		.environment(\.colorScheme, .dark)
		.ignoresSafeArea()
	}
}

struct BasicAlert_Previews: PreviewProvider {
	static var previews: some View {
		BasicAlertView {
			Text("Bubu is the Alert King")
		}
	}
}
