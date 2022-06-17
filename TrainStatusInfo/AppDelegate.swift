//
//  AppDelegate.swift
//  StatusBarInfo
//
//  Created by niklas on 03.04.22.
//

import Cocoa
import CoreMotion
import CoreWLAN

class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private var button: NSStatusBarButton!
    private var title: String = "Loading train data..."
    
    private var provider: TrainProvider? = nil
    
    private var highSpeed: Int = 0
    private var displaySpeed: Int = 0
    private var arrived: Bool = false
    
    private var fetchTimer: Timer?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.button = statusItem.button
        
        let statusBarMenu = NSMenu(title: "Train Info Menu Bar")
        statusBarMenu.addItem(withTitle: "Quit",
                              action: #selector(quit),
                              keyEquivalent: "")
        
        statusItem.menu = statusBarMenu
        
        if let button = statusItem.button {
            button.title = self.title
            
            self.startFetching()
        }
        
        _ = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateInfo), userInfo: nil, repeats: true)
        
        // After 10 seconds of trying to get info, set title to not connected
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if (self.provider != nil) {
                return
            }
            if let button = self.statusItem.button {
                button.title = "Not connected to train hotspot..."
            }
        }
    }
    
    @objc func fetchInfo() {
        // Find active train provider
        if (self.provider == nil) {
            let providers = [Öbb(), DeutscheBahn()]
            
            let currentSSIDs = self.getCurrentSSIDs()
            providers.forEach { provider in
                provider.getPossibleSSIDs().forEach { ssid in
                    if currentSSIDs.contains(ssid) {
                        self.provider = provider
                        print("Setting provider to " + String(describing: provider))
                    }
                }
            }
        }
        
        self.provider?.fetchData()
    }
    
    @objc func updateInfo() {
        var timeLeft = "-:-"
        if (self.provider?.arrivalDate != nil) {
            timeLeft = calculateTimeLeft(arrivalDate: self.provider!.arrivalDate!)
        }
        
        
        var title = ""
        
        if self.provider?.speed != nil {
            if (abs(self.displaySpeed - self.provider!.speed!) > 20) {
                self.displaySpeed = self.provider!.speed!
            }
            
            // Interpolate speed
            if (self.displaySpeed < self.provider!.speed!) {
                self.displaySpeed += 1
            }
            
            if (self.displaySpeed > self.provider!.speed!) {
                self.displaySpeed -= 1
            }
            
            if (self.displaySpeed > self.highSpeed) {
                self.highSpeed = self.displaySpeed
            }
            
            title += String(self.displaySpeed) + " km/h | "
        }
        
        
        if (self.provider?.nextStation != nil) {
            if (self.arrived) {
                title += "➡ " + (self.provider?.nextStation ?? "-")
            } else {
                title += "⬆ " + (self.provider?.nextStation ?? "-") + " " + timeLeft
            }
        }
        
        if (self.highSpeed != 0 && self.highSpeed == self.displaySpeed) {
            title = "🔥 " + title
        }
        
        if (title != self.title) {
            self.title = title
            print("Setting title to: " + title)
            DispatchQueue.main.async {
                if let button = self.statusItem.button {
                    button.title = title
                }
            }
        }
    }
    
    func calculateTimeLeft(arrivalDate: Date) -> String {
        let now = Date()
        
        arrived = (arrivalDate < now)
        
        let components = Calendar.current.dateComponents([.minute, .second], from: now, to: arrivalDate)
        return "\(components.minute!):\(String(format: "%02d", components.second!))"
    }
    
    func startFetching() {
        self.fetchInfo()
        self.fetchTimer = Timer.scheduledTimer(timeInterval: 2.5, target: self, selector: #selector(fetchInfo), userInfo: nil, repeats: true)
    }
    
    func stopFetching() {
        self.fetchTimer?.invalidate()
        self.fetchTimer = nil
    }
    
    func getCurrentSSIDs() -> [String] {
        let client = CWWiFiClient.shared()
        return client.interfaces()?.compactMap { interface in
            return interface.ssid()
        } ?? []
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
