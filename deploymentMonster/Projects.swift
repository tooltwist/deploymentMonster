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
    
    // For each mode:
    //      - Is it defined? (i.e. has a directory)
    //      - directory path
    //      - what prefix is used for it's docker containers
    //      - how many containers are currently running
    var dev: Bool
    var devDirectory: String
    var devPrefix: String? = nil
//    var devContainersRunning: Int
//    var devContainersStopped: Int
    
    var dockerize = false
    var dockerizeDirectory: String
    
    var test = false
    var testDirectory: String
    var testPrefix: String? = nil
//    var testContainersRunning = 0
//    var testContainersStopped = 0

    var devall: Bool
    var devallDirectory: String
    var devallPrefix: String? = nil
//    var devallContainersRunning: Int
//    var devallContainersStopped: Int

    
    init(name: String, configsDirectory: String) {
        self.name = name

//        self.devDirectory = devDirectory
//        self.dev = (devDirectory != nil)
//        self.devPrefix = self.findPrefix(devDirectory)
//        self.devContainers = 0
        
        
        
        let filemgr = NSFileManager.defaultManager()
        var isDir : ObjCBool = false

        // dev
        self.dev = false
        self.devDirectory = configsDirectory + "/dev"
        if filemgr.fileExistsAtPath(self.devDirectory, isDirectory:&isDir) {
            if isDir {
                self.dev = true
            }
        }
//        self.devContainersRunning = 0
//        self.devContainersStopped = 0
        
        // dockerize
        self.dockerize = false
        self.dockerizeDirectory = configsDirectory + "/dockerize"
        if filemgr.fileExistsAtPath(self.dockerizeDirectory, isDirectory:&isDir) {
            if isDir {
                self.dockerize = true
            }
        }
        
        // test
        self.test = false
        self.testDirectory = configsDirectory + "/test"
        if filemgr.fileExistsAtPath(self.testDirectory, isDirectory:&isDir) {
            if isDir {
                self.test = true
            }
        }
//        self.devContainersRunning = 0
//        self.devContainersStopped = 0
        
        // dev-all
        self.devall = false
        self.devallDirectory = configsDirectory + "/devall"
        if filemgr.fileExistsAtPath(self.devallDirectory, isDirectory:&isDir) {
            if isDir {
                self.devall = true
            }
        }
//        self.devallContainersRunning = 0
//        self.devallContainersStopped = 0

        // Load from properties files (if they exist)
        self.devPrefix = self.findPrefix(devDirectory)
        self.testPrefix = self.findPrefix(testDirectory)
        self.devallPrefix = self.findPrefix(devallDirectory)
    }
    
    func findPrefix(directory: String?) -> String? {
        if directory == nil { return nil }
        
        
        // See if a properties file exists
        let path = directory! + "/.deploymentMonster"
        let filemgr = NSFileManager.defaultManager()
        if filemgr.fileExistsAtPath(path) {
            
            
            let jsonData = NSData(contentsOfFile: path)
            do {
                let jsonResult = try NSJSONSerialization.JSONObjectWithData(jsonData!, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary

                let prefix : String = (jsonResult!["prefix"] as? String)!
                
                print("prefix is \(prefix)")
                return prefix
            }
            catch let error as NSError { print(error.localizedDescription); }
        }
        return nil
    }
    
    /**
     *      Return the prefix of containers for a specific mode (dev, test, devall)
     */
    func prefixForMode(mode: String) -> String? {
        if mode == "dev" {
            return self.devPrefix
        }
        if mode == "test" {
            return self.testPrefix
        }
        if mode == "devall" {
            return self.devallPrefix
        }
        return nil
    }
}

/*
 * Load projects from the config directory
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
                    let project = Project(name: filename, configsDirectory: fullPath)
                    list.append(project)
                }
            }
        }
    } catch let error as NSError { print(error.localizedDescription); }

    
//    let p = Project(name: "Fred")
//    list.append(p)
//    list.append(Project(name: "Bill"))
    return list
}