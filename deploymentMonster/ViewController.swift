//
//  ViewController.swift
//  deploymentMonster
//
//  Created by Philip Callender on 14/09/2016.
//  Copyright © 2016 Philip Callender. All rights reserved.
//

// See https://www.raywenderlich.com/118835/os-x-nstableview-tutorial
// See

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var projectTableView: NSTableView!
    
    @IBOutlet weak var devTab: NSTabViewItem!
    @IBOutlet weak var devTerminalButton: NSButton!
    @IBOutlet weak var devFinderButton: NSButton!
    @IBOutlet var devContainers: NSTextView!
    
    @IBOutlet weak var dockerizeTab: NSTabViewItem!
    @IBOutlet weak var dockerizeTerminalButton: NSButton!
    @IBOutlet weak var dockerizeFinderButton: NSButton!
    
    @IBOutlet weak var testTab: NSTabViewItem!
    @IBOutlet weak var testTerminalButton: NSButton!
    @IBOutlet weak var testFinderButton: NSButton!
    
    @IBOutlet weak var projectTab: NSTabViewItem!
    @IBOutlet weak var projectTerminalButton: NSButton!
    @IBOutlet weak var projectFinderButton: NSButton!
    @IBOutlet weak var projectDirectoryMsg: NSTextField!
    @IBOutlet weak var projectDirectoryNotFoundMsg: NSTextField!
    
    
    var projects: [Project] = []
    
    // Current project
    var currentProject: Project? {
        didSet {
            print("currentProject was changed")
            showCurrentProject()
        }
    }
    
    // Related to Docker ps
    dynamic var psRunning = false
    var outputPipe:NSPipe!
    var buildTask:NSTask!
    
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    
    
    
// MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Source of data for the project list
        projects = loadProjects()
        projectTableView.setDelegate(self)
        projectTableView.setDataSource(self)
        
        // Set fixed spaced font for docker outputs
        let font = NSFont(name: "Courier", size: 11)
        devContainers.font = font
  
    }
    
    override func viewDidAppear() {
        
        if (projects.count == 0) {
            
            // Display nice message
            let alert = NSAlert()
            alert.messageText = "No projects found"
            alert.addButtonWithTitle("OK")
            alert.informativeText = "Please checkout projects from config.tooltwist.com into ~/Configs, then press REFRESH to update this screen."
            alert.runModal()
        }
    }

    
    
    
    
// MARK: -
// MARK: Start Terminals and Finder
// MARK: -

    @IBAction func configsTerminalButton(sender: AnyObject) {
        //print("configsTerminalButton operation")
        
        if currentProject == nil {
            return
        }

        let button = sender as! NSButton
        let id = button.identifier
        var directory = ""
        if id == "devTerminalButton" {
            directory = currentProject!.devDirectory
        } else if id == "dockerizeTerminalButton" {
            directory = currentProject!.dockerDirectory
        } else if id == "testTerminalButton" {
            directory = currentProject!.testDirectory
        } else if id == "projectTerminalButton" {
            directory = "/Development/projects/" + currentProject!.name
        }
        else {
            print("Unknown tab identifier \(id)")
            return
        }
        
        // Create a script to go to this directory
        let str = "#!/bin/bash\n"
            + "cd " + directory + "\n"
            // + "/bin/bash --login\n";
            + "clear\n"
            + "exec /Applications/Docker/Docker\\ Quickstart\\ Terminal.app/Contents/Resources/Scripts/start.sh\n"
        let tmpDir = NSTemporaryDirectory()
        let fileName = NSUUID().UUIDString + ".command"
        let fileURL = NSURL.fileURLWithPathComponents([tmpDir, fileName])
        do {
            try str.writeToURL(fileURL!, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error as NSError { print(error.localizedDescription); }
        
        // Make the script executable
        let scriptPath = fileURL?.path;
        print("scriptPath is \(scriptPath)")
        let filemgr = NSFileManager.defaultManager()
        do {
            try filemgr.setAttributes([NSFilePosixPermissions : 0500], ofItemAtPath: scriptPath!)
        } catch let error as NSError { print(error.localizedDescription); }

        // Run the script in Terminal
        let path = "/usr/bin/open"
        let arguments = ["-b", "com.apple.terminal", scriptPath!]
//        sender.enabled = false
        let task = NSTask.launchedTaskWithLaunchPath(path, arguments: arguments)
        task.waitUntilExit()
//        sender.enabled = true

    }

    @IBAction func configsFinderButton(sender: AnyObject) {
        print("configsFinderButton operation")
        
        
        if currentProject == nil {
            return
        }
        
        let button = sender as! NSButton
        let id = button.identifier
        var directory = ""
        if id == "devFinderButton" {
            directory = currentProject!.devDirectory
        } else if id == "dockerizeFinderButton" {
            directory = currentProject!.dockerDirectory
        } else if id == "testFinderButton" {
            directory = currentProject!.testDirectory
        } else if id == "projectFinderButton" {
            directory = "/Development/projects/" + currentProject!.name
        }
        else {
            print("Unknown tab identifier \(id)")
            return
        }
        
        
        let path = "/usr/bin/open"
//        let arguments = ["-R", "/Users/philipcallender/Configs"]
        let arguments = ["-R", directory]
        
        //        sender.enabled = false
        
        let task = NSTask.launchedTaskWithLaunchPath(path, arguments: arguments)
        task.waitUntilExit()
    }
    
    @IBAction func projectTerminalButton(sender: AnyObject) {
        print("projectTerminalButton operation")
    }


}

// MARK: -
// MARK:         List of Projects UI
// MARK: -

extension ViewController : NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        //return directoryItems?.count ?? 0
        return projects.count;
//        return 3;
    }
}

