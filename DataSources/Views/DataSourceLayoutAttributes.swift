import UIKit

open class DataSourceLayoutAttributes: UICollectionViewLayoutAttributes {

    public internal(set) var stretchFactor: CGFloat = 0

    public override init() {
        super.init()
    }

    open override func copy() -> Any {
        let copy = super.copy() as! DataSourceLayoutAttributes
        copy.stretchFactor = stretchFactor
        return copy
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? DataSourceLayoutAttributes else { return false }
        guard stretchFactor == other.stretchFactor else { return false }
        return super.isEqual(object)
    }

}
