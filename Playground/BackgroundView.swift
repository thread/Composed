import UIKit

final class BackgroundView: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.cgColor
        backgroundColor = UIColor(white: 0.98, alpha: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
