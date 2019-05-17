//
//  MyoManager.swift
//  PA28Checklist
//
//  Created by Alexander H List on 4/22/19.
//  Copyright © 2019 Alexander H List. All rights reserved.
//

//shouldNotifyInBackground
//attachByIdentifier for autoconnect

import Foundation

protocol MyoManagerDelegate {
  func recognizedGesture(manager: MyoManager)
  
  /// On main thread, that a prediction happened.
  /// For updating the UI
  func madePredicition(manager: MyoManager, prediction: Prediction)
}

class MyoManager {
  var delegate: MyoManagerDelegate?
  fileprivate var myo: TLMMyo!
  fileprivate let modeler = MyoModelRunner()
  
  fileprivate var lastRecognition = Date()
  fileprivate var recognitionDebounceInterval = 1.0
  fileprivate var recognitionThreshold = 0.93
  fileprivate var recognitionPredictionAverageCount = 5
  
  fileprivate var datum = Datum()
  fileprivate let startTime = Date()
  
  var printCSV: Bool = false
  var printClassification: Bool = true
  
  init() {
    TLMHub.shared()?.shouldNotifyInBackground = true
    TLMHub.shared()?.shouldSendUsageData = false
    TLMHub.shared()?.lockingPolicy = .none
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.onConnect(notification:)), name: NSNotification.Name.TLMHubDidConnectDevice, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.onEMGData(notification:)), name: NSNotification.Name.TLMMyoDidReceiveEmgEvent, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.onAccelerometerData(notification:)), name: NSNotification.Name.TLMMyoDidReceiveAccelerometerEvent, object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(self.onRotationData(notification:)), name: NSNotification.Name.TLMMyoDidReceiveOrientationEvent, object: nil)
  }
}

extension MyoManager {
  @objc func onConnect(notification: Notification!) {
    guard let myo = TLMHub.shared()?.myoDevices()?.first as? TLMMyo else { return }
    self.myo = myo
    myo.setStreamEmg(.enabled)
  }
  
  @objc func onEMGData(notification: Notification!) {
    guard let emg = notification.userInfo?[kTLMKeyEMGEvent] as? TLMEmgEvent,
      let data = emg.rawData as? [NSNumber] else { return }
    datum.date = emg.timestamp.timeIntervalSince(startTime)
    datum.emg = data
    processData()
  }
  
  @objc func onAccelerometerData(notification: Notification!) {
    guard let accel = notification.userInfo?[kTLMKeyAccelerometerEvent] as? TLMAccelerometerEvent else { return }
    let data = accel.vector
    datum.date = accel.timestamp.timeIntervalSince(startTime)
    datum.acceleration = data
    processData()
  }
  
  @objc func onRotationData(notification: Notification!) {
    guard let rot = notification.userInfo?[kTLMKeyOrientationEvent] as? TLMOrientationEvent else { return }
    let data = rot.quaternion
    datum.date = rot.timestamp.timeIntervalSince(startTime)
    datum.quaternion = data
    processData()
  }
  
  func processData() {
    guard datum.ready else { return }
    if printCSV {
      print(datum)
    }
    modeler.addDataPoint(point: datum)
    if !modeler.isPredicting {
      OperationQueue.main.addOperation { [weak self] in
        guard let this = self else { return }
        guard let prediction = this.modeler.makePrediction() else { return }
        if this.printClassification {
          print(prediction)
        }
        DispatchQueue.main.async {
          this.delegate?.madePredicition(manager: this, prediction: prediction)
          this.debounceRecognition()
        }
      }
    }
    datum = Datum()
  }
  
  /// Handles recognition and it's debouncing
  func debounceRecognition() {
    guard Date().timeIntervalSince(lastRecognition) > recognitionDebounceInterval else { return }
    guard modeler.averageOfLast(pointCount: recognitionPredictionAverageCount)?.gesture ?? 0 > recognitionThreshold else { return }
    print(modeler.averageOfLast(pointCount: recognitionPredictionAverageCount)!.gesture)

    delegate?.recognizedGesture(manager: self)
    lastRecognition = Date()
  }
}
