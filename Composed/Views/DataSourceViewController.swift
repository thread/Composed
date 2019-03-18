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
        self.wrapper = CollectionViewWrapper(collectionView: collectionView, dataSource: dataSource)
        self.layout = layout
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        edgesForExtendedLayout = .top
        extendedLayoutIncludesOpaqueBars = true

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            view.topAnchor.constraint(equalTo: collectionView.topAnchor),
            view.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
        ])

        wrapper.prepare(dataSource: dataSource)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

}
