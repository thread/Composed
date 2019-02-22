import UIKit
import Composed

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        let family = PeopleDataSource(array: [
            Person(name: "Shaps Benkau", age: 38),
            Person(name: "Uwe", age: 60),
            Person(name: "Anne", age: 35)
        ])

        family.title = "Family"

        let friends = PeopleDataSource(array: [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph Duffy", age: 24)
        ])

        friends.title = "Friends"

        let countries = PeopleDataSource(array: countryNames)
        countries.title = "Countries"
        
        let composed = ComposedDataSource()

        composed.append(family)
        composed.append(friends)
        composed.append(countries)

        let layout = FlowLayout()

        layout.globalHeader.pinsToBounds = true
        layout.globalHeader.pinsToContent = true
        layout.globalHeader.prefersFollowContent = false
        layout.globalHeader.inset = 20

//        layout.globalFooter.pinsToBounds = true
//        layout.globalFooter.pinsToContent = true
//        layout.globalFooter.prefersFollowContent = true
//        layout.globalFooter.respectsSafeArea = true
//        layout.globalFooter.respectSafeAreaForSize = false

        let global = RootDataSource(child: composed)
        let controller = DataSourceViewController(dataSource: global, layout: layout)
        let nav = window?.rootViewController as? UINavigationController

        controller.edgesForExtendedLayout = [.top]
        controller.extendedLayoutIncludesOpaqueBars = true

        controller.navigationItem.title = "Composed"

        nav?.navigationBar.isHidden = false
        nav?.navigationBar.isTranslucent = false
        nav?.navigationBar.prefersLargeTitles = true
        nav?.pushViewController(controller, animated: false)

        return true
    }

    private var countryNames: [Person] {
        var countries: [String] = []

        for code in NSLocale.isoCountryCodes as [String] {
            let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
            let name = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id) ?? "Country not found for code: \(code)"
            countries.append(name)
        }
        return countries.map { Person(name: $0, age: 18) }
    }

}

