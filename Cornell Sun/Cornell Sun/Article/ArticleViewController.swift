//
//  ArticleViewController.swift
//  Cornell Sun
//
//  Created by Mindy Lou on 10/16/17.
//  Copyright © 2017 cornell.sun. All rights reserved.
//

import UIKit
import HTMLString
import Bayes

enum FontSize {
    case regular
    case large
    case small

    func getFont() -> UIFont {
        switch self {
        case .regular:
            return .articleBody
        case .large:
            return .articleBodyLarge
        case .small:
            return .articleBodySmall
        }
    }
}

class ArticleViewController: UIViewController {
    let leadingOffset: CGFloat = 17.5
    let articleBodyOffset: CGFloat = 25
    let articleBodyInset: CGFloat = 36
    let articleSeparatorOffset: CGFloat = 15
    let separatorHeight: CGFloat = 1.5
    let articleHeaderHeight: CGFloat = 450
    let commentReuseIdentifier = "CommentReuseIdentifier"

    var post: PostObject!
    var comments: [CommentObject]! = []

    // dictionary in the form [feature_name -> feature_value]
    var featureDict: [String: Any] = [:]
    var classifier: BayesianClassifier<String, String>! = nil

    // UI Components
    var articleScrollView: UIScrollView!
    var articleView: UIView!
    var articleHeaderView: ArticleHeaderView!
    var articleBodyTextView: UITextView!
    var textSizeRightBarButtonItem: UIBarButtonItem!
    var commentsLabel: UILabel!
    var commentsTableView: UITableView!
    var articleEndSeparator: UILabel!

    var currentFontSize: FontSize = .regular

    let heroImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    convenience init(article: PostObject) {
        self.init()
        self.post = article
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.title = ""
        navigationController?.navigationBar.tintColor = .black
        textSizeRightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "textSize"), style: .plain, target: self, action: #selector(toggleSize))
        navigationItem.setRightBarButton(textSizeRightBarButtonItem, animated: true)
//        setupViews()
//        setupWithArticle()
        fillFeatureDictionary()
        let wordsArr = buildWordsArray()

        let ageGroupLabel = UILabel()
        ageGroupLabel.font = UIFont.systemFont(ofSize: 30)
        ageGroupLabel.textAlignment = .center
        guard let category = classifier.classify(wordsArr) else { return }
        ageGroupLabel.text = "Most likely age group: \(category)"
        view.addSubview(ageGroupLabel)
        ageGroupLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        let probabilitiesLabel = UILabel()
        probabilitiesLabel.textAlignment = .center
        probabilitiesLabel.text = "Top 5 words: \n"
        probabilitiesLabel.numberOfLines = 6
        view.addSubview(probabilitiesLabel)
        probabilitiesLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(ageGroupLabel.snp.bottom).offset(15)
        }

        var youngWords: [(word: String, weight: Double)] = []
        var midWords: [(word: String, weight: Double)] = []
        var oldWords: [(word: String, weight: Double)] = []
        var wordsSet = Set<String>()

        for word in wordsArr {
            wordsSet.insert(word)
        }

        for word in wordsSet {
            let youngWeight = self.classifier.eventSpace.P(word, givenCategory: "18-24")
            let midWeight = self.classifier.eventSpace.P(word, givenCategory: "25-44")
            let oldWeight = self.classifier.eventSpace.P(word, givenCategory: "45+")
            youngWords.append((word, youngWeight))
            midWords.append((word, midWeight))
            oldWords.append((word, oldWeight))
        }

        let youngWordsSorted: [(word: String, weight: Double)] = youngWords.sorted(by: { $0.weight > $1.weight })
        let midWordsSorted: [(word: String, weight: Double)] = midWords.sorted(by: { $0.weight > $1.weight })
        let oldWordsSorted: [(word: String, weight: Double)] = oldWords.sorted(by: { $0.weight > $1.weight })

        var youngWordIndicies: [String: Int] = [:]
        var midWordIndicies: [String: Int] = [:]
        var oldWordIndicies: [String: Int] = [:]

        for index in 0..<youngWordsSorted.count {
            let (youngWord, _) = youngWordsSorted[index]
            let (midWord, _) = midWordsSorted[index]
            let (oldWord, _) = oldWordsSorted[index]

            youngWordIndicies[youngWord] = index
            midWordIndicies[midWord] = index
            oldWordIndicies[oldWord] = index
        }

        var counter = 0
        if category == "18-24" {
            for (word, weight) in youngWordsSorted {
                let midIndex = midWordIndicies[word] ?? -1
                let oldIndex = oldWordIndicies[word] ?? -1
                if weight - midWordsSorted[midIndex].weight - oldWordsSorted[oldIndex].weight > 0.05 && counter < 5 {
                    probabilitiesLabel.text = probabilitiesLabel.text! + "\(word): \(weight)\n"
                    counter += 1
                }
            }
        } else if category == "25-44" {
            for (word, weight) in midWordsSorted {
                let youngIndex = youngWordIndicies[word] ?? -1
                let oldIndex = oldWordIndicies[word] ?? -1
                if weight - youngWordsSorted[youngIndex].weight - oldWordsSorted[oldIndex].weight > 0.05 && counter < 5 {
                    probabilitiesLabel.text = probabilitiesLabel.text! + "\(word): \(weight)\n"
                    counter += 1
                }
            }
        } else if category == "45+" {
            for (word, weight) in oldWordsSorted {
                let youngIndex = youngWordIndicies[word] ?? -1
                let midIndex = midWordIndicies[word] ?? -1
                if weight - youngWordsSorted[youngIndex].weight - midWordsSorted[midIndex].weight > 0.05 && counter < 5 {
                    probabilitiesLabel.text = probabilitiesLabel.text! + "\(word): \(weight)\n"
                    counter += 1
                }
            }
        }



