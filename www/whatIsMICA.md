---
output: html_document
---



### What is MICA?
*MICA* is a tool that aims to identify and group minerals that have similar chemical compositions.

This is a fairly common problem; the identification of a mineral based on it's chemistry is a difficult task. Hopefully *MICA* can make it a bit easier!

*MICA* is built from the database of minerals at [webmineral.com](www.webmineral.com) which consists of 4722 minerals. The composition of 85 elements for each mineral is recorded in the database. 

### Finding similar minerals
Comparing minerals in 85-dimension space would be an impossible task. So using the [UMAP algorithm](https://github.com/lmcinnes/umap), we reduce the dimensionality of the data to three dimensions. Now that our data is in 3D, we can visually assess similar groups of minerals and identify naturally occurring relationships between groups of minerals.

In it's most basic form, *MICA* looks like this:
<center>
<img src="Image Coloured by Sulfer.png" align="middle" width="100%" margin="0 auto" />
*Each dot represents a mineral. The minerals are coloured by their Sulfur and sized by their Copper content*
</center>

Each of these individual dots represents one of the 4722 minerals found in the webmineral database.

The quantitative distance between points isn't particularly meaningful due to the highly non-linear nature of the dimension reduction. However, the distance between one point relative to another _is_ meaningful. Minerals that have a small distance between them are more similar than those which are far away.

### Creating natural groups of minerals
We use the [DBSCAN algorithm](https://en.wikipedia.org/wiki/DBSCAN) to perform density-based clustering on the reduced-dimensionality mineral data. This gives us a number of clusters with constituent minerals that have similar chemical compositions.

*MICA* shows you a list of the elements in a selected cluster, along with their associated chemical formulae.

### Importance of elements within clusters
Being able to quickly assess the importance of certain elements within a group of minerals can be informative.

We use the [Random Forest algorithm](https://en.wikipedia.org/wiki/Random_forest) to build a quick unsupervised model that finds the elements that best distinguish the current cluster of minerals from all other minerals. The mean decrease in the Gini index for each element is ranked and displayed.
