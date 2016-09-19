//
//  ViewController.swift
//  deploymentMonster
//
//  Created by Philip Callender on 14/09/2016.
//  Copyright © 2016 Philip Callender. All rights reserved.
//

// See https://www.raywenderlich.com/118835/os-x-nstableview-tutorial
// See



/*
 *  Steps:
 *      Select projects
 *      Select containers
 *      Display project list
 *      Display current project
 *      Display containers for current project
 */
import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var projectTableView: NSTableView!
    @IBOutlet weak var devContainersTableView: NSTableView!
    @IBOutlet weak var testContainersTableView: NSTableView!
    
    @IBOutlet weak var devTab: NSTabViewItem!
    @IBOutlet weak var devTerminalButton: NSButton!
    @IBOutlet weak var devFinderButton: NSButton!
    
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
    
    var projects: [Project] = [] {
        didSet {
//            redisplayProjectList()
        }
    }
    
    var containers: [Container] = [] {
        didSet {
            redisplayProjectList()
        }
    }
    
    // Current project
    var currentProject: Project? {
        didSet {
            print("currentProject was changed to \(self)")
            showCurrentProject()
        }
    }
    
//    // Related to Docker ps
//    dynamic var psRunning = false
//    var outputPipe:NSPipe!
//    var buildTask:NSTask!
//    var dockerPsOutput = ""
    
    
    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    
    
    
// MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the source for the project table
        projectTableView.setDelegate(self)
        projectTableView.setDataSource(self)
        
        // Set the source for the dev containers table
        devContainersTableView.setDelegate(self)
        devContainersTableView.setDataSource(self)
        
        // Set the source for the test containers table
        testContainersTableView.setDelegate(self)
        testContainersTableView.setDataSource(self)
        
        // Set fixed spaced font for docker outputs
        //        let font = NSFont(name: "Courier", size: 11)
        //        devContainers.font = font
  
    }
    
    @IBAction func refreshButtonPressed(sender: AnyObject) {
        loadProjectsAndContainers()
    }
    
    func loadProjectsAndContainers() {
        
        // Load the list of projects
        projects = loadProjects()
        
        // Load the list of Docker containers
        loadContainers()
        
    }
    
    override func viewDidAppear() {
        
        loadProjectsAndContainers();
        
//        if (projects.count == 0) {
//            
//            // Display nice message
//            let alert = NSAlert()
//            alert.messageText = "No projects found"
//            alert.addButtonWithTitle("OK")
//            alert.informativeText = "Please checkout projects from config.tooltwist.com into ~/Configs, then press REFRESH to update this screen."
//            alert.runModal()
//        }
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
            directory = currentProject!.dockerizeDirectory
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
    
    func loginToContainer(containerName: String) -> Void {
        
        // Create a script to go to this directory
        let str = "#!/bin/bash\n"
            + "clear\n"
            + "export DOCKER_HOST=tcp://192.168.99.100:2376\n"
            + "#export DOCKER_MACHINE_NAME=default\n"
            + "export DOCKER_TLS_VERIFY=1\n"
            + "export DOCKER_CERT_PATH=${HOME}/.docker/machine/machines/default\n"
            + "/usr/local/bin/docker exec -it \(containerName) bash\n"
            + "echo Press Enter\n"
            + "read ans\n"
        
        
        
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
        let task = NSTask.launchedTaskWithLaunchPath(path, arguments: arguments)
        task.waitUntilExit()
    }
    
    func logsForContainer(containerName: String) -> Void {
        
        // Create a script to go to this directory
        let str = "#!/bin/bash\n"
            + "export DOCKER_HOST=tcp://192.168.99.100:2376\n"
            + "#export DOCKER_MACHINE_NAME=default\n"
            + "export DOCKER_TLS_VERIFY=1\n"
            + "export DOCKER_CERT_PATH=${HOME}/.docker/machine/machines/default\n"
            + "/usr/local/bin/docker logs -f \(containerName)\n"
            + "echo Press Enter\n"
            + "read ans\n"

        
        
        
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
        let task = NSTask.launchedTaskWithLaunchPath(path, arguments: arguments)
        task.waitUntilExit()
        
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
            directory = currentProject!.dockerizeDirectory
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

extension ViewController {
    
    func findProject(name: String) -> Project? {
        for i in 0 ..< projects.count {
            if projects[i].name == name {
                return projects[i]
            }
        }
        return nil
    }

    func updateProjectCounts() {
        print("updateProjectCounts()")

//        for i in 0 ..< projects.count {
//
//            // dev
//            projects[i].devContainersRunning = 0
//            projects[i].devContainersStopped = 0
//            if projects[i].devPrefix != nil {
//                let prefix = projects[i].devPrefix! + "_"
//                
//                for container in containers {
//                    if container.name.hasPrefix(prefix) {
//                        if container.running {
//                            projects[i].devContainersRunning += 1
//                        }
//                        else {
//                            projects[i].devContainersStopped += 1
//                        }
//                    }
//                }
//            }
//            
//            // test
//            projects[i].testContainersRunning = 0
//            projects[i].testContainersStopped = 0
//            if projects[i].testPrefix != nil {
//                let prefix = projects[i].testPrefix! + "_"
//                
//                for container in containers {
//                    if container.name.hasPrefix(prefix) {
//                        if container.running {
//                            projects[i].testContainersRunning += 1
//                        }
//                        else {
//                            projects[i].testContainersStopped += 1
//                        }
//                    }
//                }
//            }
//            
//            // devall
//            projects[i].devContainersRunning = 0
//            projects[i].devContainersStopped = 0
//            if projects[i].devPrefix != nil {
//                let prefix = projects[i].devPrefix! + "_"
//                
//                for container in containers {
//                    if container.name.hasPrefix(prefix) {
//                        if container.running {
//                            projects[i].devallContainersRunning += 1
//                        }
//                        else {
//                            projects[i].devallContainersStopped += 1
//                        }
//                    }
//                }
//            }
//        }
    
    }

    func redisplayProjectList() {
        print("redisplayProjectList()")

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.projectTableView.reloadData()
        })
    }
}


