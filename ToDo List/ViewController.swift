//
//  ViewController.swift
//  ToDo List
//
//  Created by 张壹弛 on 12/24/18.
//  Copyright © 2018 张壹弛. All rights reserved.
//

import Cocoa
//to present data in table, u have to make ViewController tableview datasrc, delegate
class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate{
    //property
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var importantCheckbox: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var deleteButton: NSButton!
    
    var toDoItems : [ToDoItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        getToDoItem()
    }
    func getToDoItem(){
        // Get the ToDoItem from CoreData(need managedObjectContext)
        if let context = (NSApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext{
            do{
                // Set them to the class property
                toDoItems = try context.fetch(ToDoItem.fetchRequest())
            }catch{}
        }
        // update table
        tableView.reloadData()
    }
    @IBAction func addClicked(_ sender: Any) {
        if textField.stringValue != "" {
            // get managedObjectContext from delegate
            if let context = (NSApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext{
                // make a toDoItem from CoreData
                let toDoItem = ToDoItem(context: context)
                toDoItem.name = textField.stringValue
                // checkbox statevalue has been change from int to NSControl.StateValue
                if importantCheckbox.state == .off{
                    // not important
                    toDoItem.important = false
                }else{
                    // important
                    toDoItem.important = true
                }
                (NSApplication.shared.delegate as? AppDelegate)?.saveAction(nil)
                // clear previous added item
                textField.stringValue = ""
                importantCheckbox.state = .off
                getToDoItem()
            }
        }
    }
    
    @IBAction func deleteClicked(_ sender: Any) {
        
        let toDoItem = toDoItems[tableView.selectedRow]
        //make sure we have context to delete that item
        if let context = (NSApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext{
            context.delete(toDoItem)
            //standard step, dont forget
            (NSApplication.shared.delegate as? AppDelegate)?.saveAction(nil)
            getToDoItem()
            //avoid issue that delete one item and then have no item select, selectRow = -1
            deleteButton.isHidden = true
        }
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    // MARK: - TableView Stuff
    func numberOfRows(in tableView: NSTableView) -> Int {
        return toDoItems.count
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //toDoItems defined in property(beginning) row defined in parameter of this func
        let toDoItem = toDoItems[row]
        
     // if tableColumn?.identifier == NSUserInterfaceItemIdentifier.init("importantColumn") {
        if tableColumn?.identifier.rawValue == "importantColumn"{
            //go to get IMPORTANT cell
            // pull one of views from the table view and spit it back to you, here so you can use it
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier.init("importantCell"), owner: self) as? NSTableCellView {
                //now you work with cell and do stuff with it
                if toDoItem.important == true{
                    cell.textField?.stringValue = "❗️"
                }else{
                    cell.textField?.stringValue = ""
                }
                
                return cell
            }
            // -> NSView? indicate looking for NSView optional
            return nil
        }else{
            // TODO NAME
            // pull one of views from the table view and spit it back to you, here so you can use it
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier.init("todoCell"), owner: self) as? NSTableCellView {
                //now you work with cell and do stuff with it
                
                cell.textField?.stringValue = toDoItem.name!
                return cell
            }
            // -> NSView? indicate looking for NSView optional
            return nil
        }
    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        deleteButton.isHidden = false
    }
    
}

