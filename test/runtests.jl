using PCDGroundRemoval
using Test

# Helper function to compare floating-point numbers with a tolerance
isapprox_tol(x, y, tol=1e-10) = isapprox(x, y; atol=tol, rtol=tol)

@testset verbose = true "All test" begin

    @testset "PCDGroundRemoval.jl" begin
        points = [0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3 3 3]
        points2 = [0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3.1 3.1 3]
        grid_18 = zeros(2,5,3)
        grid_18[:,:,1] = [0 1 1.5 0 0 ; 2 3 0 0 0]
        grid_18[:,:,2] = [0  1  1.5  0  0; 2  3  0  0  0]
        grid_18[:,:,3] = [0  1  1.5  0  0; 2  3  0 0  0]
        grid_1 = zeros(3,5,3)
        grid_1[:,:,1] = [1  1.5  0  0  0; 2  0  0  0  0; 3.1  0  0  0  0]
        grid_1[:,:,2] = [1  1.5  0  0  0; 2  0  0  0  0; 3.1  0  0  0  0]
        grid_1[:,:,3] = [1  1.5  0  0  0; 2  0  0  0  0; 3    0  0  0  0]
        @test make_pillar_grid(points; grid_box_size = 1.8) == grid_18
        @test make_pillar_grid(points2; grid_box_size = 1) == grid_1
        @test my_extremas([0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3 3 3], 1.8) == (2,2,0,0)
        @test my_extremas([0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3 3 3], 1) == (3,3,0,0)
        @test my_extremas([0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3.1 3.1 3], 1) == (4,4,0,0)
        @test my_extremas([0 0 0; 1 1 1; 2 2 2; 1.5 1.5 1.5; 3.1 3.1 3], 1.8) == (3,3,0,0)
    end

    @testset "pointsDeleting.jl" begin
        points = [1 1 0; 0 0 0; 0 0 0;;; 0 0 0; 0 0 0;0 0 0;;; 2 2 0; 3 3 0;0 0 0]
        points2 = [1 1 1; 0 0 0; 2 2 2]
        after_del = zeros(2,3,3)
        after_del[:,:,1] = [1  1  0; 0  0  0]
        after_del[:,:,2] = [0  0  0; 0  0  0]
        after_del[:,:,3] = [2  2  0; 3  3  0]
        after_del2 = [1 1 1; 2 2 2]
        @test delete_zero(points) == after_del
        @test delete_zero(points2) == after_del2

    end

    @testset "distance.jl" begin
        zero = [0,0,0]
        ones = [1, 1, 1]
        empty = Matrix{Float64}[]
        point = [2,0,0]

        cluster = [2 0 0; 1 1 0; 0 0 5]
        cluster2 = [3 3 1; 5 1 2]
        @test distance(zero,point) == 2
        @test distance(ones, cluster2) == [sqrt(8), sqrt(17)]
        @test distance(zero, cluster) == [2,sqrt(2),5]
        @test distance(cluster, cluster2) == sqrt(9)
        @test @calculate_distance([1, 1, 1], [1, 2, 3]) == 2.23606797749979
        @test isapprox_tol(@calculate_distance([1, 1, 1], [1 2 3; 2 3 4; 3 4 5]), [2.23606797749979, 3.7416573867739413, 5.385164807134504])
        @test isapprox_tol(@calculate_distance([1 1 1; 2 2 2; 3 3 3], [1 2 3; 2 3 4; 3 4 5]), 1.4142135623730951)

    end

    @testset "circleFitting.jl" begin
        # (x-3)^2 + (x-5)^2 = 22
        points = [3 5-sqrt(22); 3 5+sqrt(22); 3-sqrt(22) 5; 3+sqrt(22) 5]
        d, e, f = fit_circle(points)
        x0, y0, r = center(d,e,f)
        x,y,r_ransac = RANSAC(points, 100, 0.1)
        @test isapprox(d, -6; atol = 0.1)
        @test isapprox(e, -10; atol = 0.1)
        @test isapprox(f, 12; atol = 0.1)
        @test isapprox(x0, 3; atol = 0.1)
        @test isapprox(y0, 5; atol = 0.1)
        @test isapprox(r, sqrt(22); atol = 0.1)
        @test isapprox(x, 3; atol = 0.1)
        @test isapprox(y, 5; atol = 0.1)
        @test isapprox(r_ransac, sqrt(22); atol = 0.1)
    end

    @testset "xyzIO.jl" begin
        # this test is the only one that uses external data
        # it is therefore necessary to have the test file test.xyz downloaded in the root directory of the project, 
        # otherwise the test will not work
        points = [0.0 0.0 0.0;
        -5.4497723579 -5.3231377602 8.1485939026;
        -5.4518322945 -5.2601299286 8.1033678055;
        -5.4498615265 -5.1939916611 8.0530357361;
        -5.4393219948 -5.120569706 7.9910330772]
        save_xyz([0.1 2 3; 1 1 1], "save_test.xyz")
        @test read_xyz("test.xyz") == points
        @test read_xyz("save_test.xyz") == [0.1 2 3; 1 1 1]
        @test_throws LoadError read_xyz("asd.xyz")

    end

end