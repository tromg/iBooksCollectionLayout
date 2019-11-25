import UIKit

public protocol BooksLayoutScrollableCellScrollDelegate: class {
    func booksLayoutScrollableCellCanBeInteracted(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol) -> Bool
    func booksLayoutScrollableCellCanShowScrollIndicator(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol, contentOffset: CGPoint) -> Bool
    func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol, didChangeContentOffset newContentOffset: CGPoint, isDecelerating: Bool)
    func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol, willChangeContentOffset targetContentOffset: UnsafeMutablePointer<CGPoint>, withVelocity velocity: CGPoint)
    func booksLayoutScrollableCellMinimumContentHeight(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol) -> CGFloat
    func booksLayoutScrollableCellShouldBeExpanded(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol)
    func booksLayoutScrollableCellShouldBeClosed(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol)
}

public protocol BooksLayoutScrollableCellViewController: UIViewController {
    func height(for width: CGFloat) -> CGFloat
    var closeActionBlock: (() -> Void)? { get set }
}

public protocol BooksLayoutScrollableCellProtocol: UICollectionViewCell {

    func setScrollOffset(_ newOffset: CGFloat, animated: Bool)
}

public class BooksLayoutScrollableCell: UICollectionViewCell {

    public static var reuseId: String {
        String(describing: self)
    }

    public weak var scrollDelegate: BooksLayoutScrollableCellScrollDelegate?

    private lazy var tapRec: UITapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.clipsToBounds = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollView.addGestureRecognizer(tapRec)

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

    @objc private func handleTap(_ tapRec: UITapGestureRecognizer) {
        guard point(inside: tapRec.location(in: self), with: nil) else {
            scrollDelegate?.booksLayoutScrollableCellShouldBeClosed(self)
            return
        }

        guard scrollView.contentOffset.y > 0 else {
            scrollDelegate?.booksLayoutScrollableCellShouldBeExpanded(self)
            return
        }

        // do nothing
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(scrollView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setContentContainerView(_ contentContainerView: BooksLayoutScrollableCellViewController) {
        self.contentContainerView = contentContainerView

        setNeedsLayout()
    }

    override public func layoutSubviews() {
        scrollView.frame = bounds

        if let contentContainerView = contentContainerView {
            let minHeight = scrollDelegate?.booksLayoutScrollableCellMinimumContentHeight(self) ?? 0
            let height = max(contentContainerView.height(for: bounds.width), minHeight)
            contentContainerView.view.frame = .init(x: 0, y: 0, width: bounds.width, height: height)
            scrollView.contentSize = contentContainerView.view.frame.size
        }
    }

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let resultPoint = scrollView.convert(point, from: self)

        return scrollView.subviews.first { $0.frame.contains(resultPoint) } != nil
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !self.isHidden
            && self.isUserInteractionEnabled
            && (scrollDelegate?.booksLayoutScrollableCellCanBeInteracted(self) ?? true) {
            return scrollView.subviews.compactMap { $0.hitTest($0.convert(point, from: self), with: event) }.first ?? scrollView
        } else {
            return nil
        }
    }
}

extension BooksLayoutScrollableCell: BooksLayoutScrollableCellProtocol {

    public func setScrollOffset(_ newOffset: CGFloat, animated: Bool) {
        scrollView.setContentOffset(.init(x: 0, y: newOffset), animated: animated)
    }
}

extension BooksLayoutScrollableCell: UIScrollViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.booksLayoutScrollableCell(self, didChangeContentOffset: scrollView.contentOffset, isDecelerating: scrollView.isDecelerating)
        scrollView.showsVerticalScrollIndicator = scrollDelegate?.booksLayoutScrollableCellCanShowScrollIndicator(self, contentOffset: scrollView.contentOffset) ?? false
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollDelegate?.booksLayoutScrollableCell(self, willChangeContentOffset: targetContentOffset, withVelocity: velocity)
    }
}
