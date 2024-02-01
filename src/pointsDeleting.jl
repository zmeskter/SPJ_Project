using Base.Threads
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
    indexes = Int[]
    my_lock = SpinLock()

    @threads for i in 1:size(points, 1)
        if any(x -> x != 0, points[i, :, :])
            lock(my_lock)
            try
                push!(indexes, i)
            finally
                unlock(my_lock)
            end
        end
    end

    if isempty(indexes)
        return similar(points, 0, 0, 0)  # Return an empty array if no non-zero elements are found
    end

    grid2 = points[sort(indexes), :, :]  # Sort indexes to make sure they are in correct order
    return copy(grid2)
end

function delete_zero_old(points::Array{<:Real,3})
    indexes = []
    for i = 1:size(points)[1]
        if sum(abs.(points[i,:,:])) != 0
            append!(indexes, i)
        end
    end
    grid2 = zeros((size(indexes)[1], size(points)[2], 3))
    for i = 1:size(indexes)[1]
        grid2[i,:,:] = points[indexes[i],:,:]
    end
    return grid2
end

function delete_zero(points::Array{<:Real,2})
    indexes = Int[]
    my_lock = SpinLock()

    @threads for i in 1:size(points, 1)
        if any(x -> x != 0, points[i, :, :])
            lock(my_lock)
            try
                push!(indexes, i)
            finally
                unlock(my_lock)
            end
        end
    end

    if isempty(indexes)
        return similar(points, 0, 0)  # Return an empty array if no non-zero elements are found
    end

    grid2 = points[sort(indexes), :]  # Sort indexes to make sure they are in correct order
    return copy(grid2)
end

export delete_zero