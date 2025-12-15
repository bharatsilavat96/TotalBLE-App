//
//  SceneDelegate.swift
//  BLEApp
//
//  Created by Bharat Shilavat on 14/12/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let bleManager = BLEManager()
        let viewModel = BLEViewModel(bleManager: bleManager)
        let rootVC = DeviceListViewController(viewModel: viewModel)

        let navController = UINavigationController(rootViewController: rootVC)

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

/*
 Typical BLE RSSI Ranges & Meanings
 Excellent (Strong): > -60 dBm (e.g., -50 dBm) - Very close, ideal for setup/updates.
 Good/Fair: -60 dBm to -85 dBm - Relatively close, reliable for data.
 Weak/Poor: < -85 dBm (e.g., -90 dBm) - Far away, high chance of packet loss, near disconnection.
 Out of Range: -200 dBm (or similar) - Signal not detected.
 Key Factors Affecting RSSI
 Distance: The primary factor; signal strength drops with distance.
 Obstacles: Walls, furniture, and people block signals.
 Interference: Other wireless devices, noise, and reflections weaken the signal.
 Device Hardware: Chipset, antenna design, and transmit power vary between manufacturers.
 
 You now support:
 ✅ Scan & stop scan
 ✅ Sort devices by RSSI
 ✅ Connect / disconnect
 ✅ Handle disconnect errors
 ✅ Discover services
 ✅ Discover characteristics
 ✅ Read characteristic
 ✅ Write characteristic
 ✅ Enable / disable notifications
 ✅ Receive live data (notify)
 ✅ Read RSSI
 ✅ Cache services & characteristics
 ✅ Fully observable from ViewModel
 */