extension ViewController : NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {

        if tableView == self.projectTableView {
            return projects.count
        } else if tableView == self.devContainersTableView {
            return numberOfRowsInTableView_containers(tableView, mode: "dev")
        } else if tableView == self.testContainersTableView {
            return numberOfRowsInTableView_containers(tableView, mode: "test")
        }
        
        assert(false, "unknown table")
    }
    
    
    /**
     *      Return the number of rows in one of the containers tables
     */
    func numberOfRowsInTableView_containers(tableView: NSTableView, mode: String) -> Int {
        
        var rows = 0
        if currentProject != nil {
            let prefix = currentProject!.prefixForMode(mode)
            if prefix != nil {
                for container in containers {
                    if container.name.hasPrefix(prefix!) {
                        rows += 1
                    }
                }
            }
        }
        return rows
    }
}

extension ViewController : NSTableViewDelegate {

    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {

        
        if tableView == self.devContainersTableView {
            return tableView_containers(tableView, tableColumn: tableColumn, row: row, mode: "dev")
        }
        else if tableView == self.testContainersTableView {
            return tableView_containers(tableView, tableColumn: tableColumn, row: row, mode: "test")
        }
    
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
            
            if project.devPrefix != nil {

                // See how many dev containers are running
                var running = 0
                var stopped = 0
                let prefix = project.devPrefix! + "_"
                for container in containers {
                    if container.name.hasPrefix(prefix) {
                        if container.running {
                            running += 1
                        }
                        else {
                            stopped += 1
                        }
                    }
                }

                
                
                text = "\(running)/\(stopped)"
            }
            else if project.dev {
                text = "?"
            }
            else {
                text = "-"
            }
            cellIdentifier = "dev_cell_id"
        } else if tableColumn == tableView.tableColumns[2] {
            text = project.dockerize ? "YES" : ""
            cellIdentifier = "dockerize_cell_id"
        } else if tableColumn == tableView.tableColumns[3] { // test
            if project.testPrefix != nil {
                
                // See how many test containers are running
                var running = 0
                var stopped = 0
                let prefix = project.testPrefix! + "_"
                for container in containers {
                    if container.name.hasPrefix(prefix) {
                        if container.running {
                            running += 1
                        }
                        else {
                            stopped += 1
                        }
                    }
                }
                text = "\(running)/\(stopped)"
            }
            else if project.test {
                text = "?"
            }
            else {
                text = "-"
            }
            cellIdentifier = "test_cell_id"
        }
        
