module SPJ_Project
using Clustering
using Random
using Base.Threads
using Distributed
# Write your package code here.
include("xyzIO.jl")
include("pointsDeleting.jl")
include("distances.jl")
include("circleFitting.jl")
include("classify.jl")


"""
    make_pillar_grid(points::Matrix{<:Real}; grid_box_size = 1.8)

Take Nx3 Matrix of points and return points devided to grid with specific box size: NxMx3 array and delete those pillars with no points
# Examples
```julia-repl
julia> make_pillar_grid([0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3 3 3]; grid_box_size = 1.8)
2x5x3 Array{Float64, 3}:
[:, :, 1] =
 0.0  1.0  1.5  0.0  0.0
 2.0  3.0  0.0  0.0  0.0

[:, :, 2] =
 0.0  1.0  1.5  0.0  0.0
 2.0  3.0  0.0  0.0  0.0

[:, :, 3] =
 0.0  1.0  1.5  0.0  0.0
 2.0  3.0  0.0  0.0  0.0

 julia> make_pillar_grid([0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3.1 3.1 3]; grid_box_size = 1)
3x5x3 Array{Float64, 3}:
[:, :, 1] =
 1.0  1.5  0.0  0.0  0.0
 2.0  0.0  0.0  0.0  0.0
 3.1  0.0  0.0  0.0  0.0

[:, :, 2] =
 1.0  1.5  0.0  0.0  0.0
 2.0  0.0  0.0  0.0  0.0
 3.1  0.0  0.0  0.0  0.0

[:, :, 3] =
 1.0  1.5  0.0  0.0  0.0
 2.0  0.0  0.0  0.0  0.0
 3.0  0.0  0.0  0.0  0.0
```
"""
function make_pillar_grid(points::Matrix{<:Real}; grid_box_size = 1.8)
    x_max, y_max, x_min, y_min = my_extremas(points, grid_box_size)
    xmin = ceil(abs(minimum(points[:, 1])))
    ymin = ceil(abs(minimum(points[:, 2])))
    
    x_size = x_min + x_max
    y_size = y_min + y_max
    
    X, Y = points[:, 1], points[:, 2]
    
    grid = zeros(Float64, (x_size * y_size, size(points, 1), 3))
    
    x_offsets = grid_box_size * (0:x_size) .- xmin
    y_offsets = grid_box_size * (0:y_size) .- ymin
    
    @threads for i in 1:x_size
        for j in 1:y_size
        x_part = (x_offsets[i] .<= X .< x_offsets[i + 1])
        y_part = (y_offsets[j] .<= Y .< y_offsets[j + 1])
        
        common = x_part .& y_part
        
        view_grid = view(grid, i + (j - 1) * x_size, 1:count(Bool, common), :)
        view_points = view(points, common, :)
        copyto!(view_grid, view_points)
    end
end
    
    return delete_zero(grid)
end

function make_pillar_grid_old(points::Matrix{<:Real}; grid_box_size = 1.8)
    x_max, y_max, x_min, y_min = my_extremas(points, grid_box_size)
    xmin = ceil(abs(minimum(points[:, 1])))
    ymin = ceil(abs(minimum(points[:, 2])))
    
    x_size = x_min + x_max
    y_size = y_min + y_max
    
    X, Y = points[:, 1], points[:, 2]
    
    grid = zeros(Float64, (x_size * y_size, size(points, 1), 3))
    
    for i in 1:x_size, j in 1:y_size
        x_part = findall(x -> (grid_box_size * i - xmin > x >= grid_box_size * (i - 1) - xmin), X)
        y_part = findall(y -> (grid_box_size * j - ymin > y >= grid_box_size * (j - 1) - ymin), Y)
        
        common = intersect(x_part, y_part)
        shape = size(common, 1)
        
        grid[(i - 1) * y_size + j, 1:shape, :] .= @view points[common, :]
    end
    
    return delete_zero(grid)
end

function my_extremas(points::Matrix{<:Real}, grid_box_size)
    x_max = ceil(Int64,ceil( (abs(maximum(points[:,1]))))/grid_box_size)
    y_max = ceil(Int64,ceil((abs(maximum(points[:,2]))))/grid_box_size)
    x_min = ceil(Int64,ceil((abs(minimum(points[:,1]))))/grid_box_size)
    y_min = ceil(Int64,ceil((abs(minimum(points[:,2]))))/grid_box_size)
    return x_max,y_max,x_min, y_min
