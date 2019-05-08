import Quick
import Nimble

@testable import Composed

final class Complex_Spec: QuickSpec {

    override func spec() {
        super.spec()

        let list1 = ArrayDataSource(elements: [1, 2, 3])
        let list2 = ArrayDataSource(elements: [9, 8])

        let sectioned = SectionedDataSource(contentsOf: [
            list1.store.elements,
            list2.store.elements,
        ])

        let countries = SectionedDataSource(elements: countryNames)
        let segmented = SegmentedDataSource(children: [list2, list1])
        let empty = EmptyDataSource()
        let composed = ComposedDataSource(children: [sectioned, segmented, countries, empty])

        composed.removeAll()
    }

}

private var countryNames: [String] {
    var countries: [String] = []

    for code in NSLocale.isoCountryCodes {
        let id = NSLocale.localeIdentifier(fromComponents: [NSLocale.Key.countryCode.rawValue: code])
        let name = NSLocale(localeIdentifier: "en_UK").displayName(forKey: NSLocale.Key.identifier, value: id)!
        countries.append(name)
    }

    return countries
}
