import Quick
import Nimble

@testable import Composed

final class DataStore_Spec: QuickSpec {

    override func spec() {
        describe("") {
            it("should be ok") {
                let store = ArrayDataStore(elements: [1, 2, 3])
                let source = BasicDataSource(store: store)
                source.
            }
        }
    }

}
