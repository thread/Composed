import Quick
import Nimble

@testable import Composed

final class Complex_Spec: QuickSpec {

    override func spec() {
        super.spec()

        var list1: ArrayDataSource<Int>!
        var list2: ArrayDataSource<Int>!
        var list3: ArrayDataSource<Int>!
        var sectioned: SectionedDataSource<Int>!
        var countries: SectionedDataSource<String>!
        var segmented: SegmentedDataSource!
        var innerComposed: ComposedDataSource!
        var outerComposed: ComposedDataSource!

        var newList: ArrayDataSource<Int>!

        beforeEach {
            list1 = ArrayDataSource(elements: [1, 2, 3])
            list2 = ArrayDataSource(elements: [9, 8])
            list3 = ArrayDataSource(elements: [4, 5, 6, 7])

            sectioned = SectionedDataSource(contentsOf: [
                list1.store.elements,
                list2.store.elements,
            ])

            countries = SectionedDataSource(elements: countryNames)
            segmented = SegmentedDataSource(children: [EmptyDataSource(), list1])
            innerComposed = ComposedDataSource(children: [segmented, list3])
            outerComposed = ComposedDataSource(children: [sectioned, innerComposed, countries, EmptyDataSource()])
        }

        describe("Given a complex dataSource heirachy") {
            it("the dataSource's should have the expected counts") {
                expect(list1.numberOfSections).to(equal(1))
                expect(list2.numberOfSections).to(equal(1))
                expect(list3.numberOfSections).to(equal(1))
                expect(sectioned.numberOfSections).to(equal(2))
                expect(countries.numberOfSections).to(equal(1))
                expect(segmented.numberOfSections).to(equal(1))
                expect(innerComposed.numberOfSections).to(equal(2))
                expect(outerComposed.numberOfSections).to(equal(6))
            }

            context("when segmented.selectedChild == nil") {
                beforeEach {
                    segmented.setSelected(index: nil)
                }
                
                it("the dataSource counts should be adjusted") {
                    expect(segmented.numberOfSections).to(equal(0))
                    expect(innerComposed.numberOfSections).to(equal(1))
                    expect(outerComposed.numberOfSections).to(equal(5))
                }
            }

            context("when segmented is removed from innerComposed") {
                beforeEach {
                    innerComposed.remove(dataSource: segmented)
                }

                it("the dataSource counts should be adjusted") {
                    expect(innerComposed.numberOfSections).to(equal(1))
                    expect(outerComposed.numberOfSections).to(equal(5))
                }
            }

            context("when all children are removed from innerComposed") {
                beforeEach {
                    innerComposed.removeAll()
                }

                it("the dataSource counts should be adjusted") {
                    expect(innerComposed.numberOfSections).to(equal(0))
                    expect(outerComposed.numberOfSections).to(equal(4))
                }
            }

            context("when all children are removed from outerComposed") {
                it("the dataSource counts should be adjusted") {
                    outerComposed.removeAll()
                    expect(outerComposed.numberOfSections).to(equal(0))
                }
            }

            context("when a new child is added to innerComposed") {
                beforeEach {
                    newList = ArrayDataSource(elements: [0])
                    innerComposed.insert(dataSource: newList, at: 0)
                }

                it("the dataSource counts should be adjusted") {
                    expect(innerComposed.numberOfSections).to(equal(3))
                    expect(outerComposed.numberOfSections).to(equal(7))
                }
            }
        }
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
