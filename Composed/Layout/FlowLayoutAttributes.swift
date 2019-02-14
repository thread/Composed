import UIKit

open class FlowLayoutAttributes: UICollectionViewLayoutAttributes {

    open var isFirstInSection: Bool = false
    open var isLastInSection: Bool = false

    open override func copy(with zone: NSZone? = nil) -> Any {
        guard let copy = super.copy(with: zone) as? FlowLayoutAttributes else { fatalError() }
        copy.isFirstInSection = isFirstInSection
        copy.isLastInSection  = isLastInSection
        return copy
    }

}