        // Return the cell for this row/column
        if let cell = projectTableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        return nil
    }
    
    
    /**
     *  tableview for one of the containers tables.
     */
    func tableView_containers(tableView: NSTableView, tableColumn: NSTableColumn?, row: Int, mode: String) -> NSView? {

        // Look for the required container
        
        if currentProject != nil {
            let prefix = currentProject!.prefixForMode(mode)
            if prefix != nil {
                
                // Iterate through the containers, till we find the continer for this row
                let container = findContainerForCurrentProject(row, mode: mode)
                
                // This is the required container - return it's cell
                var text:String = ""
                var cellIdentifier: String = ""
                
                if tableColumn == tableView.tableColumns[0] { // name
                    if container!.running {
                        text = container!.name
                    }
                    else {
                        text = "[" + container!.name + "]"
                    }
                    cellIdentifier = "name_cell_identifier"
                }
                else if tableColumn == tableView.tableColumns[1] { // image
                    text = container!.image
                    cellIdentifier = "image_cell_identifier"
                }
                else if tableColumn == tableView.tableColumns[2] { // logs
                    text = container!.image
                    cellIdentifier = "logs_cell_identifier"
                }
                else if tableColumn == tableView.tableColumns[3] { // login
                    text = container!.image
                    cellIdentifier = "login_cell_identifier"
                }
                
                // Return the cell for this row/column
                if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
                    cell.textField?.stringValue = text
                    tagButtonsInView(cell, tag: row)
                    return cell
                }
                return nil
            }
        }
        return nil
    }

    func findContainerForCurrentProject(requiredIndex: Int, mode: String) -> Container? {
        
        // Look for the required container
        if currentProject == nil {
            return nil
        }
        
        let prefix = currentProject!.prefixForMode(mode)
        if prefix == nil {
            return nil
        }
                
        // Iterate through the containers, till we find the continer for this row
        var cnt = 0
        for i in 0 ..< containers.count {
            
            // See if this container is for this project / mode
            if containers[i].name.hasPrefix(prefix! + "_") {
                
                // Container is for this project/mode.
                // Is it for the row we ar displaying?
                if cnt == requiredIndex {
                    return containers[i]
                }
                else {
                    cnt += 1
                }
            }
        }
        return nil
    }

    
    func tagButtonsInView(view: NSView, tag: Int) -> Void {
        for subview in view.subviews as [NSView] {
            if let labelView = subview as? NSButton {
                labelView.tag = tag
            } else {
                tagButtonsInView(subview, tag: tag)
            }
        }
    }

    
    func tableViewSelectionDidChange(notification: NSNotification) {
        
//        notification.
        
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

//    func tableViewSelectionDidChan
//    
//    func tableView(tableView: NSTableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        print("did select:      \(indexPath)  ")
//    }

    
    

}

// MARK: -
// MARK:         Table of test containers
// MARK: -



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
            showDockerize = currentProject!.dockerize
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
        
//        self.devContainers.string = ""
        
        // Get a list of containers
//        dockerPs()
//        
//        getContainers()
        
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.devContainersTableView.reloadData()
        })
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.testContainersTableView.reloadData()
        })

        
    }
}

// MARK: -
// MARK:         Docker containers
// MARK: -
extension ViewController {

