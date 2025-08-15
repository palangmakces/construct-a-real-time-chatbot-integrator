import Foundation
import SocketIO
import SwiftJWT

class RealTimeChatBotIntegrator {
    let socket: SocketIOClient
    let jwt: String
    let botToken: String
    let chatBotUrl: String
    
    init(botToken: String, chatBotUrl: String) {
        self.botToken = botToken
        self.chatBotUrl = chatBotUrl
        self.socket = SocketIOClient(socketURL: URL(string: "\(chatBotUrl)/socket.io")!)
        self.jwt = generateJWTToken()
        setupSocket()
    }
    
    func generateJWTToken() -> String {
        let header = ["typ": "JWT", "alg": "HS256"]
        let payload = ["iss": "swift-rt-chat-bot", "iat": Int(Date().timeIntervalSince1970)]
        let jwtHeader = header.jsonEncodedString()
        let jwtPayload = payload.jsonEncodedString()
        let jwtSignature = "\(jwtHeader).\(jwtPayload)".hmac(algorithm: .sha256, key: botToken)
        return "\(jwtHeader).\(jwtPayload).\(jwtSignature)"
    }
    
    func setupSocket() {
        socket.emit("authenticate", with: ["token": jwt])
        socket.on(" authenticated") { [weak self] data, ack in
            print("Authenticated successfully!")
            self?.listenForMessages()
        }
        socket.on("error") { [weak self] data, ack in
            print("Error: \(data)")
        }
        socket.connect()
    }
    
    func listenForMessages() {
        socket.on("message") { [weak self] data, ack in
            if let message = data[0] as? [String: Any] {
                print("Received message: \(message["text"] ?? "")")
                self?.processMessage(message: message)
            }
        }
    }
    
    func processMessage(message: [String: Any]) {
        // TO DO: Implement chat bot logic here
        // Send response back to the user
        sendMessage(text: "Hello! I'm a chatbot!")
    }
    
    func sendMessage(text: String) {
        socket.emit("message", with: ["text": text])
    }
}

extension Dictionary {
    func jsonEncodedString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(data: jsonData, encoding: .utf8)!
        } catch {
            return ""
        }
    }
}

extension String {
    func hmac(algorithm: CryptoAlgorithm, key: String) -> String {
        let crypto = HMAC(key: key, algorithm: algorithm)
        return crypto.encode(self)!
    }
}

enum CryptoAlgorithm {
    case sha256
}

class HMAC {
    let key: String
    let algorithm: CryptoAlgorithm
    
    init(key: String, algorithm: CryptoAlgorithm) {
        self.key = key
        self.algorithm = algorithm
    }
    
    func encode(_ message: String) -> String? {
        guard let messageData = message.data(using: .utf8),
              let keyData = key.data(using: .utf8) else {
            return nil
        }
        
        var hmacData = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        
        switch algorithm {
        case .sha256:
            CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), keyData.bytes, keyData.count, messageData.bytes, messageData.count, &hmacData)
        }
        
        return hmacData.map { String(format: "%02hhx", $0) }.joined()
    }
}