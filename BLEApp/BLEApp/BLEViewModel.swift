//
//  BLEViewModel.swift
//  BLEApp
//
//  Created by Bharat Shilavat on 14/12/25.
//

import Foundation
import CoreBluetooth

enum BLEConnectionState {
    case idle
    case scanning
    case connecting
    case connected
    case disconnected
}

protocol BLEManagerProtocol {
    
    var onDevicesUpdated: (([BLEDevice]) -> Void)? { get set }
    
    var onConnected: ((CBPeripheral) -> Void)? { get set }
    var onDisconnected: ((CBPeripheral, Error?) -> Void)? { get set }
    var onRSSIUpdated: ((NSNumber) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    
    func startScan()
    func stopScan()
    func connect(to device: BLEDevice)
    func disconnect()
}


final class BLEViewModel {
    
    private var bleManager: BLEManagerProtocol
    
    private(set) var devices: [BLEDevice] = []
    private(set) var connectionState: BLEConnectionState = .idle
    private(set) var rssi: Int?
    
    var onUpdate: (() -> Void)?
    var onError: ((String) -> Void)?
    
    init(bleManager: BLEManagerProtocol) {
        self.bleManager = bleManager
        
        self.bleManager.onDevicesUpdated = { [weak self] devices in
            self?.devices = devices
            self?.onUpdate?()
        }
        
        self.bleManager.onConnected = { [weak self] _ in
            self?.connectionState = .connected
            self?.onUpdate?()
        }
        
        self.bleManager.onDisconnected = { [weak self] _, error in
            self?.connectionState = .disconnected
            if let error = error {
                self?.onError?(error.localizedDescription)
            }
            self?.onUpdate?()
        }
        
        self.bleManager.onRSSIUpdated = { [weak self] rssi in
            self?.rssi = rssi.intValue
            self?.onUpdate?()
        }
        
        self.bleManager.onError = { [weak self] error in
            self?.onError?(error.localizedDescription)
        }
    }
    
    func startScan() {
        connectionState = .scanning
        bleManager.startScan()
    }
    
    func stopScan() {
        bleManager.stopScan()
        connectionState = .idle
    }
    
    func connect(index: Int) {
        connectionState = .connecting
        bleManager.connect(to: devices[index])
    }
    
    func disconnect() {
        bleManager.disconnect()
    }
}
