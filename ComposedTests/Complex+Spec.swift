import Quick
import Nimble

@testable import Composed

final class Complex_Spec: QuickSpec {

    override func spec() {
        super.spec()

        var list1: ArrayDataSource<Int>!
        var list2: ArrayDataSource<Int>!
        var list3: ArrayDataSource<Int>!
        var empty1: EmptyDataSource!
        var empty2: EmptyDataSource!
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

            empty1 = EmptyDataSource()
            empty2 = EmptyDataSource()

            countries = SectionedDataSource(elements: countryNames)
            segmented = SegmentedDataSource(children: [empty1, list1])
            innerComposed = ComposedDataSource(children: [segmented, list3])
            outerComposed = ComposedDataSource(children: [sectioned, innerComposed, countries, empty2])
        }

        describe("Given a dataSource heirachy") {
            context("when no changes have occurred") {
                it("section counts should be as expected") {
                    expect(list1.numberOfSections).to(equal(1))
                    expect(list2.numberOfSections).to(equal(1))
                    expect(list3.numberOfSections).to(equal(1))
                    expect(sectioned.numberOfSections).to(equal(2))
                    expect(countries.numberOfSections).to(equal(1))
                    expect(segmented.numberOfSections).to(equal(1))
                    expect(innerComposed.numberOfSections).to(equal(2))
                    expect(outerComposed.numberOfSections).to(equal(6))
                }

                it("local section data should be valid") {
                    let actual0 = outerComposed.localSection(for: 0)
                    let actual1 = outerComposed.localSection(for: 1)
                    let actual2 = outerComposed.localSection(for: 2)
                    let actual3 = outerComposed.localSection(for: 3)
                    let actual4 = outerComposed.localSection(for: 4)
                    let actual5 = outerComposed.localSection(for: 5)

                    expect(DataSourceHashableWrapper(actual0.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual1.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual2.dataSource)).to(equal(DataSourceHashableWrapper(empty1)))
                    expect(DataSourceHashableWrapper(actual3.dataSource)).to(equal(DataSourceHashableWrapper(list3)))
                    expect(DataSourceHashableWrapper(actual4.dataSource)).to(equal(DataSourceHashableWrapper(countries)))
                    expect(DataSourceHashableWrapper(actual5.dataSource)).to(equal(DataSourceHashableWrapper(empty2)))
                }
            }

            context("when segmented.selectedChild == nil") {
                beforeEach {
                    segmented.setSelected(index: nil)
                }

                it("section counts should be as expected") {
                    expect(segmented.numberOfSections).to(equal(0))
                    expect(innerComposed.numberOfSections).to(equal(1))
                    expect(outerComposed.numberOfSections).to(equal(5))
                }

                it("local section data should be valid") {
                    let actual0 = outerComposed.localSection(for: 0)
                    let actual1 = outerComposed.localSection(for: 1)
                    let actual2 = outerComposed.localSection(for: 2)
                    let actual3 = outerComposed.localSection(for: 3)
                    let actual4 = outerComposed.localSection(for: 4)

                    expect(DataSourceHashableWrapper(actual0.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual1.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual2.dataSource)).to(equal(DataSourceHashableWrapper(list3)))
                    expect(DataSourceHashableWrapper(actual3.dataSource)).to(equal(DataSourceHashableWrapper(countries)))
                    expect(DataSourceHashableWrapper(actual4.dataSource)).to(equal(DataSourceHashableWrapper(empty2)))
                }
            }

            context("when segmented is removed from innerComposed") {
                beforeEach {
                    innerComposed.remove(dataSource: segmented)
                }

                it("section counts should be as expected") {
                    expect(innerComposed.numberOfSections).to(equal(1))
                    expect(outerComposed.numberOfSections).to(equal(5))
                }

                it("local section data should be valid") {
                    let actual0 = outerComposed.localSection(for: 0)
                    let actual1 = outerComposed.localSection(for: 1)
                    let actual2 = outerComposed.localSection(for: 2)
                    let actual3 = outerComposed.localSection(for: 3)
                    let actual4 = outerComposed.localSection(for: 4)

                    expect(DataSourceHashableWrapper(actual0.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual1.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual2.dataSource)).to(equal(DataSourceHashableWrapper(list3)))
                    expect(DataSourceHashableWrapper(actual3.dataSource)).to(equal(DataSourceHashableWrapper(countries)))
                    expect(DataSourceHashableWrapper(actual4.dataSource)).to(equal(DataSourceHashableWrapper(empty2)))
                }
            }

            context("when all children are removed from innerComposed") {
                beforeEach {
                    innerComposed.removeAll()
                }

                it("section counts should be as expected") {
                    expect(innerComposed.numberOfSections).to(equal(0))
                    expect(outerComposed.numberOfSections).to(equal(4))
                }

                it("local section data should be valid") {
                    let actual0 = outerComposed.localSection(for: 0)
                    let actual1 = outerComposed.localSection(for: 1)
                    let actual2 = outerComposed.localSection(for: 2)
                    let actual3 = outerComposed.localSection(for: 3)

                    expect(DataSourceHashableWrapper(actual0.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual1.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual2.dataSource)).to(equal(DataSourceHashableWrapper(countries)))
                    expect(DataSourceHashableWrapper(actual3.dataSource)).to(equal(DataSourceHashableWrapper(empty2)))
                }
            }

            context("when all children are removed from outerComposed") {
                beforeEach {
                    outerComposed.removeAll()
                }

                it("section counts should be as expected") {
                    expect(outerComposed.numberOfSections).to(equal(0))
                }
            }

            context("when a new child is added to innerComposed") {
                beforeEach {
                    newList = ArrayDataSource(elements: [0])
                    innerComposed.insert(dataSource: newList, at: 0)
                }

                it("section counts should be as expected") {
                    expect(innerComposed.numberOfSections).to(equal(3))
                    expect(outerComposed.numberOfSections).to(equal(7))
                }

                it("local section data should be valid") {
                    let actual0 = outerComposed.localSection(for: 0)
                    let actual1 = outerComposed.localSection(for: 1)
                    let actual2 = outerComposed.localSection(for: 2)
                    let actual3 = outerComposed.localSection(for: 3)
                    let actual4 = outerComposed.localSection(for: 4)
                    let actual5 = outerComposed.localSection(for: 5)
                    let actual6 = outerComposed.localSection(for: 6)

                    expect(DataSourceHashableWrapper(actual0.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual1.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual2.dataSource)).to(equal(DataSourceHashableWrapper(newList)))
                    expect(DataSourceHashableWrapper(actual3.dataSource)).to(equal(DataSourceHashableWrapper(empty1)))
                    expect(DataSourceHashableWrapper(actual4.dataSource)).to(equal(DataSourceHashableWrapper(list3)))
                    expect(DataSourceHashableWrapper(actual5.dataSource)).to(equal(DataSourceHashableWrapper(countries)))
                    expect(DataSourceHashableWrapper(actual6.dataSource)).to(equal(DataSourceHashableWrapper(empty2)))
                }
            }

            context("when a new child is inserted at 0 and the last element is removed from outerComposed") {
                beforeEach {
                    newList = ArrayDataSource(elements: [0])
                    var children = outerComposed.children
                    children.removeLast()
                    children.insert(newList, at: 0)
                    outerComposed.replace(children, animated: false)
                }

                it("section counts should be as expected") {
                    expect(outerComposed.numberOfSections).to(equal(6))
                }

                it("local section data should be valid") {
                    let actual0 = outerComposed.localSection(for: 0)
                    let actual1 = outerComposed.localSection(for: 1)
                    let actual2 = outerComposed.localSection(for: 2)
                    let actual3 = outerComposed.localSection(for: 3)
                    let actual4 = outerComposed.localSection(for: 4)
                    let actual5 = outerComposed.localSection(for: 5)

                    expect(DataSourceHashableWrapper(actual0.dataSource)).to(equal(DataSourceHashableWrapper(newList)))
                    expect(DataSourceHashableWrapper(actual1.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual2.dataSource)).to(equal(DataSourceHashableWrapper(sectioned)))
                    expect(DataSourceHashableWrapper(actual3.dataSource)).to(equal(DataSourceHashableWrapper(empty1)))
                    expect(DataSourceHashableWrapper(actual4.dataSource)).to(equal(DataSourceHashableWrapper(list3)))
                    expect(DataSourceHashableWrapper(actual5.dataSource)).to(equal(DataSourceHashableWrapper(countries)))
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
