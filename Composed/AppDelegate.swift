import UIKit
import DataSources

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        let controller = PeopleViewController()
        (window?.rootViewController as? UINavigationController)?.pushViewController(controller, animated: false)

        return true
    }
}

