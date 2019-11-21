import UIKit

protocol BooksLayoutScrollableCellScrollDelegate: class {
    func booksLayoutScrollableCellCanBeInteracted(_ booksLayoutScrollableCell: BooksLayoutScrollableCell) -> Bool
    func booksLayoutScrollableCellCanShowScrollIndicator(_ booksLayoutScrollableCell: BooksLayoutScrollableCell, contentOffset: CGPoint) -> Bool
    func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCell, didChangeContentOffset newContentOffset: CGPoint, isDecelerating: Bool)
    func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCell, willChangeContentOffset targetContentOffset: UnsafeMutablePointer<CGPoint>, withVelocity velocity: CGPoint)
}

protocol BooksLayoutScrollableCellViewController: UIViewController {
    func height(for width: CGFloat) -> CGFloat
    var closeActionBlock: (() -> Void)? { get set }
}

class BooksLayoutScrollableCell: UICollectionViewCell {

    static var reuseId: String {
        String(describing: self)
    }

    weak var scrollDelegate: BooksLayoutScrollableCellScrollDelegate?

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        return scrollView
    }()

    private var contentContainerView: BooksLayoutScrollableCellViewController? {
        didSet {
            scrollView.subviews.forEach { $0.removeFromSuperview() }
            if let contentContainerView = contentContainerView {
                scrollView.addSubview(contentContainerView.view)
            }
        }
    }

    func resetOffset(animated: Bool) {
        scrollView.setContentOffset(.zero, animated: animated)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        scrollView.frame = bounds

        if let contentContainerView = contentContainerView {
            scrollView.contentSize = .init(width: bounds.width, height: contentContainerView.height(for: bounds.width))
            contentContainerView.view.frame = .init(x: 0, y: 0, width: scrollView.contentSize.width, height: scrollView.contentSize.height)
        }
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let resultPoint = scrollView.convert(point, from: self)

        return scrollView.subviews.first { $0.frame.contains(resultPoint) } != nil
    }

    func setContentContainerView(_ contentContainerView: BooksLayoutScrollableCellViewController) {
        self.contentContainerView = contentContainerView

        setNeedsLayout()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.point(inside: point, with: event)
            && !self.isHidden
            && self.isUserInteractionEnabled
            && (scrollDelegate?.booksLayoutScrollableCellCanBeInteracted(self) ?? true)
         {
            return scrollView.subviews.compactMap { $0.hitTest($0.convert(point, from: self), with: event) }.first ?? scrollView
        } else {
            return nil
        }
    }
}

extension BooksLayoutScrollableCell: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.booksLayoutScrollableCell(self, didChangeContentOffset: scrollView.contentOffset, isDecelerating: scrollView.isDecelerating)
        scrollView.showsVerticalScrollIndicator = scrollDelegate?.booksLayoutScrollableCellCanShowScrollIndicator(self, contentOffset: scrollView.contentOffset) ?? false
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollDelegate?.booksLayoutScrollableCell(self, willChangeContentOffset: targetContentOffset, withVelocity: velocity)
    }
}
