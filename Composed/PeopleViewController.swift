import UIKit
import DataSources

struct Person {
    var name: String
    var age: Int
}

final class PersonCell: DataSourceCell, ReusableViewNibLoadable {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var ageLabel: UILabel!

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

    override func cellType(for indexPath: IndexPath) -> DataReusableView.Type {
        return PersonCell.self
    }

    override func supplementType(for indexPath: IndexPath, ofKind kind: String) -> DataReusableView.Type {
        return Header.self
    }

    override func prepare(supplementaryView: UICollectionReusableView, at indexPath: IndexPath, of kind: String) {
        switch supplementaryView {
        case let view as Header:
            view.prepare(title: title)
        default:
            fatalError("Unsupported supplementary type: \(type(of: supplementaryView))")
        }
    }

    override func layoutStrategy(for section: Int) -> FlowLayoutStrategy {
        let metrics = FlowLayoutSectionMetrics(headerHeight: 0,
                                               footerHeight: 0,
                                               insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                                               horizontalSpacing: 1,
                                               verticalSpacing: 1)

        let strategy = HeaderLayoutStrategy(prototypeHeader: Header.fromNib)
        return FlowLayoutColumnsStrategy<PersonCell>(columns: 2, metrics: metrics, headerStrategy: strategy)
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
            Person(name: "Shaps", age: 38),
            Person(name: "Uwe", age: 60),
            Person(name: "Anne", age: 35)
            ])

        family.title = "Family"
        return family
    }

    private var friends: PeopleDataSource {
        let friends = PeopleDataSource(elements: [
            Person(name: "Stewart", age: 39),
            Person(name: "Joseph", age: 24)
            ])

        friends.title = "Friends"
        return friends
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
