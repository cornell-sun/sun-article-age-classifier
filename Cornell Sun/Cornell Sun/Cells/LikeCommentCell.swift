//
//  LikeCommentCell.swift
//  Cornell Sun
//
//  Created by Austin Astorga on 10/5/17.
//  Copyright © 2017 cornell.sun. All rights reserved.
//

import UIKit
import SnapKit

final class LikeCommentCell: UICollectionViewCell {

    var post: PostObject? {
        didSet {
            let plural = post!.comments.count > 1 ? "comments" : "comment"
            commentLabel.text = post!.comments.isEmpty ? "" : "26 likes \u{2022} \(post!.comments.count) " + plural
        }
    }

    let commentLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.backgroundColor = .white
        addSubview(commentLabel)
        commentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leftMargin.equalTo(15.5)
        }
    }
}
