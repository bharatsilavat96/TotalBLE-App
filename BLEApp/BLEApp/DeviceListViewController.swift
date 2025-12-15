//
//  BLEViewController.swift
//  BLEApp
//
//  Created by Bharat Shilavat on 14/12/25.
//

import Foundation
import UIKit
import CoreBluetooth

final class DeviceListViewController: UIViewController {

    private let viewModel: BLEViewModel
    private let tableView = UITableView()
    private let statusLabel = UILabel()
    private let rssiLabel = UILabel()
    private let disconnectButton = UIButton(type: .system)


    init(viewModel: BLEViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "BLE Devices"
        view.backgroundColor = .white

        setupTableView()
        setupNavigationBar()
        bindViewModel()
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Scan",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(scanTapped))

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(stopTapped))
    }

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.register(DeviceCell.self, forCellReuseIdentifier: DeviceCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
    }
    private func setupStatusUI() {
        statusLabel.textAlignment = .center
        rssiLabel.textAlignment = .center

        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.addTarget(self,
                                   action: #selector(disconnectTapped),
                                   for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            statusLabel,
            rssiLabel,
            disconnectButton
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.frame = CGRect(x: 0, y: 100,
                              width: view.bounds.width, height: 120)

        view.addSubview(stack)
    }

    
    private func bindViewModel() {

        viewModel.onUpdate = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateStatus()
            }
        }

        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                self?.showAlert(message)
            }
        }
    }

    private func updateStatus() {
        statusLabel.text = "Status: \(viewModel.connectionState)"

        if let rssi = viewModel.rssi {
            rssiLabel.text = "RSSI: \(rssi) dBm"
            rssiLabel.textColor = rssi < -85 ? .red : .black
        }
    }

    @objc private func disconnectTapped() {
        viewModel.disconnect()
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "BLE Error",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }


    @objc private func scanTapped() {
        viewModel.startScan()
    }

    @objc private func stopTapped() {
        viewModel.stopScan()
    }
}

// MARK: - TableView
extension DeviceListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.devices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceCell.identifier,
                                                 for: indexPath)
        as! DeviceCell
        cell.configure(with: viewModel.devices[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        viewModel.connect(index: indexPath.row)
    }
}
