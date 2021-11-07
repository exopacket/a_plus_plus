//
//  ViewController.swift
//  a++_app
//
//  Created by Ryan Fitzgerald on 11/2/21.
//

import UIKit
import CryptoSwift

class ViewController: UIViewController {

    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var pinLabel: UILabel!
    @IBOutlet weak var pinEntry: UITextField!
    
    private var multipeerSession: LoginMultipeerSession!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinEntry.becomeFirstResponder()
        
    }

    @IBAction func btnPress(_ sender: Any) {
    
        if(loginButton.titleLabel?.text == "Start Searching") {
            
            pinEntry.endEditing(true)
            pinEntry.isEnabled = false
            
            let a: Int? = Int(pinEntry.text!)!
            
            multipeerSession = LoginMultipeerSession.init()
            multipeerSession.startMultipeer(seed: a!, view: self)
            
            loginButton.isHidden = true
            
            mainLabel.text = "Waiting on MacBook connection..."
            
        } else if(loginButton.titleLabel?.text == "Log In") {
            
            do {
                
                let parts = multipeerSession.getK(i: 777).split(separator: ":")
                
                let keyHex = "0x" + String(parts[2])
                let keyBytes = Array<UInt8>(hex: keyHex)
                
                let aes = try AES(key: keyBytes, blockMode: ECB(), padding: .pkcs7)
                
                let message = Data(try aes.encrypt("login_action".bytes)).toHexString()
                let iphone = Data(try aes.encrypt(String(parts[1]).bytes)).toHexString()
                let macbook = Data(try aes.encrypt(String(parts[0]).bytes)).toHexString()
                
                let dt = Data(try aes.encrypt(String(getTodayString()).bytes)).toHexString()
                
                multipeerSession.send(message: message, i: iphone, m: macbook, t: dt)
                
            } catch {
                
            }
        }
    
    }
    
    func getTodayString() -> String{

        let date = Date()

        return String(date.timeIntervalSince1970)

    }
    
}

