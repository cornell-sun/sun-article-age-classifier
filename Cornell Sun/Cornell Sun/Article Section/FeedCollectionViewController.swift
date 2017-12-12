//
//  FeedCollectionViewController.swift
//  Cornell Sun
//
//  Created by Austin Astorga on 9/3/17.
//  Copyright © 2017 cornell.sun. All rights reserved.
//

import UIKit
import IGListKit
import Realm
import RealmSwift
import Bayes

class FeedCollectionViewController: ViewController, UIScrollViewDelegate {
    var feedData: [PostObject] = []
    var firstPostObject: PostObject!
    var savedPosts: Results<PostObject>!
    var currentPage = 1
    var loading = false
    let spinToken = "spinner"
    let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.alwaysBounceVertical = true
        view.backgroundColor = .white
        return view
    }()

    lazy var adapter: ListAdapter  = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 0)
    }()

    override func viewDidAppear(_ animated: Bool) {
        //we could possibly have saved posts
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.collectionView?.backgroundColor = UIColor(white: 241.0 / 255.0, alpha: 1.0)
        adapter.dataSource = self
        adapter.scrollViewDelegate = self
        savedPosts = RealmManager.instance.get()
        getPosts(page: currentPage)

        DispatchQueue.main.async {
            print("Creating event space")
            var eventSpace = EventSpace<String, String>()
            let classificationDict = self.getDictionaryFromTextFile(fileName: "post_classifications") as? [String: String] ?? [:]
            let trainingDataDict = self.getDictionaryFromTextFile(fileName: "training_data") as? [String: [String: Int]] ?? [:]
            var trainingDict: [String: [String]] = [:]
            var testingDict: [String: [String]] = [:]
            let numTrainingEntries = trainingDataDict.keys.count
            var count = 0.0
            for article in trainingDataDict.keys {
                let ageClassification: String = classificationDict[article] ?? ""
                let wordCounts: [String: Int] = trainingDataDict[article] ?? [:]
                var wordObservations: [String] = []
                for word in wordCounts.keys {
                    let numOccurrences = wordCounts[word] ?? 0
                    for _ in 1...numOccurrences {
                        wordObservations.append(word)
                    }
                }

                if count < Double(numTrainingEntries) * 0.7 {
                    // use for training
                    trainingDict[article] = wordObservations
                    eventSpace.observe(ageClassification, features: wordObservations)
                } else {
                    // use for testing
                    testingDict[article] = wordObservations
                }
                count += 1
            }

            print("Num training entries: \(trainingDict.count)")
            print("Num testing entries: \(testingDict.count)")

            let classifier = BayesianClassifier(eventSpace: eventSpace)
            var numCorrect = 0

            for article in testingDict.keys {
                let wordObservations = testingDict[article] ?? []
                let wordClassification = classificationDict[article]
                if classifier.classify(wordObservations) == wordClassification {
                    numCorrect += 1
                }
            }

            print("Number correct: \(numCorrect)")
        }
    }

    func getDictionaryFromTextFile(fileName: String) -> [String: Any]? {
        if let filepath = Bundle.main.path(forResource: fileName, ofType: "txt") {
            do {
                let jsonString = try String(contentsOfFile: filepath)
                if let data = jsonString.data(using: .utf8) {
                    do {
                        return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } catch {
                // contents could not be loaded
            }
        } else {
            // example.txt not found!
        }
        return [:]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getPosts(page: Int) {
        let savedPostIds: [Int] = savedPosts.map({$0.id})
        API.request(target: .posts(page: page)) { (response) in
            self.loading = false
            guard let response = response else {return}
            do {
                let jsonResult = try JSONSerialization.jsonObject(with: response.data, options: [])
                if let postArray = jsonResult as? [[String: Any]] {
                    for postDictionary in postArray {
                        if let post = PostObject(data: postDictionary) {
                            if self.firstPostObject == nil {
                                self.firstPostObject = post
                            }
                            if savedPostIds.contains(post.id) {
                                post.didSave = true
                            }
                            self.feedData.append(post)
                        }
                    }
                    self.adapter.performUpdates(animated: true, completion: nil)
                }
            } catch {
                print("could not parse")
                // can't parse data, show error
            }
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let distance = scrollView.contentSize.height - (targetContentOffset.pointee.y + scrollView.bounds.height)
        if !loading && distance < 300 {
            loading = true
            adapter.performUpdates(animated: true, completion: nil)
            currentPage += 1
            getPosts(page: currentPage)
        }
    }

}

extension FeedCollectionViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        var objects = feedData as [ListDiffable]
        if loading {
            objects.append(spinToken as ListDiffable)
        }
        return objects
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if let obj = object as? String, obj == spinToken {
            return spinnerSectionController()
        } else if let obj = object as? PostObject, obj.isEqual(toDiffableObject: firstPostObject) {
            return HeroSectionController()
        } else if let obj = object as? PostObject, obj.postType == .photoGallery {
            return PhotoGallerySectionController()
        }
        let articleSC = ArticleSectionController()
        articleSC.delegate = self
        return articleSC
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }

}

extension FeedCollectionViewController: TabBarViewControllerDelegate {
    func articleSectionDidPressOnArticle(_ article: PostObject) {
        let articleVC = ArticleViewController(article: article)
        articleVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(articleVC, animated: true)
    }
}
