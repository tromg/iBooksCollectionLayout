import UIKit

public protocol BooksLayoutDelegate: class {
    func booksLayoutShouldDidHideCollectionView(_ booksLayout: BooksLayout)
}

public class BooksLayout: UICollectionViewFlowLayout {

    public var interItemOffset: CGFloat = 4
    public var itemSideInset: CGFloat = 16
    public var shiftTransformOffsetX: CGFloat = 18
    public var identityTransformOffset: CGFloat = 146
    public var shiftTransformOffsetY: CGFloat = 30
    public var closeLimitOffsetY: CGFloat = -64
    public var itemHeight: CGFloat? = 560

    public var offscreenPreventionOffset: CGFloat {
        ceil(shiftTransformOffsetX + 1 - itemSideInset + interItemOffset)
    }

    private var defaultHeight: CGFloat {
        return itemHeight ?? (collectionView?.bounds.height ?? 100) - 44
    }

    private var sideInset: CGFloat {
        (unscaledItemWidth - scaledItemWidth * transformRatio) / 2 + offscreenPreventionOffset
    }
    private var unscaledItemWidth: CGFloat {
        (collectionView?.bounds.width ?? 100) - 2 * offscreenPreventionOffset
    }

    private var scaledItemWidth: CGFloat {
        unscaledItemWidth - 2 * itemSideInset
    }
    private var transformRatio: CGFloat {
        scaledItemWidth / unscaledItemWidth
    }

    struct IndexWithProgress {
        var index: Int = 0
        var offset: CGFloat = 0
        var isDecelerating: Bool = false
    }

    private var cache = [UICollectionViewLayoutAttributes]()
    private var indexWithProgress = IndexWithProgress() {
        didSet {
            self.invalidateLayout()
        }
    }

    public var interactiveCloseEnabled = false

    var isClosing = false

    public weak var delegate: BooksLayoutDelegate?

    override public func prepare() {
        guard let collectionView = collectionView else {
            return
        }

        let progress = max(0, min(indexWithProgress.offset / identityTransformOffset, 1))
        collectionView.isScrollEnabled = progress == 0

        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let cellWidth = unscaledItemWidth
        let cellHeight = defaultHeight
        let defaultShrinkedWidth = cellWidth * transformRatio

        cache = (0..<numberOfItems).map({ index -> UICollectionViewLayoutAttributes in
            let indexPath = IndexPath(item: index, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            var scale = transformRatio
            if index == indexWithProgress.index {
                scale = scale + progress * (1 - scale)
            }
            attributes.transform = .init(scaleX: scale, y: scale)
            attributes.size = .init(width: cellWidth, height: cellHeight)


            let xCenter = (collectionView.bounds.width / 2) + CGFloat(index) * (defaultShrinkedWidth + interItemOffset)

            var translationX: CGFloat = 0
            var translationY: CGFloat = 0

            if index < indexWithProgress.index {
                translationX = -progress * shiftTransformOffsetX
                translationY = -progress * shiftTransformOffsetY
            } else if index > indexWithProgress.index {
                translationX = progress * shiftTransformOffsetX
                translationY = -progress * shiftTransformOffsetY
            }

            if indexWithProgress.offset < 0 && index != indexWithProgress.index && (!indexWithProgress.isDecelerating || cache[index].transform.ty > 0) {
                translationY = -indexWithProgress.offset * scale
            }

            attributes.transform = attributes.transform.concatenating(.init(translationX: translationX, y: translationY))

            let yCenter = collectionView.bounds.height - scale  * (defaultHeight - 0.5 * cellHeight)
            attributes.center = .init(x: xCenter, y: yCenter)

            return attributes
        })
    }

    override public var collectionViewContentSize: CGSize {
        let width = cache.map { attr -> CGFloat in
            let centerX = attr.center.x
            let width = attr.size.width
            let scaleX = attr.transform.xScale

            return centerX + 0.5 * (width * scaleX)
        }.max() ?? 0

        let height = cache.map { attr -> CGFloat in
            let centerY = attr.center.y
            let height = attr.size.height
            let scaleY = attr.transform.yScale

            return centerY + 0.5 * (height * scaleY)
        }.max() ?? 0


        return .init(width: width + itemSideInset + offscreenPreventionOffset, height: height)
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return cache.filter { $0.frame.intersects(rect) }
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }

    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {

        guard let collectionView = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let collectionViewSize = collectionView.frame.size

        // we will search nearest 'stick' cell in region as big as two screen size
        let targetRect = CGRect(x: proposedContentOffset.x - collectionViewSize.width,
                                y: proposedContentOffset.y,
                                width: collectionViewSize.width * 2,
                                height: collectionViewSize.height)

        guard let attributes = layoutAttributesForElements(in: targetRect) else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let first = attributes
            .filter { attr in
                return !isOppositeDirection(attr: attr, contentOffset: collectionView.contentOffset, velocity: velocity)
        }.sorted(by: { lhs, rhs in
            let lhsDiff = abs(lhs.frame.minX - proposedContentOffset.x)
            let rhsDiff = abs(rhs.frame.minX - proposedContentOffset.x)
            return lhsDiff < rhsDiff
        }).first

        guard let firstAttrs = first else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let diff = firstAttrs.frame.minX - proposedContentOffset.x - collectionView.contentInset.left
        let targetContentOffset = CGPoint(
            x: proposedContentOffset.x + diff + 0.5*(firstAttrs.frame.width - collectionView.frame.width),
            y: proposedContentOffset.y
        )

        return targetContentOffset
    }

    private func isOppositeDirection(attr: UICollectionViewLayoutAttributes, contentOffset: CGPoint, velocity: CGPoint) -> Bool {
        let isOppositeDirection = (attr.frame.origin.x < contentOffset.x && velocity.x > 0)
            || (attr.frame.origin.x > contentOffset.x && velocity.x < 0)

        return isOppositeDirection
    }
}

extension BooksLayout: BooksLayoutScrollableCellScrollDelegate {
    public func booksLayoutScrollableCellShouldBeExpanded(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol) {
        booksLayoutScrollableCell.setScrollOffset(identityTransformOffset, animated: true)
    }

