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

final class HeaderView: DataSourceHeaderFooterView, ReusableViewNibLoadable {

    @IBOutlet private weak var titleLabel: UILabel!

    public func prepare(title: String?) {
        titleLabel.text = title
    }

}

final class PeopleDataSource: SimpleDataSource<Person> {

    var title: String?

    private let prototypeCell = PersonCell.fromNib
    private let prototypeHeader = HeaderView.fromNib

    override func metrics(for section: Int) -> DataSourceSectionMetrics {
        return DataSourceSectionMetrics(columnCount: 2, insets: UIEdgeInsets(all: 16), horizontalSpacing: 4, verticalSpacing: 4)
    }

    override func cellConfiguration(for indexPath: IndexPath) -> CellConfiguration {
        return CellConfiguration(prototype: prototypeCell, dequeueSource: .nib) { cell, indexPath in
            (cell as? PersonCell)?.prepare(person: self.element(at: indexPath))
        }
    }

    override func headerConfiguration(for section: Int) -> HeaderFooterConfiguration {
        return HeaderFooterConfiguration(prototype: prototypeHeader, dequeueSource: .nib) { view, indexPath in
            (view as? HeaderView)?.prepare(title: self.title)
        }
    }

}
