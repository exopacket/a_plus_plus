//
//  SignIn.swift
//  PamUIHelper
//
//  Created by Ryan Fitzgerald on 11/2/21.
//

import Cocoa
import Security.AuthorizationPlugin
import MultipeerConnectivity

class SignIn: NSWindowController {

    //constants
    private let IPHONE_UUID: String = ""
    
    var backgroundWindow: NSWindow!
    var effectWindow: NSWindow!
    @objc var visible = true
    var uiWindow: NSWindow!
    private var randomSeed: Int!

    @IBOutlet weak var hiddenLabel: NSTextField!
    @IBOutlet weak var mainView: NSView!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var alertText: NSTextField!
    @IBOutlet weak var bluetoothIcon: NSImageView!
    @IBOutlet weak var quitText: NSTextField!
    @IBOutlet weak var passwordStack: NSStackView!
    @IBOutlet weak var pinTextField: NSTextField!
    @IBOutlet weak var redLabel: NSTextField!
    @IBOutlet weak var hardwareCheckLabel: NSTextField!
    
    private var canExit: Bool = false
    
    var hardwareCheck: Bool!
    var hardwareCheckSuccess: Bool = false;
    
    var multipeerSession: LoginMultipeerSession!
    var connectedPeers: [MCPeerID] = []
    
    override func windowDidLoad() {
        
        super.windowDidLoad()
        
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let ns = calendar.component(.nanosecond, from: date)
        let seed = (hour * minutes) + 227 + seconds + ns
        
        let generator = SeededGenerator(seed: UInt64(seed))
        randomSeed = Int(generator.next())
        
        pinTextField.stringValue = String(randomSeed)
        
        loginApperance()
        createBackgroundWindow()
        
        username.stringValue = UserDefaults.standard.string(forKey: "uname") ?? ""
        
        let hardwareCheckStr = UserDefaults.standard.string(forKey: "hwcheck") ?? "";
        
        hardwareCheck = (hardwareCheckStr == "yes") ? true : false
        
        if(hardwareCheck) {
            hardwareCheckLabel.isHidden = false
            if(!checkHardware()) {
                hardwareCheckLabel.textColor = redLabel.textColor
                hardwareCheckLabel.stringValue = "Hardware check failed. Please connect iPhone."
                hardwareCheckSuccess = false
                
                delayedHardwareCheck()
                
            } else {
                hardwareCheckLabel.textColor = hiddenLabel.textColor
                hardwareCheckLabel.stringValue = "Hardware check completed successfully!"
                hardwareCheckSuccess = true
            }
        }
        
        username.becomeFirstResponder()
        beginCountdown()
        
        username.delegate = self
        
    }
    
