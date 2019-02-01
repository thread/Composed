import UIKit
import Composed

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

final class HeaderView: DataSourceHeaderView, ReusableViewNibLoadable {

    @IBOutlet private weak var titleLabel: UILabel!

    public func prepare(title: String?) {
        titleLabel.text = title
    }

}

//public struct DataSourceCellConfiguration<Cell, Model> where Cell: DataReusableView {
//
//    public enum Source {
//        case nib
//        case `class`
//    }
//
//    public typealias Configuration = (Cell, Model, IndexPath) -> Void
//
//    public let prototype: Cell
//    public let dequeueSource: Source
//    public let configuration: Configuration
//
//    public init(prototype: Cell, dequeueSource: Source, _ configuration: @escaping Configuration) {
//        self.prototype = prototype
//        self.dequeueSource = dequeueSource
//        self.configuration = configuration
//    }
//
//}

final class PeopleDataSource: SimpleDataSource<Person> {

    var title: String?

//    func configuration() -> DataSourceCellConfiguration<PersonCell, Person> {
//        return DataSourceCellConfiguration(prototype: .fromNib, dequeueSource: .nib) { cell, person, indexPath in
//            cell.prepare(person: person)
//        }
//    }

    override func cellSource(for indexPath: IndexPath) -> ViewSource {
        return .nib(PersonCell.self)
    }

    override func supplementViewSource(for indexPath: IndexPath, ofKind kind: String) -> ViewSource {
        return .nib(HeaderView.self)
    }

    override func prepare(supplementaryView: UICollectionReusableView, at indexPath: IndexPath, of kind: String) {
        switch supplementaryView {
        case let view as HeaderView:
            view.prepare(title: title)
        default:
            fatalError("Unsupported supplementary type: \(type(of: supplementaryView))")
        }
    }

    override func layoutStrategy(in section: Int) -> FlowLayoutStrategy {
        let strategy = HeaderLayoutStrategy(prototype: HeaderView.fromNib)
        return FlowLayoutColumnStrategy(columns: 2,
                                        sectionInsets: UIEdgeInsets(all: 16),
                                        horizontalSpacing: 4,
                                        verticalSpacing: 4,
                                        prototype: PersonCell.fromNib,
                                        headerStrategy: strategy)
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
