# Ground and dron removal with bare trunk classification
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

PCDGroundRemoval(SPJ_Project) package provides processing Point Cloud data in .xyz format. Removal of ground, points of the drone that collected the data and subsequent classification of bare trunks. 

The data used in the examples comes from forest dataset: https://github.com/ctu-mrs/slam_datasets/tree/master/forest
![](https://github.com/zmeskter/SPJ_Project/blob/main/data/doc_pic/forest_map.jpg)

# Instalation

The package is not available from official repositories and can be installed with the following command.
```
(@v1.8) pkg> add https://github.com/zmeskter/SPJ_Project
```

# Usage

The project focuses on two main parts - removal of ground and drone and classification of bare trunks. All functions are implemented in files in src folder. Example usage is shown in example.jl.
For example.jl to work properly you need to activate the examples environment: 
```
(PCDGroundRemoval) pkg> activate ./examples\\
```
![](https://github.com/zmeskter/SPJ_Project/blob/main/data/doc_pic/raw_data.png)

## Removal of ground and drone

First we remove the drone points -> i.e. points at a small distance from the point (0 , 0 , 0), where distance is the drone diameter. 
Then the remaining points are sorted into a grid, where each pillar has a square base of the specified edge length. Then, the lowest point in each pillar (the first ground point) is found and points within a small distance from this point are labled as ground points.

The fit of the plane through the lowest points in the adjacent pillars and the subsequent removal of the ground point below this plane proved to be inappropriate in this case due to the uneven terrain, therefore the above-described variant was chosen.

![](https://github.com/zmeskter/SPJ_Project/blob/main/data/doc_pic/without_ground.png)

## Classification of bare trunks

First, the data is sorted into clusters using the DBSCAN method. Then the data is projected into 2D space by neglecting the 'z' coordinate. A circle is fit to the data within each cluster using the RANSAC method and if more than k% (default k=75%) of the points lie within a specified distance from the given circle, the cluster is marked as a bare trunk.

![](https://github.com/zmeskter/SPJ_Project/blob/main/data/doc_pic/classif.png)

