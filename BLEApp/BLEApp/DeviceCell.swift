//
//  DeviceCell.swift
//  BLEApp
//
//  Created by Bharat Shilavat on 14/12/25.
//

import Foundation
import UIKit

final class DeviceCell: UITableViewCell {
    
    static let identifier = "DeviceCell"
    
    func configure(with device: BLEDevice) {
        textLabel?.text = device.name
        detailTextLabel?.text = "RSSI: \(device.rssi)"
    }
}
