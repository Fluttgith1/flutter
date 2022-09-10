//
//  Main.swift
//  Runner
//
//  Created by Alex Wallen on 9/8/22.
//

import Foundation
import AppKit


protocol NativeViewControllerDelegate: NSObjectProtocol {
    func didTapIncrementButton()
}

class NativeViewController: NSViewController {

  var count: Int?

  var labelText: String {
    get {
      let count = self.count ?? 0
      return "Flutter button tapped \(count) time\(count == 1 ? "" : "s")"
    }
  }

  var delegate: NativeViewControllerDelegate?

  @IBOutlet weak var incrementLabel: NSTextField!

  @IBAction func handleIncrement(_ sender: Any) {
    self.delegate?.didTapIncrementButton()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setState(for: 0)
  }

  func didReceiveIncrement() {
    setState(for: (self.count ?? 0) + 1)
  }

  func setState(for count: Int) {
    self.count = count
    self.incrementLabel.stringValue = labelText
  }

}
