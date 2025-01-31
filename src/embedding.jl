# Severo: a software package for analysis and exploration of single-cell RNA-seq datasets.
# Copyright (c) 2021 imec vzw.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version, and Additional Terms
# (see below).

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.

import Arpack: svds, eigs
import LinearAlgebra: svd, Diagonal, Hermitian
import UMAP

struct LinearEmbedding
    parent::Union{NamedMatrix, NamedCenteredMatrix}
    coordinates::NamedMatrix
    stdev::NamedVector
    basis::NamedMatrix
end

include("irlba.jl")
include("mul.jl")

function tssvd(A::AbstractMatrix{T}; nsv::Int=6, ritzvec::Bool=true, tol::Float64=0.0, maxiter::Int=1000, ncv::Int=2*nsv) where {T}
    C = Hermitian(A'A)

    # XXX should sqrt the tolerance probably
    λ, ϕ = eigs(C, nev=nsv, ritzvec=ritzvec, tol=tol, maxiter=maxiter, ncv=ncv)
    Sigma = sqrt.(λ)

    U = if ritzvec
        A * ϕ * inv(Diagonal(Sigma))
    else
        Matrix{T}(undef, size(A,1), 0)
    end

    SVD(U, Sigma, ϕ')
end

function _pca(X, npcs::Int64; algorithm=:arpack, kw...)
    m,n = size(X)
    npcs = min(min(m,n), npcs)

    if (npcs > 0.5 * min(m, n)) && (algorithm == :arpack || algorithm == :irlba)
        @warn "Computing too large a percentage of principal components, using standard svd instead"
        algorithm = :svd
    end

    S = if algorithm == :arpack
        S, nconv, niter, nmult, resid = svds(X; nsv=npcs, kw...)
        S
    elseif algorithm == :tssvd
        tssvd(X; nsv=npcs, kw...)
    elseif algorithm == :irlba
        irlba(X, npcs; kw...)
    else
        Q = convert(Matrix, X)
        svd(Q; kw...)
    end

    Z = view(S.U, :, 1:npcs) * Diagonal(view(S.S, 1:npcs))
    stdev = view(S.S, 1:npcs) ./ sqrt(max(1, size(X,1) - 1))
    loadings = if npcs != size(S.V, 2)
        view(S.V, :, 1:npcs)
    else
        S.V
    end

    Z, stdev, loadings
end

_pca(X::NamedMatrix, npcs::Int64; kw...) = _pca(X.array, npcs; kw...)
_pca(X::NamedCenteredMatrix, npcs::Int64; kw...) = _pca(CenteredMatrix(X.A.array, X.mu.array), npcs; kw...)

function pca(X::Union{NamedMatrix, NamedCenteredMatrix}, npcs::Int64; kw...)
    Z, stdev, loadings = _pca(X, npcs; kw...)

    k = length(stdev)
    latentnames = map(x -> string("PC-", x), 1:k)

    rownames, colnames = names(X)
    rowdim, coldim = dimnames(X)

    coordinates = NamedArray(Z, (rownames, latentnames), (rowdim, :latent))
    stdev = NamedArray(stdev, (latentnames,), (:latent,))
    basis = NamedArray(loadings, (colnames, latentnames), (rowdim, :latent))
    LinearEmbedding(X, coordinates, stdev, basis)
end

function UMAP.knn_search(X::AbstractMatrix, k, ::Val{:ann})
    knns, dists = ann(default_rng(), X', k, CosineDist(), false, size(X,1))
    knns', dists'
end

_umap(X::AbstractMatrix, ncomponents::Int64, ::Colon; kw...) = _umap(X, ncomponents; kw...)
_umap(X::AbstractMatrix, ncomponents::Int64, dims; kw...) = _umap(view(X, :, dims), ncomponents; kw...)

function _umap(X::AbstractMatrix, ncomponents::Int64=2; metric=:cosine, nneighbours::Integer=30, min_dist::Real=0.3, nepochs::Union{Nothing,Integer}=nothing, kw...)
    metric = if metric == :cosine
        UMAP.CosineDist()
    elseif metric == :euclidian
        UMAP.Euclidian()
    else
        metric
    end

    n_epochs = if nepochs === nothing
        (size(X,1) <= 10000) ? 500 : 200
    else
        nepochs
    end

    UMAP.umap(X', ncomponents; metric=metric, n_neighbors=nneighbours, min_dist=min_dist, n_epochs=n_epochs, kw...)'
end

"""
    umap(X::AbstractMatrix, ncomponents::Int64=2; dims=:, metric=:cosine, nneighbours::Int=30, min_dist::Real=.3, nepochs::Int=300, kw...) where T

Performs a Uniform Manifold Approximation and Projection (UMAP) dimensional reduction on the coordinates in the linear embedding.

For a more in depth discussion of the mathematics underlying UMAP, see the ArXiv paper: [https://arxiv.org/abs/1802.03426]

**Arguments**:

    - `X`: an unlabelled matrix with coordinates for each cell
    - `ncomponents`: the dimensionality of the embedding
    - `dims`: which dimensions to use
    - `metric`: distance metric to use
    - `nneighbours`: the number of neighboring points used in local approximations of manifold structure.
    - `min_dist`: controls how tightly the embedding is allowed compress points together.
    - `nepochs`: number of training epochs to be used while optimizing the low dimensional embedding
    - `kw`: additional parameters for the umap algorithm. See [`UMAP.umap`](@ref)

**Return values**:

A low-dimensional embedding of the cells
"""
umap(X::AbstractMatrix, ncomponents::Int64; dims=:, kw...) = _umap(X, ncomponents, dims; kw...)

"""
    umap(em::LinearEmbedding, ncomponents::Int64=2; dims=:, metric=:cosine, nneighbours::Int=30, min_dist::Real=.3, nepochs::Int=300, kw...) where T

Performs a Uniform Manifold Approximation and Projection (UMAP) dimensional reduction on the coordinates in the linear embedding.

For a more in depth discussion of the mathematics underlying UMAP, see the ArXiv paper: [https://arxiv.org/abs/1802.03426]

**Arguments**:

    - `em`: embedding containing the transformed coordinates for each cell
    - `ncomponents`: the dimensionality of the embedding
    - `dims`: which dimensions to use
    - `metric`: distance metric to use
    - `nneighbours`: the number of neighboring points used in local approximations of manifold structure.
    - `min_dist`: controls how tightly the embedding is allowed compress points together.
    - `nepochs`: number of training epochs to be used while optimizing the low dimensional embedding
    - `kw`: additional parameters for the umap algorithm. See [`UMAP.umap`](@ref)

**Return values**:

A low-dimensional embedding of the cells
"""
umap(em::LinearEmbedding, ncomponents::Int64=2,; dims=:, kw...) = umap(em.coordinates, ncomponents; dims=dims, kw...)

"""
    umap(X::NamedMatrix, ncomponents::Int64=2; dims=:, metric=:cosine, nneighbours::Int=30, min_dist::Real=.3, nepochs::Int=300, kw...) where T

Performs a Uniform Manifold Approximation and Projection (UMAP) dimensional reduction on the coordinates.

For a more in depth discussion of the mathematics underlying UMAP, see the ArXiv paper: [https://arxiv.org/abs/1802.03426]

**Arguments**:

    - `X`: a labelled matrix with coordinates for each cell
    - `ncomponents`: the dimensionality of the embedding
    - `dims`: which dimensions to use
    - `metric`: distance metric to use
    - `nneighbours`: the number of neighboring points used in local approximations of manifold structure.
    - `min_dist`: controls how tightly the embedding is allowed compress points together.
    - `nepochs`: number of training epochs to be used while optimizing the low dimensional embedding
    - `kw`: additional parameters for the umap algorithm. See [`UMAP.umap`](@ref)

**Return values**:

A low-dimensional embedding of the cells
"""
function umap(X::NamedMatrix, ncomponents::Int64=2; dims=:, kw...)
    coords = umap(X.array, ncomponents; dims=dims, kw...)

    rownames = names(X, 1)
    rowdim = dimnames(X, 1)
    latentnames = map(x -> string("UMAP-", x), 1:ncomponents)
    NamedArray(coords, (rownames, latentnames), (rowdim, :latent))
end

@partial function embedding(X, ncomponents::Int64=50; method=:pca, kw...)
    if isa(method, AbstractString)
        method = Symbol(method)
    end

    if method == :pca
        pca(X, ncomponents; kw...)
    elseif method == :umap
        umap(X, ncomponents; kw...)
    else
        error("unknown reduction method: $method")
    end
end
