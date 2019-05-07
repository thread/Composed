import UIKit
import Composed

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

//        let family = [
//            Person(name: "Shaps Benkau", age: 38),
//            Person(name: "Uwe", age: 60),
//            Person(name: "Anne", age: 35)
//        ]

        let friends = [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph Duffy", age: 24)
        ]

//        let familyDs = PeopleArrayDataSource(elements: family)
        let friendsDs = PeopleArrayDataSource(elements: friends)
        let people = SegmentedDataSource(children: [friendsDs])
        friendsDs.title = "Friends"
        people.setSelected(index: nil, animated: false)

        let names = countryNames
        let countries = PeopleSectionedDataSource(elements: names)
        countries.title = "Countries"

        let list = ListDataSource(children: [
            people, countries
        ])

        let layout = FlowLayout()
        layout.globalFooter.prefersFollowContent = true
        let controller = DataSourceViewController(dataSource: list, layout: layout)
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.collectionView.backgroundColor = .white

        let tab = window?.rootViewController as? UITabBarController
        let nav = tab?.viewControllers?.first as? UINavigationController
        nav?.navigationBar.prefersLargeTitles = true

        nav?.navigationBar.isHidden = false
        nav?.pushViewController(controller, animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            list.removeAll()
            people.setSelected(index: 0, animated: true)
        }

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
