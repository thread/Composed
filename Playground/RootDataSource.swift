import Composed

public final class RootDataSource: GlobalDataSource {

    public override func globalHeaderConfiguration() -> DataSourceUIConfiguration? {
        return DataSourceUIConfiguration(prototype: GlobalHeaderView.fromNib, dequeueSource: .nib) { _, _ in }
    }

    public override func globalFooterConfiguration() -> DataSourceUIConfiguration? {
        return DataSourceUIConfiguration(prototype: GlobalFooterView.fromNib, dequeueSource: .nib) { _, _ in }
    }

}