    func loadContainers() {
        
        let dockerPS = DockerPS()
        dockerPS.getContainers({(containers:[Container])->Void in
            print("Have containers")
            self.containers = containers
        })

    }

    @IBAction func loginToTestContainer(sender: AnyObject) {
        let index = sender.tag
        let container = findContainerForCurrentProject(index, mode: "test")
        print("loginToTestContainer \(index) as \(sender.tag!) is \(container!.name)")
        loginToContainer(container!.name)
    }
    
    @IBAction func viewLogsOfTestContainer(sender: AnyObject) {
        let index = sender.tag
        let container = findContainerForCurrentProject(index, mode: "test")
        print("viewLogsOfTestContainer \(index) as \(sender.tag!) is \(container!.name)")
        logsForContainer(container!.name)
    }
    
//    func dockerPs() {
//        print("dockerPs()")
//        
//        
//        
//        
//        //1.
//        psRunning = true
//        
//        let taskQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
//        
//        //2.
//        dispatch_async(taskQueue) {
//            
//            //1.
//            //guard let path = NSBundle.mainBundle().pathForResource("BuildScript", ofType:"command") else {
//            guard let path = NSBundle.mainBundle().pathForResource("DockerPS", ofType:"sh") else {
//                print("Unable to locate DockerPS.sh")
//                return
//            }
//            
//            //2.
//            self.buildTask = NSTask()
//            self.buildTask.launchPath = path
//            //            self.buildTask.arguments = arguments
//            
//            //3.
//            self.buildTask.terminationHandler = {
//                
//                task in
//                dispatch_async(dispatch_get_main_queue(), {
//                    //                    self.buildButton.enabled = true
//                    //                    self.spinner.stopAnimation(self)
//                    self.psRunning = false
//                    
//                    
//                    // Convert the output to an array of Containers
//                    var lines = self.dockerPsOutput.componentsSeparatedByString("\n")
//                    print("\(lines.count) lines")
//                    for i in 0 ..< lines.count {
//                        let line = lines[i]
//                        print("  \(i) -> \(line)")
//                        let sections = line.componentsSeparatedByString("|")
//                        print("      \(sections.count) sections")
//                    }
//                    
//                    
//                    
//                })
//                
//            }
//            
//            self.captureStandardOutputAndRouteToTextView(self.buildTask)
//            
//            //4.
//            self.buildTask.launch()
//            
//            //5.
//            self.buildTask.waitUntilExit()
//        }
//    }
//
//
//    func captureStandardOutputAndRouteToTextView(task:NSTask) {
//        
//        //1.
//        outputPipe = NSPipe()
//        task.standardOutput = outputPipe
//        
//        //2.
//        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
//        
//        //3.
//        NSNotificationCenter.defaultCenter().addObserverForName(NSFileHandleDataAvailableNotification, object: outputPipe.fileHandleForReading , queue: nil) {
//            
//            notification in
//            
//            //4.
//            let output = self.outputPipe.fileHandleForReading.availableData
//            let outputString = String(data: output, encoding: NSUTF8StringEncoding) ?? ""
//            
//            //5.
//            dispatch_async(dispatch_get_main_queue(), {
//                //                let previousOutput = self.outputText.string ?? ""
//                let previousOutput = self.devContainers.string ?? ""
//                let nextOutput = previousOutput + "\n" + outputString
//                self.dockerPsOutput = self.dockerPsOutput + "\n" + outputString
//                //                self.outputText.string = nextOutput
//                self.devContainers.string = nextOutput
//                
//                
////                var sections = outputString.componentsSeparatedByString("|")
////                print("sections=\(sections)")
//                
//                
//                let range = NSRange(location:nextOutput.characters.count,length:0)
//                //                self.outputText.scrollRangeToVisible(range)
//                self.devContainers.scrollRangeToVisible(range)
//                
//            })
//            
//            //6.
//            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
//        }
//    }
}
