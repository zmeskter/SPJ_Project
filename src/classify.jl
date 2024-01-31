using Plots

"""
    classify_bare_trunk(cluster; threshold1 = 0.1, threshold2 = 0.1, accuracy= 0.75, ignore_points = 20)

take NxMx3 array of points sorted into clusters and return plot image showing which clusters contain the tree (bare trunk)
these are shown in green in the picture. Clusters containing less than xxx points are coloured blue 
and the remaining clusters are coloured red - they do not contain a tree, but are large enough to be a major object.

# Optional params:

threshold1: for RANSAC -specifies the distance from the circle within which the point is taken as its inliner

threshold2: tolerance of the distance from the circle to take the point as part of the trunk

accuracy: what is the required percentage of points within the tolerance (treshold2) for the cluster to be considered a tree

ignore_points: minimum amount of points in the cluter to be considered

"""
function classify_bare_trunk(clusters; threshold1 = 0.1, threshold2 = 0.1, accuracy= 0.75, ignore_points = 20)
    x0,y0,r = RANSAC(clusters[1][:,1:2],2000,threshold1)
    color = get_color(clusters[1],x0,y0, r,threshold2,accuracy, ignore_points)
    plt = scatter3d(clusters[1][:,1], clusters[1][:,2], clusters[1][:, 3],color = color, markersize = 1)
    for i =2:61
        x0,y0,r = RANSAC(clusters[i][:,1:2],2000,threshold1)
        color = get_color(clusters[i],x0,y0,r,threshold2,accuracy, ignore_points)
        scatter3d!(clusters[i][:,1], clusters[i][:,2], clusters[i][:, 3],color =color, markersize = 1)
    end
    return plt
end

"""
    get_color(cluster,r, threshold, accuracy, ignore_points)

take Nx3 matrix of points from one cluster and returns the color that corresponds to how it was classified:

green: tree (bare trunk), red: not tree, but objet with enough points, blue: too small to be considered

# Params:

cluster: Nx3 matrix of points in cluster

r: radius of fitting circle (tree radius)

threshold: tolerance of the distance from the circle to take the point as part of the trunk

ignore_points: minimum amount of points in the cluter to be considered
"""
function get_color(cluster,x0,y0,r, threshold, accuracy, ignore_points)
    dist = distance([x0,y0], cluster[:,1:2])
    N = size(dist)[1]
    cnt = 0
    for i = 1:N
        if(dist[i] <= r +threshold && dist[i] >= r - threshold)
            cnt += 1
        end
    end
    
    if N < ignore_points
        return RGB(0,0,1)
    end

    if cnt/N > accuracy
        clr = RGB(0,1,0)
    else 
        clr = RGB(1,0,0)
    end
    return clr
end