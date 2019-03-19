import UIKit
import Composed

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        let family = [
            Person(name: "Shaps Benkau", age: 38),
            Person(name: "Uwe", age: 60),
            Person(name: "Anne", age: 35)
        ]

        let friends = [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph Duffy", age: 24)
        ]

        let people = PeopleDataSource(elements: [])
        people.title = "People"
        people.append(elements: family)
        people.append(elements: friends)

        let names = countryNames
        let countries = PeopleDataSource(elements: names)
        countries.title = "Countries"

        let list = ListDataSource()
        list.append(people)
        list.append(countries)

        let layout = FlowLayout()
        layout.globalFooter.prefersFollowContent = true
        let controller = DataSourceViewController(dataSource: list, layout: layout)
        controller.navigationItem.largeTitleDisplayMode = .always

        let tab = window?.rootViewController as? UITabBarController
        let nav = tab?.viewControllers?.first as? UINavigationController
        nav?.navigationBar.prefersLargeTitles = true

        nav?.navigationBar.isHidden = false
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

