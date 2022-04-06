//
//  main.swift
//  StatusBarInfo
//
//  Created by niklas on 03.04.22.
//

import Foundation
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