end

function remove_drone_old(points::Matrix{<:Real}, distances::Array{<:Real})
    distance_not_zero_idx = findall(dist-> dist != 0, distances)
    distance_not_zero = distances[distance_not_zero_idx]
    distance_smaller_than = findall(dist-> dist >= 0.35, distance_not_zero)
    points_without_zero = points[distance_not_zero_idx,:]
    points = points_without_zero[distance_smaller_than,:]
    return points
end

function remove_drone(points::Matrix{<:Real}, distances::Vector{<:Real})
    # Find indices of points to keep
    keep_indices = (distances .!= 0) .& (distances .> 0.35)

    # Use logical indexing to extract the desired points
    return points[keep_indices, :]
end

"""
    remove_ground_points(grid::Array{<:Real}; threshold = 0.45)

Take grid (NxMx3 array) with the points sorted into pillars and return 
the Nx3 matrix of the points labeled as ground.
"""
function label_ground_points(grid::Array{<:Real}; threshold = 0.45)
    ground_pts = zeros(Float64, 0, 3)

    for i in 1:size(grid, 1)
        all_points = grid[i, :, :]
        real_points_idx = findall(pts -> pts != 0, sum(abs.(all_points), dims=2)[:, 1])
        real_points = all_points[real_points_idx, :]

        if(size(real_points)[1] == 0)
            continue
        end

        min_point = minimum(real_points[:, 3])
        ground_points_idx = findall(pts -> pts < min_point + threshold, real_points[:, 3])
        ground_points = real_points[ground_points_idx, :]

        ground_pts = vcat(ground_pts, ground_points)
        ground_pts =unique(ground_pts, dims = 1)
    end

    return ground_pts
end

"""
    remove_ground_points(grid::Array{<:Real}; threshold = 0.45)

Take grid (NxMx3 array) with the points sorted into pillars, delete the points that belong to the ground 
and return the Nx3 matrix of the remaining points.
"""
function remove_ground_points(grid::Array{<:Real}; threshold = 0.45)
    no_ground_pts = zeros(Float64, 0, 3)

    @threads for i in 1:size(grid, 1)
        all_points = grid[i, :, :]
        real_points = all_points[all_points[:, 3] .!= 0, :]

        if size(real_points, 1) == 0
            continue
        end

        min_point = minimum(real_points[:, 3])
        no_ground_points = real_points[real_points[:, 3] .>= min_point + threshold, :]

        # Append non-ground points directly without concatenation
        no_ground_pts = vcat(no_ground_pts, no_ground_points)
    end

    no_ground_pts = unique(no_ground_pts, dims=1)

    return no_ground_pts
end

function remove_ground_points_old(grid::Array{<:Real}; threshold = 0.45)
    no_ground_pts = zeros(Float64, 0, 3)

    for i in 1:size(grid, 1)
        all_points = grid[i, :, :]
        real_points_idx = findall(pts -> pts != 0, sum(abs.(all_points), dims=2)[:, 1])
        real_points = all_points[real_points_idx, :]

        if(size(real_points)[1] == 0)
            continue
        end

        min_point = minimum(real_points[:, 3])
        no_ground_points_idx = findall(pts -> pts >= min_point + threshold, real_points[:, 3])
        no_ground_points = real_points[no_ground_points_idx, :]

        no_ground_pts = vcat(no_ground_pts, no_ground_points)
    end


    no_ground_pts =unique(no_ground_pts, dims = 1)

    return no_ground_pts
end

"""
    clustering(points::Matrix{<:Real}, eps::Real, min::Int)

Take Nx3 matrix of points and using DBSCAN devide them into clusters
# Params:

eps: the radius of a point neighborhood

min: the minimum number of neighboring points (including itself) to qualify a point as a density point
"""
function clustering(points::Matrix{<:Real}, eps::Real, min::Int)
    return dbscan(points, eps, min_neighbors = min, min_cluster_size = 20)
end


export make_pillar_grid_parallel, make_pillar_grid, make_pillar_grid_old, remove_drone, remove_drone_old, remove_ground_points_old, label_ground_points, remove_ground_points, clustering, RANSAC, center, fit_circle, fit_dist, my_extremas, classify_bare_trunk, get_color
end
