//
//  Extensions.swift
//  Cornell Sun
//
//  Created by Austin Astorga on 9/4/17.
//  Copyright © 2017 cornell.sun. All rights reserved.
//

import UIKit
import Kingfisher

func captionMaxHeight(width: CGFloat) -> CGFloat {
     let tmpStr = "A rink attendant collect fish thrown by the Cornell students in a tradition that spans over decades. (Cameron Pollack/ Sun Photography Editor)"
    return tmpStr.height(withConstrainedWidth: width - 36, font: UIFont(name: "Georgia", size: 13)!)
}

//func titleMaxHeight(width: CGFloat) -> CGFloat {
//    let tmpStr = ""
//    return tmpStr.height(withConstrainedWidth: , font: .bookmarkTitle)
//}

func getCurrentViewController() -> UIViewController? {

    if let rootController = UIApplication.shared.keyWindow?.rootViewController {
        var currentController: UIViewController! = rootController
        while currentController.presentedViewController != nil {
            currentController = currentController.presentedViewController
        }
        return currentController
    }
    return nil
}

func taptic(style: UIImpactFeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.prepare()
    generator.impactOccurred()
}

func cacheImage(imageLink: String) {
    if let urlImage = URL(string: imageLink) {
        KingfisherManager.shared.retrieveImage(with: urlImage, options: nil, progressBlock: nil, completionHandler: nil)
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)

        return ceil(boundingBox.width)
    }

    var htmlToAttributedString: NSAttributedString? {
        do {
            return try NSAttributedString(data: Data(utf8),
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            print("error:", error)
            return  nil
        }
    }

    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}

extension UIView {
    func addConstraintsWithFormat(_ format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }

        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
    }
}

let imageCache = NSCache<NSString, UIImage>()
class ArticleImageView: UIImageView {
    var imageUrlString: String?

    func loadImageUsingUrlString(_ urlString: String) {
        imageUrlString = urlString
        let url = URL(string: urlString)
        image = nil

        if let imageFromCache = imageCache.object(forKey: urlString as NSString) {
            self.image = imageFromCache
            return
        }

        URLSession.shared.dataTask(with: url!) { data, _, error in
            if error != nil {
                print(error!) //@todo Crashlytics
                return
            }

            DispatchQueue.main.async(execute: {
                let imageToCache = UIImage(data: data!)

                if self.imageUrlString == urlString {
                    self.image = imageToCache
                }
                imageCache.setObject(imageToCache!, forKey: urlString as NSString)
                })
        }.resume()
    }
}
