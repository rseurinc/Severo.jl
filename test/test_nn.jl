using Cell
using Test

using Distances
import Statistics: quantile

@testset "euclidian" begin
    X = rand(100, 10)

    metric = Euclidean()
    k = 4
    nn_index, distances = Cell.ann(X, k, metric)

    D = pairwise(metric, X, dims=1)
    j = map(1:size(X,1)) do i
        nn = partialsortperm(view(D,:,i), 1:k)
        x = length(intersect(Set(nn),Set(nn_index[i,:])))
        x / (k + (k - x))
    end

    @test quantile(j, .1) > .95
end

@testset "cosine" begin
    X = rand(100, 10)

    metric = CosineDist()
    k = 4
    nn_index, distances = Cell.ann(X, k, metric)

    D = pairwise(metric, X, dims=1)
    j = map(1:size(X,1)) do i
        nn = partialsortperm(view(D,:,i), 1:k)
        x = length(intersect(Set(nn),Set(nn_index[i,:])))
        x / (k + (k - x))
    end

    @test quantile(j, .1) > .95
end
