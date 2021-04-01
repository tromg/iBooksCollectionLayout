import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        window.windowLevel = .normal + 1
        window.makeKeyAndVisible()
        window.rootViewController = InitialVC()
        window.frame = UIScreen.main.bounds

        self.window = window

        return true
    }
}

