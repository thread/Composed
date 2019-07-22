import Quick
import Nimble

@testable import Composed

final class AllNewAndImproved_Spec: QuickSpec {

    override func spec() {
        super.spec()

        describe("") {
            let global = ComposedSectionProvider()

            let child1 = ComposedSectionProvider()
                let child1a = ArraySection<String>()
                let child1b = ArraySection<String>()
            let child2 = ComposedSectionProvider()
                let child2a = ComposedSectionProvider()
                    let child2b = ArraySection<String>()
                    let child2c = ArraySection<String>()
                let child2d = ArraySection<String>()
                let child2z = ComposedSectionProvider()
                let child2e = ComposedSectionProvider()
                    let child2f = ArraySection<String>()

            child1.append(child1a)
            child1.append(child1b)
            child2.append(child2a)
            child2a.append(child2b)
            child2a.append(child2c)
            child2.append(child2d)
            child2e.append(child2f)
            child2.append(child2z)
            child2.append(child2e)
            global.append(child1)
            global.append(child2)

            let cache = global.cachedProviderSections

            it("should contain 2 global sections") {
                expect(global.numberOfSections) == 6
            }

            it("cache should contain 5 providers") {
                expect(cache.count) == 6
            }

            it("section offset should be 2") {
                expect(cache[HashableProvider(child2)]) == 2
                expect(cache[HashableProvider(child2a)]) == 2
                expect(cache[HashableProvider(child2e)]) == 5

                expect(child2.cachedProviderSections[HashableProvider(child2a)]) == 0
                expect(child2.cachedProviderSections[HashableProvider(child2z)]) == 3
                expect(child2.cachedProviderSections[HashableProvider(child2e)]) == 3
            }
        }
    }

}
