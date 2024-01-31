"""
    delete_zero(points::Array{<:Real,3})

take NxMx3 array of point sorted into N pillars and delete those pillars which contain no point -> [n,:,:] are only zeros
# Examples
```julia-repl
julia> delete_zero([1 1 0; 0 0 0; 0 0 0;;; 0 0 0; 0 0 0;0 0 0;;; 2 2 0; 3 3 0;0 0 0])
2x3x3 Array{Float64, 3}:
[:, :, 1] =
 1.0  1.0  0.0
 0.0  0.0  0.0

[:, :, 2] =
 0.0  0.0  0.0
 0.0  0.0  0.0

[:, :, 3] =
 2.0  2.0  0.0
 3.0  3.0  0.0
```
"""
function delete_zero(points::Array{<:Real,3})
    indexes = []
    for i = 1:size(points)[1]
        #println(points[i,:,:])
        #println("i=",i, "    ",sum(points[i,:,1:2]) )
        if sum(abs.(points[i,:,:])) != 0
            append!(indexes, i)
        end
    end
    #print(indexes)
    grid2 = zeros((size(indexes)[1], size(points)[2], 3))
    for i = 1:size(indexes)[1]
        grid2[i,:,:] = points[indexes[i],:,:]
    end
    return grid2
end

"""
    delete_zero(points::Array{<:Real,2})

take Nx3 Matrix of 3D point and delete all occurrences of point [0,0,0]
# Examples
```julia-repl
julia> delete_zero([1 1 1; 0 0 0; 2 2 2])
2x3 Matrix{Float64}:
 1.0  1.0  1.0
 2.0  2.0  2.0
```
"""
function delete_zero(points::Array{<:Real,2})
    
    indexes = []
    for i=1:size(points)[1]
        #println(sum(points[i,:]), "   ", i)
        if sum(abs.(points[i,:,:])) != 0
            append!(indexes, i)
        end
    end
    real_points = zeros((size(indexes)[1], 3))
    for i = 1:size(indexes)[1]
        real_points[i,:] = points[indexes[i],:]
    end
    return real_points
end

export delete_zero