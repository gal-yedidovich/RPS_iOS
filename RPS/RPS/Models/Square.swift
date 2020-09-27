//
//  Square.swift
//  RPS
//
//  Created by Gal Yedidovich on 28/09/2020.
//

import Foundation
import SwiftUI

struct Square: Identifiable {
	let id = UUID()
	var position: (row: Int, col: Int)
	var isMine: Bool
	var type: PawnType
	var highlighted = false
	var hidden = false
}

enum PawnType: String, Identifiable {
	case Rock = "hexagon.fill",
		 Paper = "doc.fill",
		 Scissors = "scissors",
		 Flag = "flag",
		 Trap = "xmark.seal",
		 Hidden = " ",
		 None = ""
	
	var id: String { rawValue }
	
	static func from(string value: String) -> PawnType {
		switch value {
		case "rock": return .Rock
		case "paper": return .Paper
		case "scissors": return .Scissors
		case "trap": return .Trap
		case "flag": return .Flag
		default: return .None
		}
	}
	
	var string: String {
		switch self {
		case .Rock: return "rock"
		case .Paper: return "paper"
		default: return "scissors"
		}
	}
}
