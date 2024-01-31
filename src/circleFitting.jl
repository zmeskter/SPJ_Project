using Random
"""
    fit_circle(X)

take Nx2 matrix of points and returns the coefficients d,e,f of the circle given by the equation x^2 + y^2 + dx + ey + f = 0
"""
function fit_circle(X)
    N, M = size(X)
    A = hcat(X[:,1], X[:,2], ones(N,1))
    b = -X[:,1].^2 -X[:,2].^2
    K = A\b
    d = K[1]
    e = K[2]
    f = K[3]
    return d,e,f
end
"""
    center(d,e,f)

Calculate the coordinates of the centre (x0,y0) and radius (r) of the circle from 
the parameters d,e,f that correspond to the equation of the circle x^2 + y^2 + dx + ey + f = 0.
"""
function center(d,e,f)
    x0 = -d/2
    y0 = -e/2
    r = sqrt((d/2)^2+(e/2)^2-f)
    return x0,y0,r
end

"""
    fit_dist(X,x0,y0,r)

Calculate the distance of the point specified by the Nx2 matrix from the circle centered at [x0,y0] with radius r.
The points inside the circle will have negative distance, those outside will have positive distance.
"""
function fit_dist(X,x0,y0,r)
    N = size(X)[1]
    d = zeros(N)
    for i = 1:N
        d[i] = sqrt((X[i,1] - x0)^2 + (X[i,2] - y0)^2) - r
    end
    return d
end

"""
    RANSAC(X, num_iter, threshold)

Implementation of the RANSAC method for interpolating points with a circle.
It takes the points given by Nx2Matrix, selects 3 random points and intersects the circle with them. 
Calculate the distances of all points from this circle. 
If the distance of a point from the circle is less than a threshold, declare it an inlier. 
Repeat this process num_iter times. Finally, it selects the circle that had the most inliners.
"""
function RANSAC(X, num_iter, threshold)
    d = 0
    e = 0
    f = 0
    count = 0
    N,M = size(X)
    L = collect(1:N)
    for i = 1:num_iter
        L = randperm(N)
        AA=transpose(hcat(X[L[1],:], X[L[2],:], X[L[3],:]))
        d2,e2,f2 = fit_circle(AA)
        x, y, r = center(d2, e2, f2)
        distan = fit_dist(X, x,y,r)
        count1=0
        for j = 1:N
            if distan[j] < threshold && distan[j]>-threshold
                count1 = count1 +1
            end
        end
        if count1 > count
            d = d2
            e = e2
            f = f2
            count = count1
        end
    end
    x0, y0, r = center(d, e, f)
    return x0,y0,r
end
