//
//  BLEDeviceModel.swift
//  BLEApp
//
//  Created by Bharat Shilavat on 14/12/25.
//

import Foundation
import CoreBluetooth

struct BLEDevice {
    let id: UUID
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral
}
