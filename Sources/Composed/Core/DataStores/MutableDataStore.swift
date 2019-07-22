import Foundation

public protocol MutableDataStore: DataStore, RandomAccessCollection, RangeReplaceableCollection, MutableCollection { }

extension ArrayDataStore: MutableDataStore {

    public var startIndex: Int {
        return elements.startIndex
    }

    public var endIndex: Int {
        return elements.endIndex
    }

    public func index(after i: Int) -> Int {
        return elements.index(after: i)
    }

    public func index(before i: Int) -> Int {
        return elements.index(before: i)
    }

    public subscript(position: Int) -> Element {
        get { return elements[position] }
        set { elements[position] = newValue }
    }

    public func insert<C>(contentsOf newElements: C, at i: Int) where C : Collection, Element == C.Element {
        elements.insert(contentsOf: newElements, at: i)
        let indexes = i..<newElements.count
        let indexPaths = indexes.map { IndexPath(item: $0, section: 0) }

        var details = ComposedChangeDetails()
        details.insertedIndexPaths = indexPaths
        delegate?.dataStoreDidUpdate(changeDetails: details)
    }

    public func removeSubrange(_ bounds: Range<Int>) {
        elements.removeSubrange(bounds)
        let indexPaths = bounds.map { IndexPath(item: $0, section: 0) }

        var details = ComposedChangeDetails()
        details.removedIndexPaths = indexPaths
        delegate?.dataStoreDidUpdate(changeDetails: details)
    }

    public func replaceSubrange<C, R>(_ subrange: R, with newElements: C)
        where C : Collection, R : RangeExpression, Element == C.Element, Index == R.Bound {
            elements.replaceSubrange(subrange, with: newElements)
            let details = ComposedChangeDetails(hasIncrementalChanges: false)
            delegate?.dataStoreDidUpdate(changeDetails: details)
    }

    public func replaceElements(_ elements: [Element], changesets: [DataSourceChangeset]? = nil) {
        self.elements = elements

        let details = ComposedChangeDetails(changesets: changesets)
        delegate?.dataStoreDidUpdate(changeDetails: details)
    }

}

extension ArrayDataStore: ExpressibleByArrayLiteral {

    public convenience init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
}
