import Quick
import Nimble

@testable import Composed

final class ArrayDataStore_Spec: QuickSpec {

    override func spec() {
        super.spec()

        describe("") {
            it("should be ok") {
                let store = ArrayDataStore(elements: [1, 2, 3])
                let source = BasicDataSource(store: store)
                expect(source.numberOfSections).to(equal(1))
                expect(source.numberOfElements(in: 0)).to(equal(3))
            }
        }
    }

}
