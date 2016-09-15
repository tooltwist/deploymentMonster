//
//  Projects.swift
//  deploymentMonster
//
//  Created by Philip Callender on 14/09/2016.
//  Copyright © 2016 Philip Callender. All rights reserved.
//

import Cocoa

struct Project {
    var name = ""
    var dev = false
    var devDirectory = ""
    var test = false
    var testDirectory = ""
    var docker = false
    var dockerDirectory = ""
}

/*
 * Load projects from teh config directory
 */
func loadProjects() -> [Project] {
    
    let filemgr = NSFileManager.defaultManager()
    let homeDirectory = NSHomeDirectory()
    let configDir = homeDirectory + "/Configs"

    // See if the config directory exists
    if !filemgr.fileExistsAtPath(configDir) {
        
        // The configs directory does not exist
        print("Configs directory \(configDir) not found")
        
        // Ask the user if they'd like to create the directory
        let alert = NSAlert()
        alert.messageText = "Missing directory for configurations"
        alert.addButtonWithTitle("Yes")
        alert.addButtonWithTitle("No")
        alert.informativeText = "Create " + configDir + "?"
        let res = alert.runModal()
        if res == NSAlertFirstButtonReturn {
            
            // Create the directory
            print("Create config directory \(configDir)")
            
            do {
                try filemgr.createDirectoryAtPath(configDir, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError { print(error.localizedDescription); }
            
        }
        return []
        
    }
    
    // Load the projects
    print("Config directory exists")
    
    var list = [Project]()
    
    do {
        let filelist = try filemgr.contentsOfDirectoryAtPath(configDir)
        
//        let fileManager = FileManager.default
        
        
        for filename in filelist {
            print(filename)
            
            // Skip hidden files (start with '.')
            if filename.hasPrefix(".") {
                print("is dot")
                continue
            }

            // Only add directories
            let fullPath = configDir + "/" + filename
            var isDir : ObjCBool = false
            if filemgr.fileExistsAtPath(fullPath, isDirectory:&isDir) {
                if isDir {
                    
                    var dev = false
                    let devDir = fullPath + "/dev"
                    if filemgr.fileExistsAtPath(devDir, isDirectory:&isDir) {
                        if isDir {
                            dev = true
                        }
                    }
                    var test = false
                    let testDir = fullPath + "/test"
                    if filemgr.fileExistsAtPath(testDir, isDirectory:&isDir) {
                        if isDir {
                            test = true
                        }
                    }
                    var dockerize = false
                    let dockerDir = fullPath + "/dockerize"
                    if filemgr.fileExistsAtPath(dockerDir, isDirectory:&isDir) {
                        if isDir {
                            dockerize = true
                        }
                    }

                    list.append(Project(name: filename,
                        dev: dev,
                        devDirectory: devDir,
                        test: test,
                        testDirectory: testDir,
                        docker: dockerize,
                        dockerDirectory: dockerDir))
                }
            }
        }
    } catch let error as NSError { print(error.localizedDescription); }

    
//    let p = Project(name: "Fred")
//    list.append(p)
//    list.append(Project(name: "Bill"))
    return list
}