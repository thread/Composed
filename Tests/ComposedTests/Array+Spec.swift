import Quick
import Nimble

@testable import Composed

final class ArrayDataStore_Spec: QuickSpec {

    override func spec() {
        super.spec()

        describe("Given an array of elements") {
            var elements: [Int]!
            var source: ArrayDataSource<Int>!

            beforeEach {
                elements = [1, 2, 3, 4, 5, 6, 7, 8, 9]
                source = ArrayDataSource(elements: elements)
            }

            it("should contain 1 section") {
                expect(source.numberOfSections).to(equal(1))
            }

            it("should contain 9 elements") {
                expect(source.numberOfElements(in: 0)).to(equal(elements.count))
            }
        }
    }

}
