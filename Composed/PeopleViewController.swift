import UIKit
import DataSources

struct Person {
    var name: String
    var age: Int
}

final class PersonCell: DataSourceCell, ReusableViewNibLoadable {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var ageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.adjustsFontForContentSizeCategory = true
        ageLabel.adjustsFontForContentSizeCategory = true
    }

    public func prepare(person: Person) {
        nameLabel.text = person.name
        ageLabel.text = "\(person.age)"
    }

}

final class Header: DataSourceHeaderView, ReusableViewNibLoadable {

    @IBOutlet private weak var titleLabel: UILabel!

    public func prepare(title: String?) {
        titleLabel.text = title
    }

}

final class PeopleDataSource: SimpleDataSource<Person> {

    var title: String?

    override func cellSource(for indexPath: IndexPath) -> DataSourceViewSource {
        return .nib(PersonCell.self)
    }

    override func supplementViewSource(for indexPath: IndexPath, ofKind kind: String) -> DataSourceViewSource {
        return .nib(Header.self)
    }

    override func prepare(supplementaryView: UICollectionReusableView, at indexPath: IndexPath, of kind: String) {
        switch supplementaryView {
        case let view as Header:
            view.prepare(title: title)
        default:
            fatalError("Unsupported supplementary type: \(type(of: supplementaryView))")
        }
    }

    override func layoutStrategy(in section: Int) -> FlowLayoutStrategy {
        let metrics = FlowLayoutSectionMetrics(headerHeight: 0,
                                               footerHeight: 0,
                                               insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                                               horizontalSpacing: 4,
                                               verticalSpacing: 4)

        let strategy = HeaderLayoutStrategy(prototypeHeader: Header.fromNib)
        return FlowLayoutColumnsStrategy(columns: 2, metrics: metrics, prototypeCell: PersonCell.fromNib, headerStrategy: strategy)
    }

    override func prepare(cell: DataSourceCell, at indexPath: IndexPath) {
        switch cell {
        case let cell as PersonCell:
            cell.prepare(person: self[indexPath]!)
        default:
            fatalError("Unsupported cell type: \(type(of: cell))")
        }
    }

}

final class PeopleViewController: DataSourceViewController {

    init() {
        let composed = ComposedDataSource()
        super.init(dataSource: composed, layout: FlowLayout())

        composed.append(family)
        composed.append(friends)
        composed.append(family)
        composed.append(friends)
        composed.append(family)
        composed.append(friends)
        composed.append(family)
        composed.append(friends)
    }

    private var family: PeopleDataSource {
        let family = PeopleDataSource(elements: [
            Person(name: "Shaps is the best dad in the world", age: 38),
            Person(name: "Uwe", age: 60),
            Person(name: "Anne", age: 35)
            ])

        family.title = "Family"
        return family
    }

    private var friends: PeopleDataSource {
        let friends = PeopleDataSource(elements: [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph is the worst Python Developer in London", age: 24)
            ])

        friends.title = "Friends"
        return friends
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: nil) { _ in
            self.collectionView.reloadData()
        }
    }

}
