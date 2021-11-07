//
//  AppDelegate.swift
//  PamUIHelper
//
//  Created by Ryan Fitzgerald on 11/2/21.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NoLoWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        window.windowController?.windowDidLoad()
        
        let presOptions : NSApplication.PresentationOptions = [.hideDock, .hideMenuBar, .autoHideToolbar, .disableForceQuit, .disableHideApplication, .disableAppleMenu, .disableProcessSwitching, .fullScreen, .disableMenuBarTransparency]
        
        
        let optionsDictionary = [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions: presOptions]

        window.controller.mainView.enterFullScreenMode(NSScreen.main!, withOptions: optionsDictionary)
        
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

