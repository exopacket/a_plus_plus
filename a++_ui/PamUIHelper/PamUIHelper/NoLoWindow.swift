//
//  NoLoWindow.swift
//  PamUIHelper
//
//  Ryan Fitzgerald 11/2/21.
//

import Foundation
import Cocoa

class NoLoWindow: NSWindow {
    
    private var ctrlPressed:Bool = false;
    @IBOutlet weak var controller: SignIn!
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        
        super.init(contentRect: contentRect, styleMask: style, backing: .buffered, defer: false)
        
    }
    
    override var canBecomeKey: Bool {
        return true;
    }
    
    override var canBecomeMain: Bool {
        return true;
    }
}
