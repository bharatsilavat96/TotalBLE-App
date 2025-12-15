//
//  BLEManager.swift
//  BLEApp
//
//  Created by Bharat Shilavat on 14/12/25.
//

import Foundation
import CoreBluetooth


final class BLEManager: NSObject, BLEManagerProtocol {
    
    // MARK: - Public callbacks (to ViewModel)
    
    var onDevicesUpdated: (([BLEDevice]) -> Void)?
    
    var onConnected: ((CBPeripheral) -> Void)?
    var onDisconnected: ((CBPeripheral, Error?) -> Void)?
    var onServicesDiscovered: (([CBService]) -> Void)?
    var onCharacteristicsDiscovered: ((CBService, [CBCharacteristic]) -> Void)?
    var onValueUpdated: ((CBCharacteristic, Data?) -> Void)?
    var onRSSIUpdated: ((NSNumber) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Private properties
    
    private var centralManager: CBCentralManager!
    private var devices: [UUID: BLEDevice] = [:]
    private var connectedPeripheral: CBPeripheral?
    
    // Cache discovered services & characteristics
    private var services: [CBUUID: CBService] = [:]
    private var characteristics: [CBUUID: CBCharacteristic] = [:]
    
    // MARK: - Connection reliability
    
    private var shouldAutoReconnect = true
    private var lastConnectedDevice: BLEDevice?
    
    private var connectionTimeoutTimer: Timer?
    private let connectionTimeout: TimeInterval = 10 // seconds
    
    // RSSI monitoring
    private var rssiTimer: Timer?
    private let weakRSSIThreshold = -85 // dBm
    private let rssiCheckInterval: TimeInterval = 2
    
    // Background handling
    private var wasConnectedBeforeBackground = false
    
    // MARK: - Init
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Scanning
    
    func startScan() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth not powered on")
            return
        }
        
        devices.removeAll()
        
        // Scan options (allow duplicates to update RSSI continuously)
        let options: [String: Any] = [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ]
        
        centralManager.scanForPeripherals(
            withServices: nil, // or [CBUUID] to filter
            options: options
        )
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    // MARK: - Connection
    
    func connect(to device: BLEDevice) {
        lastConnectedDevice = device
        shouldAutoReconnect = true
        
        startConnectionTimeout()
        centralManager.connect(device.peripheral, options: [
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }
    
    
    func disconnect() {
        shouldAutoReconnect = false
        stopRSSIMonitoring()
        
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
    private func startConnectionTimeout() {
        stopConnectionTimeout()
        
        connectionTimeoutTimer = Timer.scheduledTimer(withTimeInterval: connectionTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.onError?(NSError(domain: "BLE", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Connection timeout"]))
        }
    }
    
    private func stopConnectionTimeout() {
        connectionTimeoutTimer?.invalidate()
        connectionTimeoutTimer = nil
    }
    
    
    // MARK: - RSSI
    
    func readRSSI() {
        connectedPeripheral?.readRSSI()
    }
    
    private func startRSSIMonitoring() {
        stopRSSIMonitoring()
        
        rssiTimer = Timer.scheduledTimer(withTimeInterval: rssiCheckInterval, repeats: true) { [weak self] _ in
            self?.connectedPeripheral?.readRSSI()
        }
    }
    
    private func stopRSSIMonitoring() {
        rssiTimer?.invalidate()
        rssiTimer = nil
    }
    
    
    // MARK: - Characteristic operations
    
    func readValue(for characteristic: CBCharacteristic) {
        connectedPeripheral?.readValue(for: characteristic)
    }
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType = .withResponse) {
        connectedPeripheral?.writeValue(data, for: characteristic, type: type)
    }
    
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        connectedPeripheral?.setNotifyValue(enabled, for: characteristic)
    }
}

//MARK: - ✅ Central Manager Delegate (Scanning / Connection lifecycle)
extension BLEManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            
        case .poweredOn:
            if let device = lastConnectedDevice,
               shouldAutoReconnect {
                central.connect(device.peripheral, options: nil)
            }
            
        case .poweredOff:
            connectedPeripheral = nil
            stopRSSIMonitoring()
            onError?(NSError(domain: "BLE", code: -3001, userInfo: [NSLocalizedDescriptionKey: "Bluetooth turned OFF"]))
            
        case .resetting:
            connectedPeripheral = nil
            services.removeAll()
            characteristics.removeAll()
            
        default:
            break
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        let device = BLEDevice(id: peripheral.identifier, name: peripheral.name ?? "Unknown", rssi: RSSI.intValue, peripheral: peripheral)
        
        devices[device.id] = device
        
        let sortedDevices = devices.values.sorted { $0.rssi > $1.rssi }
        onDevicesUpdated?(sortedDevices)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopConnectionTimeout()
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        services.removeAll()
        characteristics.removeAll()
        
        startRSSIMonitoring()
        
        onConnected?(peripheral)
        peripheral.discoverServices(nil)
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        onError?(error ?? NSError(domain: "BLE", code: -1))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        stopRSSIMonitoring()
        connectedPeripheral = nil
        
        onDisconnected?(peripheral, error)
        
        // Auto-reconnect only if unexpected
        if shouldAutoReconnect,
           let device = lastConnectedDevice,
           error != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.centralManager.connect(device.peripheral, options: nil)
            }
        }
    }
}

//MARK: - Peripheral Delegate (Services, Characteristics, Data) -
extension BLEManager: CBPeripheralDelegate {
    
    // MARK: - Services
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            onError?(error)
            return
        }
        
        guard let services = peripheral.services else { return }
        
        services.forEach { service in
            self.services[service.uuid] = service
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        onServicesDiscovered?(services)
    }
    
    // MARK: - Characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            onError?(error)
            return
        }
        
        guard let chars = service.characteristics else { return }
        
        chars.forEach { characteristic in
            characteristics[characteristic.uuid] = characteristic
        }
        
        onCharacteristicsDiscovered?(service, chars)
    }
    
    // MARK: - Value updates (Read / Notify)
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            onError?(error)
            return
        }
        
        onValueUpdated?(characteristic, characteristic.value)
    }
    
    // MARK: - Write response
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            onError?(error)
        }
    }
    
    // MARK: - Notification state
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            onError?(error)
        }
    }
    
    // MARK: - RSSI
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error { onError?(error)
            return
        }
        
        let rssiValue = RSSI.intValue
        onRSSIUpdated?(RSSI)
        
        if rssiValue < weakRSSIThreshold {
            onError?(NSError(domain: "BLE", code: -2001, userInfo: [
                NSLocalizedDescriptionKey: "Weak Bluetooth signal (\(rssiValue)dBm)"
            ]
                            ))
        }
    }
    
    // MARK: - Background -
    func appDidEnterBackground() {
        wasConnectedBeforeBackground = connectedPeripheral != nil
    }
    
    func appWillEnterForeground() {
        if wasConnectedBeforeBackground,
           let device = lastConnectedDevice {
            centralManager.connect(device.peripheral, options: nil)
        }
    }
}
