using Cell, Test

@testset "ranksum" begin
    statistics = [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30, 0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
    labels = BitArray([1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    pval = 0.13291945818531886
    @test Cell.ranksumtest(statistics, labels) ≈ pval
end
