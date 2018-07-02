# Cornell Sun Article Age Classification
Naïve Bayes classifier client for predicting reader age on articles. This repo is also part of our final project for CS 4701: Practicum in Artificial Intelligence. See the other [repo on how we parsed our data](https://github.com/cornell-sun/sun-classifier-training-data). For a more detailed look into our project, feel free to see our [presentation slide deck](https://github.com/cornell-sun/sun-article-age-classifier/blob/master/_readme/classification_slides.pdf) or our [full technical report](https://github.com/cornell-sun/sun-article-age-classifier/blob/master/_readme/CS%204701%20Writeup.pdf).

### Team
- Chris Sciavolino ([@cdsciavolino](https://github.com/cdsciavolino))
- Mindy Lou ([@mindylou](https://github.com/mindylou))

### Overview
The Cornell Daily Sun has readership that spans college students to older readers trying to stay in touch with thier college roots. Fortunately, the website uses analytics software to gather insights about which articles is read by which age ranges. Using this data, we integrated a Naïve Bayes classifier that will predict which age range is most likely to read a given article.

### Data Breakdown
Given the Cornell Daily Sun is a college newspaper, it naturally follows that the far greater majority of people consuming content would be college students (ages 18-24). After observing this fact, we decided to group the original 6 groups (18-24, 25-34, 35-44, 45-54, 55-64, 65+) into 3: 18-24, 25-44, 45+. By grouping the data, we were able to better distribute the data into larger buckets so that one would not overpower the others. 

### Naïve Bayes Classifier
We decided to use a bag-of-words feature vector on a Naïve Bayes Classifier to predict the age range for a particular article. First we pre-processed a text file containing a JSON of our training data ([see Python data parsing repo](https://github.com/cornell-sun/sun-classifier-training-data)). That is, we split each group of articles into their labelled age range, split the article into word counts, and fed those word count dictionaries into the classifier. When testing, we took the article in question, split it into word counts, and the classifier would read these in and predict the age range of the article.

### Accuracy and Insights
From our training data of 800 articles, we split it approximately 70% into training data and 30% into testing data. From this accuracy rating, we found our classifier accurately identified the article's age range around 76% of the time. Although this was pretty good, we were able to get more insights by analyzing the words that were most indicative of each age range. For each of the age ranges, we found the following most indicative words:

![18-24 Most Common Words](https://github.com/cornell-sun/sun-article-age-classifier/blob/master/_readme/18-24-common-words.png)

![25-44 Most Common Words](https://github.com/cornell-sun/sun-article-age-classifier/blob/master/_readme/25-44-common-words.png)

![45+ Most Common Words](https://github.com/cornell-sun/sun-article-age-classifier/blob/master/_readme/45-common-words.png)

