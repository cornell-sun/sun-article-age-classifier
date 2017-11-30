//
//  BookmarkSectionController.swift
//  Cornell Sun
//
//  Created by Austin Astorga on 11/13/17.
//  Copyright © 2017 cornell.sun. All rights reserved.
//

import UIKit
import IGListKit
import ImageSlideshow

// swiftlint:disable:next type_name
enum bookmarkCellType: Int {
    case categoryCell = 0
    case imageAndTitleCell = 1
    case actionMenuCell = 2
}

class BookmarkSectionController: ListSectionController {
    var entry: PostObject!
    weak var delegate: TabBarViewControllerDelegate?

    override init() {
        super.init()
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 15, right: 0)
    }
}

extension BookmarkSectionController: HeartPressedDelegate, BookmarkPressedDelegate, SharePressedDelegate {

    func taptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    func didPressBookmark(_ cell: MenuActionCell) {
        let correctBookmarkImage = cell.bookmarkButton.currentImage == #imageLiteral(resourceName: "bookmarkPressed") ? #imageLiteral(resourceName: "bookmark") : #imageLiteral(resourceName: "bookmarkPressed")
        cell.bookmarkButton.setImage(correctBookmarkImage, for: .normal)
        cell.bookmarkButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        taptic()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.40),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        cell.bookmarkButton.transform = CGAffineTransform.identity
        })
        RealmManager.instance.delete(object: entry)
    }

    func didPressHeart(_ cell: MenuActionCell) {
        let correctHeartImage = cell.heartButton.currentImage == #imageLiteral(resourceName: "heartPressed") ? #imageLiteral(resourceName: "heart") : #imageLiteral(resourceName: "heartPressed")
        cell.heartButton.setImage(correctHeartImage, for: .normal)
        cell.heartButton.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        taptic()
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: CGFloat(0.40),
                       initialSpringVelocity: CGFloat(6.0),
                       options: UIViewAnimationOptions.allowUserInteraction,
                       animations: {
                        cell.heartButton.transform = CGAffineTransform.identity
        })
    }

    func didPressShare() {
        taptic()
        if let articleLink = URL(string: entry.link) {
            let title = entry.title
            let objectToShare = [title, articleLink] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectToShare, applicationActivities: nil)
            getCurrentViewController()?.present(activityVC, animated: true, completion: nil)
        }
    }

    func didPressPhotos(_ slideShow: ImageSlideshow) {
        let fullScreenVC = FullScreenSlideshowViewController()
        slideShow.contentScaleMode = .scaleAspectFit
        slideShow.zoomEnabled = true
        fullScreenVC.slideshow = slideShow
        getCurrentViewController()?.present(fullScreenVC, animated: true, completion: nil)
    }

    override func numberOfItems() -> Int {
        return 3
    }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let context = collectionContext, entry != nil else {return .zero}
        let width = context.containerSize.width
        guard let sizeForItemIndex = bookmarkCellType(rawValue: index) else {
            return .zero
        }
        switch sizeForItemIndex {
        case .categoryCell:
            return CGSize(width: width, height: 40)
        case .imageAndTitleCell:
            return CGSize(width: width, height: 124)
        case .actionMenuCell:
            return CGSize(width: width, height: 35)
        }
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cellForItemIndex = bookmarkCellType(rawValue: index) else {
            return UICollectionViewCell()
        }
        switch cellForItemIndex {
        case .categoryCell:
            // swiftlint:disable:next force_cast
            let cell = collectionContext!.dequeueReusableCell(of: CategoryCell.self, for: self, at: index) as! CategoryCell
            cell.post = entry
            return cell
        case .imageAndTitleCell:
            // swiftlint:disable:next force_cast
            let cell = collectionContext!.dequeueReusableCell(of: BookmarkCell.self, for: self, at: index) as! BookmarkCell
            cell.post = entry
            return cell
        case .actionMenuCell:
            // swiftlint:disable:next force_cast
            let cell = collectionContext!.dequeueReusableCell(of: MenuActionCell.self, for: self, at: index) as! MenuActionCell
            cell.heartDelegate = self
            cell.bookmarkDelegate = self
            cell.shareDelegate = self
            cell.setupViews(forBookmarks: true)
            cell.setBookmarkImage(didSelectBookmark: entry.didSave)
            return cell
        }
    }

    override func didUpdate(to object: Any) {
        entry = object as? PostObject
    }

    override func didSelectItem(at index: Int) {
        if index != 2 {
            delegate?.articleSectionDidPressOnArticle(entry)
        }
    }
}
