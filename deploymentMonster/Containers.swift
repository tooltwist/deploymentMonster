//
//  Containers.swift
//  deploymentMonster
//
//  Created by Philip Callender on 16/09/2016.
//  Copyright © 2016 Philip Callender. All rights reserved.
//

//import Foundation

import Cocoa

struct Container {
    var name = ""
    var image = ""
    var running = false
    var ports = ""
}

class DockerPS {
    
    var psRunning = false
    var outputPipe:NSPipe!
    var buildTask:NSTask!
    var dockerPsOutput = ""


    func getContainers(completion: ([Container]) -> Void) {
        print("getContainers()")
        
        
        //1.
        psRunning = true
        
        let taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
        
        //2.
        dispatch_async(taskQueue) {
            
            //1.
            //guard let path = NSBundle.mainBundle().pathForResource("BuildScript", ofType:"command") else {
            guard let path = NSBundle.mainBundle().pathForResource("DockerPS", ofType:"sh") else {
                print("Unable to locate DockerPS.sh")
                return
            }
            
            //2.
            self.buildTask = NSTask()
            self.buildTask.launchPath = path
            //            self.buildTask.arguments = arguments
            
            //3.
            self.buildTask.terminationHandler = {
                
                task in
                dispatch_async(dispatch_get_main_queue(), {
                    //                    self.buildButton.enabled = true
                    //                    self.spinner.stopAnimation(self)
                    self.psRunning = false
                    
                    
                    // Convert the output to an array of Containers
                    
                    var containers:[Container] = []
                    var lines = self.dockerPsOutput.componentsSeparatedByString("\n")
                    print("\(lines.count) lines")
                    for i in 0 ..< lines.count {
                        let line = lines[i]
                        print("  \(i) -> \(line)")
                        let sections = line.componentsSeparatedByString("|")
                        print("      \(sections.count) sections")

                        if sections.count == 4 {
                            
                            let running = !sections[2].hasPrefix("Exited")
                            containers.append(Container(
                                name: sections[0],
                                image: sections[1],
                                running: running,
                                ports: sections[3]
                                ))
                        }

                    
                    
                    }
                    completion(containers)
                })
                
            }
            
            self.captureStandardOutputAndRouteToTextView(self.buildTask)
            
            //4.
            self.buildTask.launch()
            
            //5.
            self.buildTask.waitUntilExit()
        }
    }


    func captureStandardOutputAndRouteToTextView(task:NSTask) {
        
        //1.
        outputPipe = NSPipe()
        task.standardOutput = outputPipe
        
        //2.
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        //3.
        NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading , queue: nil) {
            
            notification in
            
            //4.
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: NSUTF8StringEncoding) ?? ""
            
            //5.
//ZZZ            dispatch_async(dispatch_get_main_queue(), {
                
                //                let previousOutput = self.outputText.string ?? ""
    //            let previousOutput = self.devContainers.string ?? ""
    //            let nextOutput = previousOutput + "\n" + outputString
                self.dockerPsOutput = self.dockerPsOutput + "\n" + outputString
                //                self.outputText.string = nextOutput
    //            self.devContainers.string = nextOutput
                
                
                //                var sections = outputString.componentsSeparatedByString("|")
                //                print("sections=\(sections)")
                
                
    //            let range = NSRange(location:nextOutput.characters.count,length:0)
    //            //                self.outputText.scrollRangeToVisible(range)
    //            self.devContainers.scrollRangeToVisible(range)
                
//ZZZ            })
            
            //6.
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }

}
