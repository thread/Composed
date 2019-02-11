import UIKit
import Composed

struct Person {
    var name: String
    var age: Int
}

final class PeopleDataSource: ArrayDataSource<Person>, DataSourceUIProviding {

    var title: String?

    lazy var sizingStrategy: DataSourceSizingStrategy = {
        return ColumnSizingStrategy(columnCount: 2, sizingMode: .automatic(isUniform: false))
    }()

    func metrics(for section: Int) -> DataSourceSectionMetrics {
        return DataSourceSectionMetrics(insets: UIEdgeInsets(horizontal: 16, vertical: 0), horizontalSpacing: 4, verticalSpacing: 4)
    }

    func cellConfiguration(for indexPath: IndexPath) -> CellConfiguration {
        return CellConfiguration(prototype: PersonCell.fromNib, dequeueSource: .nib) { cell, indexPath in
            cell.prepare(person: self.element(at: indexPath))
        }
    }

    func headerConfiguration(for section: Int) -> HeaderFooterConfiguration? {
        return title.map { title in
            HeaderFooterConfiguration(prototype: HeaderView.fromNib, dequeueSource: .nib) { view, indexPath in
                view.prepare(title: title)
            }
        }
    }

}

final class PersonCell: DataSourceCell, ReusableViewNibLoadable {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var ageLabel: UILabel!

    override var isHighlighted: Bool {
        didSet { layer.add(CATransition(), forKey: nil) }
    }

    override var isSelected: Bool {
        didSet { layer.add(CATransition(), forKey: nil) }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundView = UIView(frame: .zero)
        backgroundView?.layer.cornerRadius = 6
        backgroundView?.layer.borderWidth = 1
        backgroundView?.layer.borderColor = UIColor.lightGray.cgColor
        backgroundView?.backgroundColor = UIColor(white: 0.98, alpha: 1)

        selectedBackgroundView = UIView(frame: .zero)
        selectedBackgroundView?.layer.cornerRadius = 6
        selectedBackgroundView?.layer.borderWidth = 1
        selectedBackgroundView?.layer.borderColor = UIColor.lightGray.cgColor
        selectedBackgroundView?.backgroundColor = UIColor(white: 0.88, alpha: 1)

        backgroundColor = .clear
    }

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