//        var counter = 0
//        for (word, weight) in wordProbsSorted {
//            if counter < wordProbsSorted.count || counter < 4 {
//                probabilitiesLabel.text = probabilitiesLabel.text! + "\(word) : \(weight)\n"
//                counter += 1
//            }
//        }

//        print("This should be classified as: \(classifier.classify(wordsArr))")

    }

    @objc func toggleSize() {
        switch currentFontSize {
        case .regular:
            currentFontSize = .large
        case .large:
            currentFontSize = .small
        case .small:
            currentFontSize = .regular
        }
        articleBodyTextView.font = currentFontSize.getFont()
    }

    func setupViews() {
        articleScrollView = UIScrollView()
        guard let tabBarControllerHeight = tabBarController?.tabBar.frame.height else { return }
        articleScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tabBarControllerHeight, right: 0)
        view.addSubview(articleScrollView)
        articleScrollView.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview()
            make.top.bottom.leading.trailing.equalToSuperview()
        }

        articleView = UIView()
        articleScrollView.addSubview(articleView)
        articleView.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview()
            make.top.bottom.leading.trailing.equalToSuperview()
        }

        articleHeaderView = ArticleHeaderView(article: post, frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 0))
        articleView.addSubview(articleHeaderView)
        articleHeaderView.snp.makeConstraints { make in
            make.leading.trailing.width.top.equalToSuperview()
            make.height.equalTo(articleHeaderHeight)
        }

        articleBodyTextView = UITextView(frame: .zero)
        articleBodyTextView.isEditable = false
        articleBodyTextView.font = currentFontSize.getFont()
        articleView.addSubview(articleBodyTextView)
        articleBodyTextView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(leadingOffset)
            make.top.equalTo(articleHeaderView.snp.bottom)
            make.bottom.equalToSuperview().inset(300) // will update this to automatically resize to tableview content
        }

        articleEndSeparator = UILabel(frame: .zero)
        articleEndSeparator.backgroundColor = .warmGrey
        articleView.addSubview(articleEndSeparator)
        articleEndSeparator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(leadingOffset)
            make.height.equalTo(separatorHeight)
            make.top.equalTo(articleBodyTextView.snp.bottom).offset(articleSeparatorOffset)
        }

        commentsLabel = UILabel(frame: .zero)
        commentsLabel.text = "Comments"
        commentsLabel.font = UIFont.systemFont(ofSize: 15.0, weight: .bold)
        commentsLabel.textColor = .black
        articleView.addSubview(commentsLabel)
        commentsLabel.snp.makeConstraints { make in
            make.top.equalTo(articleEndSeparator.snp.bottom).offset(articleSeparatorOffset)
            make.leading.equalToSuperview().offset(leadingOffset)
        }

        commentsTableView = UITableView(frame: .zero)
        commentsTableView.register(CommentTableViewCell.self, forCellReuseIdentifier: commentReuseIdentifier)
        commentsTableView.delegate = self
        commentsTableView.dataSource = self
        commentsTableView.tableFooterView = UIView()
        commentsTableView.isScrollEnabled = false
        articleView.addSubview(commentsTableView)
        commentsTableView.snp.makeConstraints { make in
            make.width.leading.trailing.equalToSuperview()
            make.top.equalTo(commentsLabel.snp.bottom).offset(articleSeparatorOffset)
            make.height.equalTo(300)
        }
    }

    func setupWithArticle() {
        articleBodyTextView.text = post.content
        articleBodyTextView.isScrollEnabled = false
        articleBodyTextView.setNeedsUpdateConstraints()
        // hardcoded comments
        let comment1 = CommentObject(id: 0, postId: 0, authorName: "Brendan Elliott", comment: "Great Story! I really enjoyed reading about the perserverance of the current candidate, despite the stressful election.", date: Date(), image: #imageLiteral(resourceName: "brendan"))
        let comment2 = CommentObject(id: 0, postId: 0, authorName: "Hettie Coleman", comment: "This story was wack! But I will be respectful because that’s how online discourse should be!", date: Date(), image: #imageLiteral(resourceName: "emptyProfile"))
        comments.append(comment1)
        comments.append(comment2)
        commentsTableView.reloadData()
    }
}

extension ArticleViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150 // will need to auto resize tableviewcells eventually
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: commentReuseIdentifier, for: indexPath) as? CommentTableViewCell ?? CommentTableViewCell()
        let comment = comments[indexPath.row]
        cell.setup(for: comment)
        return cell
    }

}

