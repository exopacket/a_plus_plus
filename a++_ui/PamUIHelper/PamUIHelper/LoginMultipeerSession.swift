//
//  LoginMultipeerSession.swift
//  PamUIHelper
//
//  Created by Ryan Fitzgerald on 11/2/21.
//

import MultipeerConnectivity
import os
import GameplayKit
import CryptoSwift

class LoginMultipeerSession: NSObject, ObservableObject {
    
    private let BASE64_KEY: String = "l3bXFOMHgxlF3uV7ImHtxBo48gd8pBoDjG3OBvFihJ0="
    
    private let serviceType = "mblogin"
    private var myPeerId: MCPeerID!
    private var otherPeerId: MCPeerID!
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var session: MCSession!
    private let log = Logger()
    var connectedPeers: [MCPeerID] = []
    private var view: SignIn!
    private var messageKey: String = ""
    private var messageKeyHash: String!

    override init() {
        
        super.init()
        
    }

    public func startMultipeer(seed: Int, view: SignIn) {
        
        self.view = view
        
        do {
            myPeerId = try MCPeerID(displayName: getPeerIds(id: 1, seed: UInt64(seed)))
            otherPeerId = try MCPeerID(displayName: getPeerIds(id: 2, seed: UInt64(seed)))
            messageKey = try getPeerIds(id: 3, seed: UInt64(seed))
            messageKeyHash = try getPeerIds(id: 4, seed: UInt64(seed))
        } catch {
            
        }
        
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
        
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
    }
    
    fileprivate func getPeerIds(id: Int, seed: UInt64) throws -> String{
        
        let keyStr = BASE64_KEY
        let key = Data(base64Encoded: keyStr)!
        
        let strToHash = String(seed * seed + 41898)
        let bytes = strToHash.bytes
        
        let finalHash = try HMAC(key: key.bytes, variant: .sha512).authenticate(bytes)
        
        let _strToHash = String(self.messageKey)
        let _bytes = _strToHash.bytes
        
        let _finalHash = try HMAC(key: key.bytes, variant: HMAC.Variant.sha3(.sha512)).authenticate(_bytes)

        let finalHashHex = Data(String(finalHash.toHexString()).bytes).sha512().toHexString()
        
        let start = finalHashHex.index(finalHashHex.startIndex, offsetBy: 7)
        let end = finalHashHex.index(finalHashHex.startIndex, offsetBy: 19)
        let range = start..<end
        
        let _start = finalHashHex.index(finalHashHex.startIndex, offsetBy: 26)
        let _end = finalHashHex.index(finalHashHex.startIndex, offsetBy: 38)
        let _range = _start..<_end
        
        let __start = finalHashHex.index(finalHashHex.startIndex, offsetBy: 9)
        let __end = finalHashHex.index(finalHashHex.startIndex, offsetBy: 73)
        let __range = __start..<__end

        let macbook = String(finalHashHex[range])
        let phone = String(finalHashHex[_range])
        let encKey = String(finalHashHex[__range])
        
        if(id == 1) {
            return macbook
        } else if(id == 2) {
            return phone
        } else if(id == 3) {
            return encKey;
        } else if(id == 4) {
            return _finalHash.toHexString()
        }
        
        return ""
        
    }
    
}

extension LoginMultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
            if(peerID.displayName == otherPeerId.displayName) {
                invitationHandler(true, session)
            }
        }
}

extension LoginMultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    }

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if(peerID.displayName == otherPeerId.displayName) {
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }
}