    fileprivate func delayedHardwareCheck() {
        
        if(!hardwareCheckSuccess) {
            
            DispatchQueue.global().async {
            
                let time:DispatchTime = DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(500))
                
                DispatchQueue.main.asyncAfter(deadline: time) {
                
                    if(!self.checkHardware()) {
                        self.hardwareCheckLabel.textColor = self.redLabel.textColor
                        self.hardwareCheckLabel.stringValue = "Hardware check failed. Please connect iPhone."
                        self.hardwareCheckSuccess = false
                        
                        self.delayedHardwareCheck()
                        
                    } else {
                        self.hardwareCheckLabel.textColor = self.hiddenLabel.textColor
                        self.hardwareCheckLabel.stringValue = "Hardware check completed successfully!"
                        self.hardwareCheckSuccess = true
                    }
                    
                }
                
            }
        }
        
    }
    
    public func checkHardwareSuccess() -> Bool {
        
        return (!hardwareCheck) ? true : hardwareCheckSuccess
        
    }

    fileprivate func checkHardware() -> Bool {
        
        let output = shell("exec xcrun xctrace list devices")
        
        let lines = output.split(whereSeparator: \.isNewline)
        
        var foundDevices = false
        
        for line in lines {
    
            if(line == "== Devices ==") {
                foundDevices = true
                continue
            }
            
            if(foundDevices) {
                
                let parts = line.split(separator: "(")
                
                if(parts.count == 3) {
                    
                    let uuid = parts[3].replacingOccurrences(of: ")", with: "")
                    
                    if(uuid == IPHONE_UUID) {
                        return true;
                    } else {
                        continue;
                    }
                    
                }
                
            }
            
            if(line == "== Simulators ==") {
                break;
            }
            
            
        }
        
        return false
        
    }
    
    fileprivate func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
    fileprivate func beginCountdown() {
        
        alertText.stringValue = "sleeping for 10 seconds prior to login [10]"
        
        var countdownVal: Int = 10
        var timerInt: Int = 1;
        
        DispatchQueue.global().async {
            
            while(countdownVal > 0) {
                
                let timerVal = timerInt * 1000;
                timerInt+=1;
                countdownVal-=1;
                
                let val = countdownVal
                
                let time:DispatchTime = DispatchTime.now().advanced(by: DispatchTimeInterval.milliseconds(timerVal))
            
                DispatchQueue.main.asyncAfter(deadline: time) {
                
                    if(val == 0) {
                        self.alertText.stringValue = "attempting connection with device"
                        self.bluetoothIcon.isHidden = false
                        self.quitText.stringValue = "you may exit if neccesary // username << exit"
                        self.canExit = true
                
                        self.multipeerSession = LoginMultipeerSession()
                        self.multipeerSession.startMultipeer(seed: self.randomSeed, view: self)
                        
                    } else {
                        self.alertText.stringValue = "sleeping for 10 seconds prior to login [" + String(val) + "]"
                    }
                    
                }
                
            }
            
        }
        
    }
    
    

    fileprivate func createBackgroundWindow() {

        for screen in NSScreen.screens {
            let view = NSView()
            view.wantsLayer = true
            
            backgroundWindow = NSWindow(contentRect: screen.frame,
                                        styleMask: .fullSizeContentView,
                                        backing: .buffered,
                                        defer: true)
            
            backgroundWindow.backgroundColor = .black
            backgroundWindow.contentView = view
            backgroundWindow.makeKeyAndOrderFront(self)
            backgroundWindow.canBecomeVisibleWithoutLogin = true
            
        }
    }


    func loginTransition() {
        
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 1.0
            context.allowsImplicitAnimation = true
            self.window?.alphaValue = 0.0
            self.backgroundWindow.alphaValue = 0.0
            self.effectWindow.alphaValue = 0.0
        }, completionHandler: {
            self.window?.close()
            self.backgroundWindow.close()
            self.effectWindow.close()
            self.visible = false
        })
    }

    fileprivate func loginApperance() {
    
        
        self.window?.level = .screenSaver
        self.window?.orderFrontRegardless()

        self.window?.isOpaque = false
        self.window?.hasShadow = false
        self.window?.backgroundColor = .black
        
        self.window?.titlebarAppearsTransparent = true
        self.window?.isMovable = false
        self.window?.canBecomeVisibleWithoutLogin = true
        self.window?.center()

    }
    
    //TODO

    @IBAction func signInClick(_ sender: Any) {
        
        if username.stringValue.isEmpty {
            return
        }
        
        // clear any alerts
        
        //alertText.stringValue = ""
        
        //prepareAccountStrings()
        /*if NoLoMechanism.checkForLocalUser(name: shortName) {
            os_log("Verify local user login for %{public}@", log: uiLog, type: .default, shortName)
            
            if getManagedPreference(key: .DenyLocal) as? Bool ?? false {
                os_log("DenyLocal is enabled, looking for %{public}@ in excluded users", log: uiLog, type: .default, shortName)
                
                var exclude = false
                
                if let excludedUsers = getManagedPreference(key: .DenyLocalExcluded) as? [String] {
                    if excludedUsers.contains(shortName) {
                        os_log("Allowing local sign in via exclusions %{public}@", log: uiLog, type: .default, shortName)
                        exclude = true
                    }
                }
                
                if !exclude {
                    os_log("No exclusions for %{public}@, denying local login. Forcing network auth", log: uiLog, type: .default, shortName)
                    networkAuth()
                    return
                }
            }
            
            if NoLoMechanism.verifyUser(name: shortName, auth: passString) {
                    os_log("Allowing local user login for %{public}@", log: uiLog, type: .default, shortName)
                    setRequiredHintsAndContext()
                    completeLogin(authResult: .allow)
                    return
            } else {
                os_log("Could not verify %{public}@", log: uiLog, type: .default, shortName)
                authFail()
                return
            }
        } else {
            networkAuth()
        }*/
    }

    //TODO
    
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        if(authResult == .allow) {
            window?.close()
        }
        NSApp.stopModal()
    }

}

extension SignIn: NSTextFieldDelegate {
    public func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, self.username.identifier == textField.identifier {
                
                if(textField.stringValue == "exit" && canExit) {
                
                    exit(23)
                    
                }
                
            }
        
    }
}


extension NSWindow {

    func shakeWindow(){
        let numberOfShakes      = 3
        let durationOfShake     = 0.25
        let vigourOfShake : CGFloat = 0.015

        let frame : CGRect = self.frame
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: frame.minX, y: frame.minY))

        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x: frame.minX - frame.size.width * vigourOfShake, y: frame.minY))
            shakePath.addLine(to: CGPoint(x: frame.minX + frame.size.width * vigourOfShake, y: frame.minY))
        }

        shakePath.closeSubpath()

        shakeAnimation.path = shakePath;
        shakeAnimation.duration = durationOfShake;

        self.animations = [NSAnimatablePropertyKey("frameOrigin"):shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
    }

}
