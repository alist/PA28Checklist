//
//  ViewController.swift
//  PA28Checklist
//
//  Created by Alexander H List on 11/11/18.
//  Copyright © 2018 Alexander H List. All rights reserved.
//

import UIKit
import AVFoundation

fileprivate let speechRate: Float = 0.53
fileprivate let numberWordsSpoken: Int = 3

class CheckCell: UITableViewCell {
  @IBOutlet weak var todoLabel: UILabel!
  
  func setupCell(todo: String, selection: Bool) {
    todoLabel.text = todo
    accessoryType = selection ? .checkmark : .none
  }
}

class ViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  let speechSynth = AVSpeechSynthesizer()
  let myoManager = MyoManager()
  
  /// Sections have their arrays of todos
  var todoData: [(String, Array<(String, Bool)>)] = []
  static let order = "order"
  static let comma: Character = ","
  
  func loadData() {
    guard let url = Bundle.main.url(forResource: "warrior2checklist", withExtension: "plist") else { return }
    let data = try! Data(contentsOf: url)
    let plist = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    
    let dictionary = plist as! Dictionary<String, Any>
    let order = dictionary[ViewController.order] as! String
    let stages = order.split(separator: ViewController.comma)
    
    for stage in stages {
      let stage = String(stage)
      let steps = dictionary[stage] as! [String]
      let stateArray = steps.map { ($0, false) }
      let value = (stage, stateArray)
      todoData.append(value)
    }
  }
  
  func updateUI() {
    let selectedPaths = tableView.indexPathsForSelectedRows ?? []
    for path in selectedPaths {
      tableView.deselectRow(at: path, animated: false)
    }
    tableView.selectRow(at: nextToDo, animated: true, scrollPosition: .middle)
    speakTodo()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
    tableView.reloadData()
    updateUI()
    myoManager.delegate = self
    speechSynth.delegate = self
    
    OperationQueue.main.addOperation { [weak self] in
      self?.openSettings()
    }
  }
    
  @IBAction func openSettings() {
    let settings = TLMSettingsViewController.settingsInNavigationController()!
    present(settings, animated: true, completion: nil)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
}

extension ViewController: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    /// can cancel the timer for unducking!
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    /// set a cancelable timer to un-duck
    /// stopAudioSessionSession()
  }
}

extension ViewController {
  var audioSession: AVAudioSession {
    return AVAudioSession.sharedInstance()
  }

  func setupAudioSession() {
    do {
      try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .duckOthers)
      try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
    } catch {
      print(error)
    }
  }
  
  func stopAudioSessionSession() {
    do {
      try audioSession.setActive(false)
    } catch {
      print(error)
    }
  }
}

extension ViewController {
  var nextToDo: IndexPath? {
    for (si, section) in todoData.enumerated() {
      for (ri, item) in section.1.enumerated() {
        if item.1 == false { return IndexPath(row: ri, section: si) }
      }
    }
    return nil
  }
  
  func speakTodo() {
    guard let nextToDo = nextToDo else { return }
    setupAudioSession()
    
    if nextToDo.row == 0 {
      let sectionText = todoData[nextToDo.section].0
      let utter = AVSpeechUtterance(string: sectionText)
      utter.rate = speechRate
      utter.postUtteranceDelay = 0.2
      speechSynth.speak(utter)
    }
    
    let item = todoData[nextToDo.section].1[nextToDo.row]
    // TODO: Would be cool to not speak `and` or `of` or `as`
    let text = Array(item.0.split(separator: " ").prefix(numberWordsSpoken)).joined(separator: " ")
    let utter = AVSpeechUtterance(string: text)
    utter.rate = speechRate
    speechSynth.speak(utter)
  }
  
  func completedTodo(indexPath: IndexPath) {
    var item = todoData[indexPath.section].1[indexPath.row]
    item.1 = !item.1
    todoData[indexPath.section].1[indexPath.row] = item
    tableView.reloadRows(at: [indexPath], with: .none)
    updateUI()
  }
}

extension ViewController: MyoManagerDelegate {
  func recognizedGesture(manager: MyoManager) {
    guard let path = nextToDo else { return }
    completedTodo(indexPath: path)
  }
  
  func madePredicition(manager: MyoManager, prediction: Prediction) {}
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "CheckCell") as! CheckCell
    let item = todoData[indexPath.section].1[indexPath.row]
    cell.setupCell(todo: item.0, selection: item.1)
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return todoData.count
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return todoData[section].0
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return todoData[section].1.count
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    completedTodo(indexPath: indexPath)
  }
}