extension LoginMultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if(peerID.displayName == otherPeerId.displayName && state == .connected) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            self.view.alertText.stringValue = "Connected to iPhone! Awaiting log in..."
            self.view.alertText.textColor =
            self.view.hiddenLabel.textColor
        }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        if(peerID.displayName == otherPeerId.displayName) {
        
            guard let msg = try? JSONDecoder().decode(MessageModel.self, from: data) else {
            
                return }
          DispatchQueue.main.async {
              
              do {
                  
                  let keyHex = "0x" + self.messageKey
                  let keyBytes = Array<UInt8>(hex: keyHex)
                  
                  let messageHex = "0x" + msg.message
                  let messageBytes = Array<UInt8>(hex: messageHex)
                  
                  let iphoneHex = "0x" + msg.i
                  let iphoneBytes = Array<UInt8>(hex: iphoneHex)
                  
                  let macbookHex = "0x" + msg.m
                  let macbookBytes = Array<UInt8>(hex: macbookHex)
                  
                  let dtHex = "0x" + msg.t
                  let dtBytes = Array<UInt8>(hex: dtHex)
                  
                  let aes = try AES(key: keyBytes, blockMode: ECB(), padding: .pkcs7)
                  
                  let message = String(bytes: Data(try aes.decrypt(messageBytes)).bytes, encoding: .utf8)
                  let iphone = String(bytes: Data(try aes.decrypt(iphoneBytes)).bytes, encoding: .utf8)
                  let macbook = String(bytes: Data(try aes.decrypt(macbookBytes)).bytes, encoding: .utf8)
                  let dt = String(bytes: Data(try aes.decrypt(dtBytes)).bytes, encoding: .utf8)
               
                  if(msg.n == "1" && iphone == self.otherPeerId.displayName && macbook == self.myPeerId.displayName && message == "login_action") {
                      
                      let date = Date(timeIntervalSince1970: Double(dt!)!)
                      
                      let now = Date()
                      
                      let difference = Calendar.current.dateComponents([.hour, .minute, .second], from: date, to: now)
                      
                      let seconds = (difference.hour! * 60 * 60) + (difference.minute! * 60)  + difference.second!
                      
                      if(seconds <= 1) {
                          
                          self.view.alertText.textColor = self.view.hiddenLabel.textColor
                          self.view.alertText.stringValue = "Bluetooth authentication completed!"
                          
                          if(self.view.checkHardwareSuccess()) {
                          
                              exit(21)
                              
                          } else {
                              
                              self.lastHardwareCheck()
                              
                          }
                          
                      } else {
                          
                          self.view.alertText.stringValue = "Authentication Error! Please try again."
                          self.view.alertText.textColor = self.view.redLabel.textColor
                          
                      }
                      
                      
                  } else {
                      
                      self.view.alertText.stringValue = "Authentication Error! Please try again."
                      self.view.alertText.textColor = self.view.redLabel.textColor
                      
                  }
                  
              } catch {
                  
              }
              
          }
            
        }
        
    }
    
    fileprivate func lastHardwareCheck() {
        
        DispatchQueue.global().async {
        
            let time:DispatchTime = DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(500))
            
            DispatchQueue.main.asyncAfter(deadline: time) {
            
                if(!self.view.checkHardwareSuccess()) {
                    self.lastHardwareCheck()
                } else {
                    self.view.alertText.textColor = self.view.hiddenLabel.textColor
                    self.view.alertText.stringValue = "Bluetooth authentication completed!"
                    
                    if(self.view.checkHardwareSuccess()) {
                    
                        exit(21)
                        
                    }
                }
                
            }
            
        }
        
    }

    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }

    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }

    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func send(data: String) {

        if !session.connectedPeers.isEmpty {
            do {
                let messageDictionary: [String: String] = ["message": data];
                let messageData = try JSONEncoder().encode(messageDictionary)
                
                try session.send(messageData, toPeers: [otherPeerId], with: .unreliable)
            } catch {
                
            }
        }
    }
    
    struct MessageModel: Codable {
        
        var message: String
        var i: String
        var m: String
        var t: String
        var n: String
        
        
        
    }
    
}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}

class SeededGenerator: RandomNumberGenerator {
    let seed: UInt64
    private let generator: GKMersenneTwisterRandomSource
    convenience init() {
        self.init(seed: 0)
    }
    init(seed: UInt64) {
        self.seed = seed
        generator = GKMersenneTwisterRandomSource(seed: seed)
    }

    func next<T>(upperBound: T) -> T where T : FixedWidthInteger, T : UnsignedInteger {
        return T(abs(generator.nextInt(upperBound: Int(upperBound))))
    }
    func next<T>() -> T where T : FixedWidthInteger, T : UnsignedInteger {
        return T(abs(generator.nextInt()))
    }
    func next() -> UInt64 {
        return UInt64(abs(generator.nextInt(upperBound: 8999)) + 1000)
    }
}
