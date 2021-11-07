//
//  LoginMultipeerSession.swift
//  a++_app
//
//  Created by Ryan Fitzgerald on 11/2/21.
//

import MultipeerConnectivity
import os
import CryptoSwift
import GameplayKit

class LoginMultipeerSession: NSObject, ObservableObject {
    
    //constants
    //base64 key (32)
    private let BASE64_KEY: String = "l3bXFOMHgxlF3uV7ImHtxBo48gd8pBoDjG3OBvFihJ0="
    
    private let serviceType = "mblogin"
    private var myPeerId: MCPeerID!
    private var otherPeerId: MCPeerID!
    private var serviceBrowser: MCNearbyServiceBrowser!
    private var session: MCSession!
    private let log = Logger()
    var connectedPeers: [MCPeerID] = []
    private var randomSeed: Int!
    private var view: ViewController!
    private var shouldRecconnect: Bool = true
    private var messageKey: String = ""
    private var messageKeyHash: String!
    
    override init() {
        
        super.init()
    
        
    }
    
    public func startMultipeer(seed: Int, view: ViewController) {
        
        self.view = view
        
        do {
            myPeerId = try MCPeerID(displayName: getPeerIds(id: 2, seed: UInt64(seed)))
            otherPeerId = try MCPeerID(displayName: getPeerIds(id: 1, seed: UInt64(seed)))
            messageKey = try getPeerIds(id: 3, seed: UInt64(seed))
            messageKeyHash = try getPeerIds(id: 4, seed: UInt64(seed))
        } catch {
            
        }
        
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        
        session.delegate = self
        serviceBrowser.delegate = self
        serviceBrowser.startBrowsingForPeers()
        
    }
    
    public func getK(i: Int) -> String {
        
        if(i == 777) {
            return otherPeerId.displayName + ":" + myPeerId.displayName + ":" + messageKey
        }
        
        return ""
        
    }
    
    fileprivate func getPeerIds(id: Int, seed: UInt64) throws -> String {
        
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

    deinit {
        serviceBrowser.stopBrowsingForPeers()
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
        
        if(peerID.displayName == otherPeerId.displayName) {
            exit(0)
        }
        
    }
}

extension LoginMultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if(peerID.displayName == otherPeerId.displayName && state == .connected) {
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
            self.view.loginButton.setTitle("Log In", for: .normal)
            self.view.loginButton.isHidden = false
            self.view.mainLabel.text = "Connected to MacBook!"
        
       }
    } else if(peerID.displayName == otherPeerId.displayName && state == .notConnected) {
        
        if(shouldRecconnect) {
            
            self.serviceBrowser.invitePeer(otherPeerId, to: session, withContext: nil, timeout: 10)
            
            DispatchQueue.main.async {
                self.view.loginButton.isHidden = true
                self.view.mainLabel.text = "Attempting reconnection..."
            }
            
        }
        
    }
        
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        if(peerID.displayName == otherPeerId.displayName) {
        
        guard let msg = try? JSONDecoder()
            .decode(MessageModel.self, from: data) else { return }
          DispatchQueue.main.async {
              
              if(msg.message == self.messageKeyHash) {
                  
                  exit(0)
                  
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
    
    func send(message: String, i: String, m: String, t: String) {
        
        if !session.connectedPeers.isEmpty {
            
            do {
                let messageDictionary: [String: String] = ["message": message, "i": i, "m": m, "t": t, "n": String(session.connectedPeers.count)];
                let messageData = try JSONEncoder().encode(messageDictionary)
                
                try session.send(messageData, toPeers: self.session.connectedPeers, with: .reliable)
            } catch {
            }
        }
        
    }
    
    struct MessageModel: Codable {
        
        var message: String
        
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
        return UInt64(abs(generator.nextInt(upperBound: 899999)) + 100000)
    }
}