extension ArticleViewController {

    func buildWordsArray() -> [String] {
        var wordObservations: [String] = []
        for word in post.content.components(separatedBy: " ") {
            wordObservations.append(word.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return wordObservations
    }

    func fillFeatureDictionary() {
        print(self.post.content)
        // length of the article's title
        self.featureDict["titleLength"] = self.post.title.count

        // category of the article -- could also trim this
        self.featureDict["category"] = self.post.categories

        // tags
        self.featureDict["tags"] = self.post.tags

        // content size -- could also sanitize the HTML
        self.featureDict["contentSize"] = self.post.content.count

        // number of images associated with post
        self.featureDict["numImages"] = self.post.photoGalleryObjects.count

        // primary category
        self.featureDict["primaryCategory"] = self.post.primaryCategory

        // tokenized title to be implemented later
        //let tagger = NSLinguisticTagger(tagSchemes: [.tokenType, .nameTypeOrLexicalClass, .language], options: 0)
        //tagger.string = self.post.title

        // average word length in title
        var wordCount = 0

        for word in self.post.title.components(separatedBy: " ") {
            print(word)
            wordCount += 1
        }

        self.featureDict["averageTitleWordLength"] = self.post.title.count / wordCount

        // Title split on "|"
        let pipeIndex = self.post.title.index(of: "|") ?? self.post.title.endIndex
        print(self.post.title[..<pipeIndex])
        self.featureDict["pipeTitle"] = self.post.title[..<pipeIndex].trimmingCharacters(in: .whitespacesAndNewlines)
        print("Feature Dictionary: \(self.featureDict)")
    }
}
