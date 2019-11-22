import UIKit
import iBooksLayout

class ViewController: UIViewController {

    lazy var layout: BooksLayout = {
        let layout = BooksLayout()
        layout.interactiveCloseEnabled = true
        layout.delegate = self

        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.register(BooksLayoutScrollableCell.self, forCellWithReuseIdentifier: BooksLayoutScrollableCell.reuseId)
        collectionView.isDirectionalLockEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.decelerationRate = .fast
        collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear

        return collectionView
    }()

    var initialIndex = 3

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        view.backgroundColor = .clear

        collectionView.reloadData()
    }

    var initialIndexDidSet = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = .init(x: -layout.offscreenPreventionOffset, y: 0, width: view.bounds.width + 2 * layout.offscreenPreventionOffset, height: view.bounds.height)
        collectionView.collectionViewLayout.invalidateLayout()

        if initialIndexDidSet == false {
            defer { initialIndexDidSet = true }

            collectionView.scrollToItem(at: .init(item: initialIndex, section: 0), at: .centeredHorizontally, animated: false)
        }
    }

    func close() {
        dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BooksLayoutScrollableCell.reuseId, for: indexPath) as! BooksLayoutScrollableCell
        cell.setContentContainerView(items[indexPath.item])
        cell.scrollDelegate = collectionView.collectionViewLayout as? BooksLayoutScrollableCellScrollDelegate

        return cell
    }
}

extension ViewController: BooksLayoutDelegate {

    func booksLayoutShouldDidHideCollectionView(_ booksLayout: BooksLayout) {
        close()
    }
}

extension ViewController {


    var items: [BooksLayoutScrollableCellViewController] {
        func createController(with color: UIColor) -> MyContentViewController {
            let myContentViewController = MyContentViewController()
            myContentViewController.setModel(.init(text: .loremIpsum, color: color))
            myContentViewController.closeActionBlock = { [weak self] in
                self?.close()
            }
            return myContentViewController
        }
        return [
            createController(with: .red),
            createController(with: .green),
            createController(with: .brown),
            createController(with: .white),
            createController(with: .blue),
            createController(with: .cyan),
            createController(with: .magenta),
            createController(with: .gray),
        ]
    }
}
