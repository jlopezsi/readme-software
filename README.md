# readme2

An R package for estimating category proportions in an unlabeled set of documents given a labeled set, by implementing the method described in [Jerzak, King, and Strezhnev (2019)](http://GaryKing.org/words). This method is meant to improve on the ideas in Hopkins and King (2010), which introduced a quantification algorithm to estimate category proportions without directly classifying individual observations. This version of the software refines the original method by implementing a technique for selecitng optimal textual features in order to minimize the error of the estimated category proportions. Automatic differentiation, stochastic gradient descent, and batch re-normalization are used to carry out the optimization. Other pre-processing functions are available, as well as an interface to the earlier version of the algorithm for comparison. The package also provides users with the ability to extract the generated features for use in other tasks.

(*Here's the abstract from our paper:*  Some scholars build models to classify documents into chosen categories. Others, especially social scientists who tend to focus on population characteristics, instead usually estimate the proportion of documents in each category -- using either parametric "classify-and-count" methods or "direct" nonparametric estimation of proportions without individual classification. Unfortunately, classify-and-count methods can be highly model dependent or generate more bias in the proportions even as the percent of documents correctly classified increases. Direct estimation avoids these problems, but can suffer when the meaning of language changes between training and test sets or is too similar across categories. We develop an improved direct estimation approach without these issues by including and optimizing continuous text features, along with a form of matching adapted from the causal inference literature. Our approach substantially improves performance in a diverse collection of 73 data sets. We also offer easy-to-use software software that implements all ideas discussed herein.)

## Installation

The most recent version of `readme2` can be installed directly from the repository using the `devtools` package

```
devtools::install_github("iqss-research/readme-software/readme")
```

`readme2` depends on the `tools`, `data.table`, `limSolve` and `FNN` packages which can be installed directly from CRAN

It also utilizes `tensorflow`, the R interface to the TensorFlow API -- an open source machine learning library. To install `tensorflow` follow the instructions available at the [RStudio page on R and TensorFlow](https://tensorflow.rstudio.com/tensorflow/).

First, install the R package via github

```
devtools::install_github("rstudio/tensorflow")
```

Then, install TensorFlow itself via the R function `install_tensorflow()`.

```
library(tensorflow)
install_tensorflow()
```

`readme` uses pre-trained dictionaries of word vectors as part of the process of translating the words in documents to a numerical representation. We suggest a default dictionary that can be downloaded and installed to the `readme` install directory using the `download_wordvecs()` function. Be aware that it may be worthwhile to change these if you are using a different language than English or texts with very unique forms of language use.

## Walkthrough

In this section, we provide a step-by-step vignette illustrating how to use `readme2` to estimate category proportions in an unlabeled set of documents. To begin, we assume that the user has a set of *labeled* documents, with every document assigned a single, mutually exclusive category label (such as via manual coding). We observe an unlabeled set of documents and seek to estimate the proportion of documents with each category label. 

The central intuition of the original `readme` is that for any individual feature _S_ in both the labeled and unlabeled set, we know that the average value of that feature _S_ is equal to the sum of the conditional expectation of _S_ in each category multiplied by the share of documents in that category. While we observe the average of _S_ in the unlabeled set, we do not observe the conditional expectations of _S_. We estimate these conditional expectations using the labeled set conditional frequency and solve for the unlabeled set proportions via standard linear programming methods.

There are many possible features _S_ that can be extracted from the text. The main contribution of `readme2` is to develop a way for selecting optimal sets of features from a large space of potential document summaries, morphing the space in which the readme regression is run to yield the best possible estimates of the category proportions. We begin by converting each document into a vector of summaries based on the word vector representations of each term in the document.

### Processing the text documents 

We illustrate the method using the provided `clinton` dataset of a subset of handcoded blogposts from the original Hopkins and King (2010) paper. This dataset is comprised of 1,676 documents coded into 6 mutually exclusive categories (`TRUTH`).

```
library(readme)
data(clinton, package="readme")
```

The first task is to convert the raw text for each document (`TEXT`) into a document-feature matrix using the word vector summaries; to load the word vector summaries into a table we use the `undergrad()` function (named in honor of those who have do so much coding by hand!). 

Prior to using `undergrad()` it is necessary to obtain a word vector dictionary that maps text tokens to a vector representation. We recommend using an off-the-shelf pre-trained word vector set based on a well-known language corpus. We include a function, `download_wordvecs()`, which when run will download our suggested default - a Stanford GloVe: 'Global Vectors for Word Representation' pre-trained dataset - to the directory in which `readme` is installed.

The `undergrad()` function takes as input the raw document texts and the word vector dictionary and returns a set of feature summaries for each document in the dataset. `cleanme()` pre-processes the text. Setting `wordVecs` to `NULL` will cause the function to search for the default word vector file called `glove.6B.200d.txt` in the `readme` installation directory (which is the default file downloaded by `download_wordvecs()`). If this file is found, it will read it directly and use it as the word vector dictionary.

```
## Generate a word vector summary for each document
wordVec_summaries = undergrad(documentText = cleanme(clinton$TEXT), wordVecs = NULL)
```

### Estimating topic proportions with `readme2`

With the topic, training set labels and features we can start estimating the model.

```
# Estimate category proportions
set.seed(2138) # Set a seed if you choose
readme.estimates <- readme(dfm = wordVec_summaries , labeledIndicator = clinton$TRAININGSET, categoryVec = clinton$TRUTH)
```

We can compare the output with the true category codings

```
# Output proportions estimate
readme.estimates$point_readme
# Compare to the truth
table(clinton$TRUTH[clinton$TRAININGSET == 0])/sum(table((clinton$TRUTH[clinton$TRAININGSET == 0])))
```

## License

Creative Commons Attribution-Noncommercial-No Derivative Works 4.0, for academic use only.

## Acknowledgments

Our thanks to Neal Beck, Aykut Firat, Ying Lu, and Jonathan Chiang for data and helpful comments.

