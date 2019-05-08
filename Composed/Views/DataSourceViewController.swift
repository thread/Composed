import UIKit

open class DataSourceViewController: UIViewController {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    open class var collectionViewClass: UICollectionView.Type {
        return UICollectionView.self
    }

    open class var layoutClass: UICollectionViewLayout.Type {
        return FlowLayout.self
    }

    public var collectionView: UICollectionView {
        return wrapper.collectionView
    }

    public var dataSource: DataSource? {
        return wrapper.dataSource
    }

    private let wrapper: CollectionViewWrapper
    public let layout: UICollectionViewLayout

    public init(dataSource: DataSource?, layout: UICollectionViewLayout = FlowLayout()) {
        let collectionView = type(of: self).collectionViewClass.init(frame: .zero, collectionViewLayout: layout)
        self.wrapper = CollectionViewWrapper(collectionView: collectionView)
        self.layout = layout
        super.init(nibName: nil, bundle: nil)

        if let dataSource = dataSource {
            self.wrapper.replace(dataSource: dataSource)
        }
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

    public func replace(dataSource: DataSource) {
        wrapper.replace(dataSource: dataSource)
    }

}
