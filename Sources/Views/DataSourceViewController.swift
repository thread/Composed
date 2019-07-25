import UIKit
import FlowLayout

/// Provides a convenience controller for working with DataSource's.
///
/// Its not required that you use this controller, if you prefer to implement this yourself, you can use a `DataSourceCoordinator` directly.
open class DataSourceViewController: UIViewController {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Override to provide a different subclass for your collectionView
    open class var collectionViewClass: UICollectionView.Type {
        return UICollectionView.self
    }

    /// Override to provide a different subclass for your collectionViewLayout
    open class var layoutClass: UICollectionViewLayout.Type {
        return FlowLayout.self
    }

    /// The associated collectionView used by this controller
    public var collectionView: UICollectionView {
        return wrapper.collectionView
    }

    /// The associated dataSource used by this controller
    public var dataSource: DataSource? {
        return wrapper.dataSource
    }

    /// The associated layout used by this controller
    public let layout: UICollectionViewLayout

    private let wrapper: DataSourceCoordinator

    /// Make a new controller with the associated dataSource and layout
    ///
    /// - Parameters:
    ///   - dataSource: The dataSource to associate with this controller
    ///   - layout: The layout to associate with this controller, defaults to `UICollectionViewFlowLayout()`
    public init(dataSource: DataSource?, layout: UICollectionViewLayout = UICollectionViewFlowLayout()) {
        let collectionView = type(of: self).collectionViewClass.init(frame: .zero, collectionViewLayout: layout)
        self.wrapper = DataSourceCoordinator(collectionView: collectionView, dataSource: dataSource)
        self.layout = layout
        super.init(nibName: nil, bundle: nil)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { context in
            var context = DataSourceInvalidationContext()
            context.invalidateLayoutMetrics  = true
            self.wrapper.invalidate(with: context)
        }, completion: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.layout = type(of: self).layoutClass.init()
        let collectionView = type(of: self).collectionViewClass.init(frame: .zero, collectionViewLayout: layout)
        self.wrapper = DataSourceCoordinator(collectionView: collectionView)
        super.init(coder: aDecoder)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true

        collectionView.alwaysBounceVertical = true
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(endEditingIfNecessary),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(invalidateEverything),
                                               name: UIContentSizeCategory.didChangeNotification, object: nil)
    }

    @objc private func invalidateEverything() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    @objc private func endEditingIfNecessary() {
        guard isEditing else { return }

        if collectionView.allowsMultipleSelection &&
            collectionView.indexPathsForSelectedItems?.isEmpty == false {
            return
        }

        setEditing(false, animated: false)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.flashScrollIndicators()
    }

    open override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        wrapper.setEditing(editing, animated: animated)
    }

    /// Convenience function for replacing the dataSource associated with this controller
    ///
    /// - Parameter dataSource: The new dataSource to associate with this controller
    public func replace(dataSource: DataSource) {
        wrapper.replace(dataSource: dataSource)
        invalidateEverything()
    }

}
