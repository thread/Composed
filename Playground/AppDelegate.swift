import UIKit
import Composed

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        let list1
            = PeopleArrayDataSource(elements: [
            Person(name: "Shaps Benkau", age: 38),
            Person(name: "Uwe", age: 60),
            Person(name: "Anne", age: 35)
        ])

        let list2 = PeopleArrayDataSource(elements: [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph Duffy", age: 24)
        ])

        let list3 = PeopleArrayDataSource(elements: [
            Person(name: "Stuart", age: 30),
            Person(name: "Dan", age: 12)
        ])

        let list4 = PeopleArrayDataSource(elements: [
            Person(name: "Stuart", age: 30),
            Person(name: "Dan", age: 12)
            ])

        let sectioned = PeopleSectionedDataSource(contentsOf: [
            list1.store.elements,
            list2.store.elements
        ])

        let innerComposed = ComposedDataSource(children: [list3])

        let countries = PeopleSectionedDataSource(elements: countryNames)

        let segmented = SegmentedDataSource(children: [innerComposed, list1])
        let composed = ComposedDataSource(children: [sectioned, segmented, countries, list4])

        countries.title = "Countries"

        let layout = FlowLayout()
        layout.globalFooter.prefersFollowContent = true
        let controller = DataSourceViewController(dataSource: composed, layout: layout)

        controller.navigationItem.largeTitleDisplayMode = .never
        controller.collectionView.backgroundColor = .white

        let tab = window?.rootViewController as? UITabBarController
        let nav = tab?.viewControllers?.first as? UINavigationController
        nav?.navigationBar.prefersLargeTitles = true

        nav?.navigationBar.isHidden = false
        nav?.pushViewController(controller, animated: false)

        print(controller.dataSource!.debugDescription)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            list.removeAll()
            segmented.setSelected(index: 1)
            print(controller.dataSource!.debugDescription)
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
