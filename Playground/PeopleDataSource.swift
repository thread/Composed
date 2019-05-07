import UIKit
import Composed

struct Person {
    var name: String
    var age: Int
}

final class PeopleDataSource: SectionedDataSource<Person>, CollectionUIProvidingDataSource {

    var title: String?

    func sizingStrategy(in collectionView: UICollectionView) -> CollectionUISizingStrategy {
        let columnCount = collectionView.traitCollection.horizontalSizeClass == .compact ? 2 : 4
        return ColumnSizingStrategy(columnCount: columnCount, sizingMode: .automatic(isUniform: true))
    }

    func metrics(for section: Int) -> CollectionUISectionMetrics {
        return CollectionUISectionMetrics(insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), horizontalSpacing: 8, verticalSpacing: 8)
    }

    func cellConfiguration(for indexPath: IndexPath) -> CollectionUIViewProvider {
        return CollectionUIViewProvider(prototype: PersonCell.fromNib, dequeueSource: .nib) { cell, indexPath, _ in
            cell.prepare(person: self.element(at: indexPath))
        }
    }

    func footerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return CollectionUIViewProvider(prototype: FooterView.fromNib, dequeueSource: .nib) { view, indexPath, _ in
            view.prepare(title: "\(self.numberOfElements(in: section)) items")
        }
    }

    func headerConfiguration(for section: Int) -> CollectionUIViewProvider? {
        return title.map { title in
            CollectionUIViewProvider(prototype: HeaderView.fromNib, dequeueSource: .nib) { view, indexPath, _ in
                view.prepare(title: title)
            }
        }
    }

    func backgroundViewClass(for section: Int) -> UICollectionReusableView.Type? {
        return BackgroundView.self
    }

}

final class ListDataSource: ComposedDataSource, GlobalViewsProvidingDataSource {

    var placeholderView: UIView? {
        let view = UIActivityIndicatorView(style: .gray)
        view.startAnimating()
        return view
    }

    func globalHeaderConfiguration() -> CollectionUIViewProvider? {
        return CollectionUIViewProvider(prototype: GlobalHeaderView.fromNib, dequeueSource: .nib) { _, _, _ in }
    }

    func globalFooterConfiguration() -> CollectionUIViewProvider? {
        return CollectionUIViewProvider(prototype: GlobalFooterView.fromNib, dequeueSource: .nib) { _, _, _ in }
    }

}

final class PersonCell: UICollectionViewCell, ReusableViewNibLoadable {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var ageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

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
        backgroundColor = .lightGray
        titleLabel.text = title
    }

}

final class FooterView: DataSourceHeaderFooterView, ReusableViewNibLoadable {

    @IBOutlet private weak var titleLabel: UILabel!

    public func prepare(title: String?) {
        backgroundColor = .darkGray
        titleLabel.text = title
    }

}
