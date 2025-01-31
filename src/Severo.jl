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

__precompile__()

module Severo

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 3
end

import SparseArrays: sparse, SparseMatrixCSC, SparseVector, SparseColumnView
import NamedArrays: NamedArray, NamedMatrix, NamedVector, names, dimnames

const CountMatrix{T} = SparseMatrixCSC{T, Int64} where {T <: Integer}
const NamedCountMatrix{T} = NamedArray{T} where {T <: Integer}

const DataMatrix{T} = SparseMatrixCSC{T, Int64} where {T <: Real}
const NamedDataMatrix{T} = NamedArray{T} where {T <: Real}

const NeighbourGraph{T} = NamedArray{T, 2, SparseMatrixCSC{T, Int64}} where {T <: Real}

const SparseVec = Union{SparseColumnView, SparseVector}

import Requires: @require
import Scratch: @get_scratch!

using Severo_jll
try
    include(joinpath(dirname(@__DIR__), "deps","deps.jl"))
catch e
    error("Severo.jl not properly configured, please run `Pkg.build(\"Severo\")`.")
end

include("macros.jl")
include("utils.jl")
include("input.jl")
include("filtering.jl")
include("normalize.jl")
include("scaling.jl")
include("variablefeatures.jl")
include("embedding.jl")
include("neighbours.jl")
include("clustering.jl")
include("datasets.jl")
include("diffexpr.jl")
include("printing.jl")
include("metrics.jl")

dataset_cache = ""

function __init__()
    global dataset_cache = @get_scratch!("datasets")
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" include("visualization.jl")
end

export CountMatrix, NamedCountMatrix, DataMatrix, NamedDataMatrix
export read_10X, read_10X_h5, read_h5, read_h5ad, write_h5ad, read_csv, read_geo, read_loom, read_data
export convert_counts, filter_counts, filter_features, filter_cells, dataset
export normalize_cells, scale_features, find_variable_features
export embedding, pca, umap, LinearEmbedding
export nearest_neighbours, shared_nearest_neighbours, jaccard_index
export cluster, prefilter_markers, find_markers, filter_rank_markers, find_all_markers
export purity, agreement, alignment
end # module
