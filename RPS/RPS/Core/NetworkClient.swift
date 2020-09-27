//
//  NetworkClient.swift
//  RPS
//
//  Created by Gal Yedidovich on 19/09/2020.
//

import Foundation
import BasicExtensions

class NetworkClient {
	
	static let Lobby = NetworkClient(name: "Lobby", port: 15001)
	static let Game = NetworkClient(name: "Game", port: 15002)
	
	private let name: String
	private let port: UInt32
	var callback: (Data)->() = { _ in }
	
	private var inputStream: InputStream!
	private var outputStream: OutputStream!
	
	init(name: String, port: UInt32) {
		self.name = name
		self.port = port
	}
	
	func connect(with token: Int) {
		if inputStream != nil { return }
		
		async {
			var readStream: Unmanaged<CFReadStream>?
			var writeStream: Unmanaged<CFWriteStream>?
			CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, "127.0.0.1" as CFString, self.port, &readStream, &writeStream)
			
			self.inputStream = readStream!.takeRetainedValue()
			self.outputStream = writeStream!.takeRetainedValue()
			self.inputStream.schedule(in: .current, forMode: .common)
			self.outputStream.schedule(in: .current, forMode: .common)
			self.inputStream.open()
			self.outputStream.open()
			
			//send Token
			self.send(data: withUnsafeBytes(of: token, { Data($0) }))
			print("connected on Lobby Socket")
			
			//listen to server
			self.listen()
		}
	}
	
	func listen() {
		async {
			while true {
				//read message size
				let sizeBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
				let numberOfBytesRead = self.inputStream.read(sizeBuffer, maxLength: 4)
				if numberOfBytesRead != 4 {
					print("error reading the size of message")
					break
				}
				
				let sizeData = Data(bytes: sizeBuffer, count: 4)
				let size = Int(sizeData.withUnsafeBytes({ $0.load(as: Int32.self) }))

				//read message
				let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
				let _ = self.inputStream.read(buffer, maxLength: size)
				let data = Data(bytes: buffer, count: size)
				
				//ignore heartbeats
				if let heartbeat: [String: String] = try? .from(json: data), heartbeat["type"] == "heartbeat" {
					continue
				}
				
				print("received data: \(String(decoding: data, as: UTF8.self))")
				post {
					self.callback(data)
				}
			}
		}
	}
	
	func send(data: Data) {
		self.outputStream.write(data: data)
	}
}

extension OutputStream {
	func write(data: Data) {
		data.withUnsafeBytes {
			let pointer = $0.baseAddress!.assumingMemoryBound(to: UInt8.self)
			write(pointer, maxLength: data.count)
		}
	}
}
