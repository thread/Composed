import UIKit
import Composed

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let tab = window?.rootViewController as? UITabBarController
        
        if let nav = tab?.viewControllers?.first as? UINavigationController {
            nav.navigationBar.prefersLargeTitles = true

            nav.navigationBar.isHidden = false
            nav.pushViewController(makeVerticalViewController(), animated: false)
        }
        
        if let nav = tab?.viewControllers?[1] as? UINavigationController {
            nav.navigationBar.prefersLargeTitles = true
            
            nav.navigationBar.isHidden = false
            nav.pushViewController(makeHorizontalViewController(), animated: false)
        }
        
        if let nav = tab?.viewControllers?[2] as? UINavigationController {
            nav.navigationBar.prefersLargeTitles = true
            
            nav.navigationBar.isHidden = false
            nav.pushViewController(makeMixedViewController(), animated: false)
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
    
    private func makeVerticalViewController() -> UIViewController {
        let list1 = Family(elements: [
            Person(name: "Shaps Benkau", age: 38),
            Person(name: "Uwe", age: 60),
            Person(name: "Anne", age: 35)
            ])
        
        let list2 = Friends(elements: [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph Duffy", age: 24)
            ])
        
        let list3 = Coworkers(elements: [
            Person(name: "Stuart", age: 30),
            Person(name: "Dan", age: 12)
        ], title: "Coworkers", allowsMultipleSelection: false)
        
        let list4 = Websites(elements: [
            Person(name: "Youtube", age: 30),
            Person(name: "Google", age: 12)
            ])
        
        let sectioned = FamilyAndFriends(contentsOf: [
            list1.store.elements,
            list2.store.elements
        ])

        sectioned.title = "Family & Friends"
        
        let innerComposed = ComposedDataSource(children: [list3])
        
        let countries = Countries(elements: countryNames)
        countries.title = "Countries"

        let segmented = SegmentedDataSource(children: [innerComposed, list1])
        let composed = ListDataSource(children: [sectioned, segmented, countries, list4])

        let layout = FlowLayout()
//        layout.globalFooterConfiguration.prefersFollowContent = true
        layout.globalHeaderConfiguration.pinsToBounds = false
//        layout.globalHeaderConfiguration.pinsToContent = true
        let controller = DataSourceViewController(dataSource: composed, layout: layout)
        
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.title = "Vertical"
        controller.collectionView.backgroundColor = .white
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            let context = FlowLayoutInvalidationContext()
//            context.invalidateGlobalHeader = true
//
//            controller.collectionView.performBatchUpdates({
//                controller.collectionView.collectionViewLayout.invalidateLayout(with: context)
//            }, completion: nil)
//        }
        
        return controller
    }
    
    private func makeHorizontalViewController() -> UIViewController {
        let variableSizedPeople = [
            Person(name: "Person 1", age: 1),
            Person(name: "Person 2 with a long name", age: 2),
            Person(name: "P 3", age: 3),
            Person(name: "Person 4", age: 4),
            Person(name: "Person 5", age: 5),
            Person(name: "Person 6", age: 6),
            Person(name: "Person 7", age: 7),
        ]
        let fixedSizedPeople = [
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
        ]
        let composedEmbedded1 = ComposedDataSource(children: [
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Automatic (not uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
//            EmbeddingDataSource(
//                child: Family(elements: variableSizedPeople, title: "Fixed Height (120)"),
//                sizeMode: .fixedHeight(120)
//            ),
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Fixed Width (250)", allowsMultipleSelection: false),
                sizeMode: .automatic(isUniform: false)
            ),
            EmbeddingDataSource(
                child: Family(elements: fixedSizedPeople, title: "Automatic (uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Automatic (not uniform)", allowsMultipleSelection: false),
                sizeMode: .automatic(isUniform: false)
            ),
            //            EmbeddingDataSource(
            //                child: Family(elements: variableSizedPeople, title: "Fixed Height (120)"),
            //                sizeMode: .fixedHeight(120)
            //            ),
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Fixed Width (250)"),
                sizeMode: .automatic(isUniform: false)
            ),
            EmbeddingDataSource(
                child: Family(elements: fixedSizedPeople, title: "Automatic (uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
        ])
        
        let composedEmbedded2 = ComposedDataSource(children: [
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Automatic (not uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
            //            EmbeddingDataSource(
            //                child: Family(elements: variableSizedPeople, title: "Fixed Height (120)"),
            //                sizeMode: .fixedHeight(120)
            //            ),
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Fixed Width (250)"),
                sizeMode: .automatic(isUniform: false)
            ),
            EmbeddingDataSource(
                child: Family(elements: fixedSizedPeople, title: "Automatic (uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Automatic (not uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
            //            EmbeddingDataSource(
            //                child: Family(elements: variableSizedPeople, title: "Fixed Height (120)"),
            //                sizeMode: .fixedHeight(120)
            //            ),
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Fixed Width (250)"),
                sizeMode: .automatic(isUniform: false)
            ),
            EmbeddingDataSource(
                child: Family(elements: fixedSizedPeople, title: "Automatic (uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
            ])

        let controller = DataSourceViewController(dataSource: ListDataSource(children: [composedEmbedded1, composedEmbedded2]))
        
        controller.navigationItem.largeTitleDisplayMode = .never
        controller.collectionView.backgroundColor = .white
        
        return controller
    }
    
    private func makeMixedViewController() -> UIViewController {
        let variableSizedPeople = [
            Person(name: "Person 1", age: 1),
            Person(name: "Person 2 with a long name", age: 2),
            Person(name: "P 3", age: 3),
            Person(name: "Person 4", age: 4),
            Person(name: "Person 5", age: 5),
            Person(name: "Person 6", age: 6),
            Person(name: "Person 7", age: 7),
        ]
        let fixedSizedPeople = [
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
            Person(name: "Person 1", age: 1),
        ]
        let composedEmbedded = ComposedDataSource(children: [
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Automatic (not uniform)"),
                sizeMode: .automatic(isUniform: false)
            ),
//            EmbeddingDataSource(
//                child: Family(elements: variableSizedPeople, title: "Fixed Height (120)"),
//                sizeMode: .fixedHeight(120)
//            ),
            EmbeddingDataSource(
                child: Family(elements: variableSizedPeople, title: "Fixed Width (250)"),
                sizeMode: .fixedWidth(250)
            ),
            EmbeddingDataSource(
                child: Family(elements: fixedSizedPeople, title: "Automatic (uniform)"),
                sizeMode: .automatic(isUniform: true)
            ),
            ])
        
        let list1 = Family(elements: [
            Person(name: "Shaps Benkau", age: 38),
            Person(name: "Uwe", age: 60),
            Person(name: "Anne", age: 35)
            ])
        
        let list2 = Friends(elements: [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph Duffy", age: 24)
            ])
        
        let list3 = Coworkers(elements: [
            Person(name: "Stuart", age: 30),
            Person(name: "Dan", age: 12)
            ])
        
        let list4 = Websites(elements: [
            Person(name: "Youtube", age: 30),
            Person(name: "Google", age: 12)
            ])
        
        let sectioned = FamilyAndFriends(contentsOf: [
            list1.store.elements,
            list2.store.elements
            ])
        
        let innerComposed = ComposedDataSource(children: [list3])
        
        let countries = Countries(elements: countryNames)
        
        let segmented = SegmentedDataSource(children: [innerComposed, list1])
        let composed = ComposedDataSource(children: [sectioned, composedEmbedded, segmented, countries, list4])
        
        countries.title = "Countries"
        
        let layout = FlowLayout()
        layout.globalFooterConfiguration.prefersFollowContent = true
        let controller = DataSourceViewController(dataSource: composed, layout: layout)
        
//        controller.navigationItem.largeTitleDisplayMode = .never
        controller.collectionView.backgroundColor = .white
        
        return controller
    }

}
