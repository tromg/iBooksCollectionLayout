import UIKit

public protocol BooksLayoutDelegate: class {
    func booksLayoutShouldDidHideCollectionView(_ booksLayout: BooksLayout)
}

public class BooksLayout: UICollectionViewFlowLayout {

    static let interItemOffset: CGFloat = 4
    static let itemSideInset: CGFloat = 16
    static let shiftTransformOffsetX: CGFloat = 18
    static let identityTransformOffset: CGFloat = 146
    static let shiftTransformOffsetY: CGFloat = 30
    static let closeLimitOffsetY: CGFloat = -64

    public static var offscreenPreventionOffset: CGFloat {
        ceil(shiftTransformOffsetX + 1 - itemSideInset + interItemOffset)
    }

    var defaultHeight: CGFloat {
        return min(560, (collectionView?.bounds.height ?? 0 - 44))
    }

    var sideInset: CGFloat {
        (unscaledItemWidth - scaledItemWidth * transformRatio) / 2 + BooksLayout.offscreenPreventionOffset
    }
    var unscaledItemWidth: CGFloat {
        collectionView?.bounds.width ?? 0
    }

    var scaledItemWidth: CGFloat {
        unscaledItemWidth - 2 * BooksLayout.itemSideInset
    }
    var transformRatio: CGFloat {
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

        let identityTransformOffset = Self.identityTransformOffset

        let progress = max(0, min(indexWithProgress.offset / identityTransformOffset, 1))
        collectionView.isScrollEnabled = progress == 0

        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let cellWidth = unscaledItemWidth
        let cellHeight = defaultHeight
        let shiftTransformOffsetX = Self.shiftTransformOffsetX
        let shiftTransformOffsetY = Self.shiftTransformOffsetY
        let interItemOffset = Self.interItemOffset
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


        return .init(width: width + Self.itemSideInset, height: height)
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
    public func booksLayoutScrollableCellCanBeInteracted(_ booksLayoutScrollableCell: BooksLayoutScrollableCell) -> Bool {
        guard let collectionView = collectionView else {
            return false
        }

        let bounds = collectionView.contentOffset.x...collectionView.contentOffset.x+collectionView.bounds.width
        return bounds ~= booksLayoutScrollableCell.center.x
    }

    public func booksLayoutScrollableCellCanShowScrollIndicator(_ booksLayoutScrollableCell: BooksLayoutScrollableCell, contentOffset: CGPoint) -> Bool {
        return contentOffset.y > Self.identityTransformOffset
    }

    public func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCell, willChangeContentOffset targetContentOffset: UnsafeMutablePointer<CGPoint>, withVelocity velocity: CGPoint) {
        let proposedResult = targetContentOffset.pointee.y
        let identityTransformOffset = Self.identityTransformOffset

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
        } else if proposedResult <= Self.closeLimitOffsetY && interactiveCloseEnabled {
            targetContentOffset.pointee.y = Self.closeLimitOffsetY
        }
    }

    public func booksLayoutScrollableCell(_ booksLayoutScrollableCell: BooksLayoutScrollableCell, didChangeContentOffset newContentOffset: CGPoint, isDecelerating: Bool) {
        guard let collectionView = collectionView,
              let indexPath = collectionView.indexPath(for: booksLayoutScrollableCell),
              isClosing == false else {
            return
        }

        if newContentOffset.y <= Self.closeLimitOffsetY && interactiveCloseEnabled && !isDecelerating {
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
