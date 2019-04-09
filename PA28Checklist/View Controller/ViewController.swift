//
//  ViewController.swift
//  PA28Checklist
//
//  Created by Alexander H List on 11/11/18.
//  Copyright © 2018 Alexander H List. All rights reserved.
//

import UIKit

class CheckCell: UITableViewCell {
  @IBOutlet weak var todoLabel: UILabel!
  
  func setupCell(todo: String, selection: Bool) {
    todoLabel.text = todo
    accessoryType = selection ? .checkmark : .none
  }
}


class ViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
    tableView.reloadData()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


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
    var item = todoData[indexPath.section].1[indexPath.row]
    item.1 = !item.1
    todoData[indexPath.section].1[indexPath.row] = item
    tableView.reloadRows(at: [indexPath], with: .none)
  }
}