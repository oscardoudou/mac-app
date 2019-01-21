/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Cocoa

class ViewController: NSViewController {

  // MARK: - Outlets

  @IBOutlet weak var tableView: NSTableView!
  @IBOutlet weak var infoTextView: NSTextView!
  @IBOutlet weak var saveInfoButton: NSButton!
  @IBOutlet weak var moveUpButton: NSButton!

  // MARK: - Properties

  var filesList: [URL] = []
  var showInvisibles = false

  var selectedFolder: URL? {
    //a didSet observer is looking for changes to property selectedFolder
    didSet {
      if let selectedFolder = selectedFolder {
        //populuate filesList property to the contents of selected folder
        filesList = contentsOf(folder: selectedFolder)
        selectedItem = nil
        self.tableView.reloadData()
        self.tableView.scrollRowToVisible(0)
        moveUpButton.isEnabled = true
        view.window?.title = selectedFolder.path
      } else {
        moveUpButton.isEnabled = false
        view.window?.title = "FileSpy"
      }
    }
  }

  var selectedItem: URL? {
    //similarly a didset observer is looking for changes to selectedItem
    didSet {
      infoTextView.string = ""
      saveInfoButton.isEnabled = false

      guard let selectedUrl = selectedItem else {
        return
      }

      let infoString = infoAbout(url: selectedUrl)
      if !infoString.isEmpty {
        let formattedText = formatInfoText(infoString)
        infoTextView.textStorage?.setAttributedString(formattedText)
        saveInfoButton.isEnabled = true
      }
    }
  }

  // MARK: - View Lifecycle & error dialog utility

  override func viewWillAppear() {
    super.viewWillAppear()

    restoreCurrentSelections()
  }

  override func viewWillDisappear() {
    saveCurrentSelections()

    super.viewWillDisappear()
  }

  func showErrorDialogIn(window: NSWindow, title: String, message: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.alertStyle = .critical
    alert.beginSheetModal(for: window, completionHandler: nil)
  }

}

// MARK: - Getting file or folder information

extension ViewController {

  func contentsOf(folder: URL) -> [URL] {
    let fileManager = FileManager.default
    do{
        let contents = try fileManager.contentsOfDirectory(atPath: folder.path)
        //process the returned array using map to convert each name of file or folder inside "folder" into a complete URL
        let urls = contents.map{ return folder.appendingPathComponent($0)}
        return urls
    }catch{
        return []
    }
  }

  func infoAbout(url: URL) -> String {
    //as usual get a reference to the FileManager shared instance
    let fileManager = FileManager.default
    do{
        //get the file information, it return a dic of type FileAttributeKey(created time, author...)-> Any
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        //2nd element in array is empty string so that path is  2 line away from rest of attrbutes, more like a title
        var report: [String] = ["\(url.path)",""]
        
        for(key, value) in attributes{
            //ingore unuseful attributes
            if key.rawValue == "NSFileExtendedAttributes" {continue}
            //inside each pair concatenate key value in a fashion that value come after key with a tab
            report.append("\(key.rawValue):\t \(value)")
        }
        return report.joined(separator: "\n")
    }catch{
        return "No information available for \(url.path)"
    }
  }

  func formatInfoText(_ text: String) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle.default().mutableCopy() as? NSMutableParagraphStyle
    paragraphStyle?.minimumLineHeight = 24
    paragraphStyle?.alignment = .left
    paragraphStyle?.tabStops = [ NSTextTab(type: .leftTabStopType, location: 240) ]

    let textAttributes: [String: Any] = [
      NSFontAttributeName: NSFont.systemFont(ofSize: 14),
      NSParagraphStyleAttributeName: paragraphStyle ?? NSParagraphStyle.default()
    ]

    let formattedText = NSAttributedString(string: text, attributes: textAttributes)
    return formattedText
  }


}

// MARK: - Actions

extension ViewController {

  @IBAction func selectFolderClicked(_ sender: Any) {
    guard let window = view.window else { return }
    let panel = NSOpenPanel();
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    
    panel.beginSheetModal(for: window){(result) in
        if result == NSFileHandlingPanelOKButton{
            //populuate a property named selectedFolder
            self.selectedFolder = panel.urls[0]
            //self refer to viewController
//                        print(self.selectedFolder)
        }
    }
    
  }

  @IBAction func toggleShowInvisibles(_ sender: NSButton) {
  }

  @IBAction func tableViewDoubleClicked(_ sender: Any) {
  }

  @IBAction func moveUpClicked(_ sender: Any) {
  }

  @IBAction func saveInfoClicked(_ sender: Any) {
  }

}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {

  func numberOfRows(in tableView: NSTableView) -> Int {
    return filesList.count
  }

}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {

  func tableView(_ tableView: NSTableView, viewFor
    tableColumn: NSTableColumn?, row: Int) -> NSView? {
    //get the url matching ther row number
    let item = filesList[row]
    //get the icon for url, NSWorkSpace is another useful singleton
    let fileIcon = NSWorkspace.shared().icon(forFile: item.path)
    //get a reference to the cell for this table. The FileCell identifier was set in the StoryBoard
    if let cell = tableView.make(withIdentifier: "FileCell", owner: "nil")as?NSTableCellView{
        //if cell exist, set its text field to show the file name and its image view to show the fiile icon
        cell.textField?.stringValue = item.lastPathComponent;
        cell.imageView?.image = fileIcon
        return cell
    }
    //if no cell exists return nil
    return nil
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    if tableView.selectedRow < 0 {
      selectedItem = nil
      return
    }

    selectedItem = filesList[tableView.selectedRow]
  }

}

// MARK: - Save & Restore previous selection

extension ViewController {

  func saveCurrentSelections() {
    guard let dataFileUrl = urlForDataStorage() else { return }

    let parentForStorage = selectedFolder?.path ?? ""
    let fileForStorage = selectedItem?.path ?? ""
    let completeData = "\(parentForStorage)\n\(fileForStorage)\n"

    try? completeData.write(to: dataFileUrl, atomically: true, encoding: .utf8)
  }

  func restoreCurrentSelections() {
    guard let dataFileUrl = urlForDataStorage() else { return }

    do {
      let storedData = try String(contentsOf: dataFileUrl)
      let storedDataComponents = storedData.components(separatedBy: .newlines)
      if storedDataComponents.count >= 2 {
        if !storedDataComponents[0].isEmpty {
          selectedFolder = URL(fileURLWithPath: storedDataComponents[0])
          if !storedDataComponents[1].isEmpty {
            selectedItem = URL(fileURLWithPath: storedDataComponents[1])
            selectUrlInTable(selectedItem)
          }
        }
      }
    } catch {
      print(error)
    }
  }

  private func selectUrlInTable(_ url: URL?) {
    guard let url = url else {
      tableView.deselectAll(nil)
      return
    }

    if let rowNumber = filesList.index(of: url) {
      let indexSet = IndexSet(integer: rowNumber)
      DispatchQueue.main.async {
        self.tableView.selectRowIndexes(indexSet, byExtendingSelection: false)
      }
    }
  }
  
  private func urlForDataStorage() -> URL? {
    return nil
  }

}
/*
 
 */
