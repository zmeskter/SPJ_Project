using Pkg
Pkg.activate(pwd() * "/examples")
Pkg.instantiate()
Pkg.resolve()
using Revise # this must come before `using PCDGroundRemoval`
using PCDGroundRemoval
using BenchmarkTools

#load data
points = read_xyz("data//1651738515.007457803.xyz")
points = read_xyz("data//1651738522.626975236.xyz")
points = read_xyz("data//1651738552.829550165.xyz")
#compute distances from [0,0,0]
distances = @calculate_distance([0, 0, 0], points)

#remove dron points
points = remove_drone(points, distances)
@benchmark remove_drone(points, distances)
@benchmark remove_drone_old(points, distances)

#sort points into pillar grid
grid = make_pillar_grid(points;grid_box_size= 1.8)
@benchmark make_pillar_grid(points;grid_box_size= 1.8)
@benchmark make_pillar_grid_old(points;grid_box_size= 1.8)
#label ground points
ground = label_ground_points(grid; threshold = 0.4)
possible_ground_idx = findall(pts -> pts < 0, ground[:,3])
ground = ground[possible_ground_idx, :]

#remove ground
without_ground = remove_ground_points(grid; threshold = 0.4)
@benchmark remove_ground_points(grid; threshold = 0.4)
#save data after dron removal
save_xyz(points, "data//without_ground.xyz")

#clustering
clusters_dbscan = clustering(Matrix(transpose(without_ground[:,1:2])), 0.12, 2)
clusters_ind = getproperty.(clusters_dbscan, :core_indices)
clusters = [without_ground[i,:] for i in clusters_ind] #points sorted into clusters

#find if point is in pointcloud
pts = ground[1,:]
all(points .== pts', dims=2)
findall(all(points .== pts', dims=2)[:, 1])

#examples of distance and removal functions calls
delete_zero(grid[1,:,:])
distance([0, 0, 0],points)
distance(delete_zero(grid[1,:,:]), delete_zero(grid[3,:,:]))
distance(delete_zero(grid[1,:,:]), delete_zero(grid[2,:,:]))
distance(delete_zero(grid[2,:,:]), delete_zero(grid[1,:,:]))
distance(delete_zero(grid[1,:,:]), Matrix{Float64}(undef,0,3))

using Plots
#classification + visualization
plotlyjs()
plt = classify_bare_trunk(clusters;threshold1 = 0.1, threshold2 = 0.1, accuracy = 0.75, ignore_points = 20)

#visualizations
plotlyjs()
scatter3d(points[:,1], points[:,2], points[:, 3],color = RGB(0,1,0), markersize = 1)
scatter3d(without_ground[:,1], without_ground[:,2], without_ground[:, 3],color = RGB(0,1,0), markersize = 1)
scatter3d!(ground[:,1], ground[:,2], ground[:, 3], color = RGB(1,0,0),markersize = 1)
scatter3d(clusters[51][:,1], clusters[51][:,2], clusters[51][:, 3],color = RGB(0,1,0), markersize = 1)
scatter3d!(clusters[2][:,1], clusters[2][:,2], clusters[2][:, 3],color = RGB(1,0,0), markersize = 1)
scatter3d!(clusters[3][:,1], clusters[3][:,2], clusters[3][:, 3],color = RGB(0,0,1), markersize = 1)




