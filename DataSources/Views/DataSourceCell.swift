import UIKit

open class DataSourceCell: UICollectionViewCell {

    public private(set) var isEditing: Bool = false

    open func setEditing(_ editing: Bool, animated: Bool) {
        isEditing = editing
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return contentView.sizeThatFits(size)
    }

    open override func systemLayoutSizeFitting(_ targetSize: CGSize) -> CGSize {
        return contentView.systemLayoutSizeFitting(targetSize)
    }

    open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority
        horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        let targetSize = CGSize(width: targetSize.width, height: 0)
        return contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required,
                                                   verticalFittingPriority: .defaultLow)
    }

}