    public func booksLayoutScrollableCellShouldBeClosed(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol) {
        delegate?.booksLayoutShouldDidHideCollectionView(self)
    }

    public func booksLayoutScrollableCellCanBeInteracted(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol) -> Bool {
        guard let collectionView = collectionView else {
            return false
        }

        let bounds = collectionView.contentOffset.x...collectionView.contentOffset.x+collectionView.bounds.width
        return bounds ~= booksLayoutScrollableCell.center.x
    }

    public func booksLayoutScrollableCellCanShowScrollIndicator(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol, contentOffset: CGPoint) -> Bool {
        return contentOffset.y > identityTransformOffset
    }

    public func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol, willChangeContentOffset targetContentOffset: UnsafeMutablePointer<CGPoint>, withVelocity velocity: CGPoint) {
        let proposedResult = targetContentOffset.pointee.y

        if 0...identityTransformOffset ~= proposedResult {
            if velocity.y < 0 {
                targetContentOffset.pointee.y = 0
            } else if velocity.y > 0 {
                targetContentOffset.pointee.y = identityTransformOffset
            } else if targetContentOffset.pointee.y > identityTransformOffset / 2 {
                targetContentOffset.pointee.y = identityTransformOffset
            } else {
                targetContentOffset.pointee.y = 0
            }
        } else if proposedResult <= closeLimitOffsetY && interactiveCloseEnabled {
            targetContentOffset.pointee.y = closeLimitOffsetY
        }
    }

    public func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCellProtocol, didChangeContentOffset newContentOffset: CGPoint, isDecelerating: Bool) {
        guard let collectionView = collectionView,
              let indexPath = collectionView.indexPath(for: booksLayoutScrollableCell),
              isClosing == false else {
            return
        }

        if newContentOffset.y <= closeLimitOffsetY && interactiveCloseEnabled && !isDecelerating {
            delegate?.booksLayoutShouldDidHideCollectionView(self)
        } else {
            indexWithProgress = .init(index: indexPath.item, offset: newContentOffset.y, isDecelerating: isDecelerating)
        }
    }
}

private extension CGAffineTransform {

    var xScale: CGFloat {
        sqrt(a*a + c*c)
    }

    var yScale: CGFloat {
        sqrt(b*b + d*d)
    }
}
