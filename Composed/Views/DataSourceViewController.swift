import UIKit

open class DataSourceViewController: UIViewController {

    open class var collectionViewClass: UICollectionView.Type {
        return UICollectionView.self
    }

    public var collectionView: UICollectionView {
        return wrapper.collectionView
    }

    public var dataSource: DataSource {
        return wrapper.dataSource
    }

    private let wrapper: CollectionViewWrapper
    public let layout: UICollectionViewLayout

    public init(dataSource: DataSource, layout: UICollectionViewLayout = FlowLayout()) {
        let collectionView = type(of: self).collectionViewClass.init(frame: .zero, collectionViewLayout: layout)
        self.wrapper = CollectionViewWrapper(collectionView: collectionView)
        self.layout = layout
        super.init(nibName: nil, bundle: nil)
        self.wrapper.replace(dataSource: dataSource)
    }

    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)

        coordinator.animate(alongsideTransition: { context in
            var context = DataSourceInvalidationContext()
            context.invalidateLayoutMetrics  = true
            self.wrapper.invalidate(with: context)
        }, completion: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.layout = FlowLayout()
        let collectionView = type(of: self).collectionViewClass.init(frame: .zero, collectionViewLayout: layout)
        self.wrapper = CollectionViewWrapper(collectionView: collectionView)
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
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !collectionView.allowsMultipleSelection {
            collectionView.indexPathsForSelectedItems?.first
                .map { collectionView.deselectItem(at: $0, animated: animated) }
        }

        guard presentedViewController == nil else { return }
        wrapper.becomeActive()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        wrapper.resignActive()
    }

    open override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        wrapper.setEditing(editing, animated: animated)
    }

    public func replace(dataSource: DataSource) {
        wrapper.replace(dataSource: dataSource)
    }

}
