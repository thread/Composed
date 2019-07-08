import Composed

public final class GlobalFooterView: UICollectionReusableView, ReusableViewNibLoadable {
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
}
