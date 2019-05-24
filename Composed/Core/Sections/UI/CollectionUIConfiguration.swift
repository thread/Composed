import UIKit

public protocol CollectionUIConfiguration {
    var headerConfiguration: CollectionUIViewProvider? { get }
    var footerConfiguration: CollectionUIViewProvider? { get }
    var backgroundViewClass: UICollectionReusableView.Type? { get }
    var numberOfElements: Int { get }
    var reuseIdentifier: String { get }
    var prototype: UICollectionReusableView { get }
    var dequeueMethod: DequeueMethod { get }
    
    func configure(cell: UICollectionViewCell, at index: Int)
}

public enum DequeueMethod {
    /// Load from a nib
    case nib
    /// Load from a class
    case `class`
}

public protocol CollectionUIConfigurationProvider {
    var collectionUIConfiguration: CollectionUIConfiguration { get }
}