extension ViewController : NSTableViewDelegate {
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
//        var image:NSImage?
        var text:String = ""
        var cellIdentifier: String = ""

        // Get the project
        if row < 0 || row >= projects.count {
            return nil
        }
        let project = projects[row]

        // See which column is being displayed
        if tableColumn == tableView.tableColumns[0] {
            text = project.name
            cellIdentifier = "ProjectCellID"
        } else if tableColumn == tableView.tableColumns[1] {
            text = project.dev ? "YES" : ""
            cellIdentifier = "dev_cell_id"
        } else if tableColumn == tableView.tableColumns[2] {
            text = project.docker ? "YES" : ""
            cellIdentifier = "dockerize_cell_id"
        } else if tableColumn == tableView.tableColumns[3] {
            text = project.test ? "YES" : ""
            cellIdentifier = "test_cell_id"
        }
        
        // Return the cell for this row/column
        if let cell = projectTableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        let numIndexes = projectTableView.selectedRowIndexes.count
        if numIndexes > 0 {
            let index = projectTableView.selectedRowIndexes.firstIndex
            if index >= 0 && index <= projects.count {
                currentProject = projects[index];
//                showCurrentProject()
            } else {
                currentProject = nil
//                showCurrentProject()
            }
        }
    }

}



// MARK: -
// MARK:         Current project
// MARK: -
extension ViewController {

    func showCurrentProject() {
        print("showCurrentProject()")
        
        var showDev = false
        var showDockerize = false
        var showTest = false
        var showProjectTab = false
        
        if currentProject != nil {
            print("Current project is \(currentProject!.name)")

            showDev = currentProject!.dev
            showDockerize = currentProject!.docker
            showTest = currentProject!.test
            
            // See if the project directory exists
            let projectDir = "/Development/projects/" + currentProject!.name
            projectDirectoryMsg.stringValue = projectDir
            var isDir : ObjCBool = false
            let filemgr = NSFileManager.defaultManager()
            if filemgr.fileExistsAtPath(projectDir, isDirectory:&isDir) {
                if isDir {
                    showProjectTab = true
                }
            }
        }
        
        
        // Look after dev tab
        if showDev {
            devTerminalButton.enabled = true
            devFinderButton.enabled = true
        }
        else {
            devTerminalButton.enabled = false
            devFinderButton.enabled = false
        }
        
        // Look after dockerize tab
        if showDockerize {
            dockerizeTerminalButton.enabled = true
            dockerizeFinderButton.enabled = true
        }
        else {
            dockerizeTerminalButton.enabled = false
            dockerizeFinderButton.enabled = false
        }
        
        // Look after test tab
        if showTest {
            testTerminalButton.enabled = true
            testFinderButton.enabled = true
        }
        else {
            testTerminalButton.enabled = false
            testFinderButton.enabled = false
        }
        
        // Look after project tab
        if showProjectTab {
            projectDirectoryNotFoundMsg.hidden = true
            projectTerminalButton.enabled = true
            projectFinderButton.enabled = true
        }
        else {
            projectDirectoryNotFoundMsg.hidden = false
            projectTerminalButton.enabled = false
            projectFinderButton.enabled = false
        }
        
        self.devContainers.string = ""
        
        // Get a list of containers
        dockerPs()
        
    }
}

// MARK: -
// MARK:         Docker containers
// MARK: -
extension ViewController {

    func dockerPs() {
        print("dockerPs()")
        
        
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
            dispatch_async(dispatch_get_main_queue(), {
                //                let previousOutput = self.outputText.string ?? ""
                let previousOutput = self.devContainers.string ?? ""
                let nextOutput = previousOutput + "\n" + outputString
                //                self.outputText.string = nextOutput
                self.devContainers.string = nextOutput
                
                let range = NSRange(location:nextOutput.characters.count,length:0)
                //                self.outputText.scrollRangeToVisible(range)
                self.devContainers.scrollRangeToVisible(range)
                
            })
            
            //6.
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
}
