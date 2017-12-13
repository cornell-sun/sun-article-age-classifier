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
    var classifier: BayesianClassifier<String, String>!
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
            var wordsSet: Set<String> = []
            var count = 0.0
            var numYoungPeople = 0
            for article in trainingDataDict.keys where classificationDict[article] == "18-24" {
                numYoungPeople += 1
            }

            print("Total training data entries: \(trainingDataDict.count)")
            print("Total 18-24 classifications: \(numYoungPeople)")
            
            for article in trainingDataDict.keys {
                let ageClassification: String = classificationDict[article] ?? ""
                let wordCounts: [String: Int] = trainingDataDict[article] ?? [:]
                var wordObservations: [String] = []
                for word in wordCounts.keys {
                    let numOccurrences = wordCounts[word] ?? 0
                    for _ in 1...numOccurrences {
                        wordsSet.insert(word)
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

            self.classifier = BayesianClassifier(eventSpace: eventSpace)
            var numCorrect = 0

            for article in testingDict.keys {
                let wordObservations = testingDict[article] ?? []
                let wordClassification = classificationDict[article]
                if self.classifier.classify(wordObservations) == wordClassification {
                    numCorrect += 1
                }
            }

            print("Number correct: \(numCorrect)")

            var youngWords: [(word: String, weight: Double)] = []
            var midWords: [(word: String, weight: Double)] = []
            var oldWords: [(word: String, weight: Double)] = []

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

            print("------POPULAR YOUNG WORDS-----")
            for (word, weight) in youngWordsSorted {
                let midIndex = midWordIndicies[word] ?? -1
                let oldIndex = oldWordIndicies[word] ?? -1
                if weight - midWordsSorted[midIndex].weight - oldWordsSorted[oldIndex].weight > 0.1 {
                    print((word, weight))
                }
            }

            print("------POPULAR MID WORDS-----")
            for (word, weight) in midWordsSorted {
                let youngIndex = youngWordIndicies[word] ?? -1
                let oldIndex = oldWordIndicies[word] ?? -1
                if weight - youngWordsSorted[youngIndex].weight - oldWordsSorted[oldIndex].weight > 0.1 {
                    print((word, weight))
                }
            }

            print("------POPULAR OLD WORDS-----")
            for (word, weight) in oldWordsSorted {
                let youngIndex = youngWordIndicies[word] ?? -1
                let midIndex = midWordIndicies[word] ?? -1
                if weight - youngWordsSorted[youngIndex].weight - midWordsSorted[midIndex].weight > 0.1 {
                    print((word, weight))
                }
            }
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
        articleVC.classifer = self.classifier
        articleVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(articleVC, animated: true)
    }
}
