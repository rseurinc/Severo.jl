import SparseArrays: SparseMatrixCSC, SparseVector, SparseColumnView, SparseMatrixCSCView, nonzeros, nonzeroinds, nnz, nzrange

function mean_var(x::Union{SparseColumnView, SparseVector})
   n = length(x)

   count = n - nnz(x)
   mu = s = zero(eltype(x))

   # nonzeros
   for v in nonzeros(x)
     count += 1
     delta = (v - mu)
     mu += delta / count
     s += delta * (v - mu)
   end

   std = sqrt(s / (n-1))
   mu, std
end

function mean_var(A::SparseMatrixCSC)
  n,d = size(A)
  mu = zeros(d)
  std = zeros(d)

  for (i,a) in enumerate(eachcol(A))
    mu[i], std[i] = mean_var(a)
  end

  mu, std
end

function scale_center(A::SparseMatrixCSC)
  n,d = size(A)
  B = similar(A)

  mu = zeros(d)
  for (i,(a,b)) in enumerate(zip(eachcol(A), eachcol(B)))
    mu[i], std = mean_var(a)
    nonzeros(b) .= nonzeros(a) ./ std
    mu[i] /= std
  end
  B, mu
end

function log_norm(A::SparseMatrixCSC{T}; scale_factor=1.0) where {T <: Signed}
  B = similar(A, Float64)

  s = sum(A, dims=2)
  for (a,b) in zip(eachcol(A), eachcol(B))
    @inbounds for (i, idx) in enumerate(nonzeroinds(a))
      nonzeros(b)[i] = log1p(scale_factor * nonzeros(a)[i] / s[idx])
    end
#    nonzeros(b) .= log1p.(scale_factor * nonzeros(a) ./ s[nonzeroinds(a)])
  end

  B
end

function filter_data(A::SparseMatrixCSC{T}; min_cells=0, min_features=0) where {T <: Signed}
  features_per_cell = vec(sum(A .> 0, dims=2))
  CI = (features_per_cell .>= min_features)

  cells_per_feature = vec(sum(A .> 0, dims=1))
  FI = (cells_per_feature .>= min_cells)

  A[CI, FI]
end

function gram_matrix(A, mu, std)
  m,n = size(A)
  G = Matrix{eltype(A)}(A'A)
  #mul!(G, A', A) Converts to dense first?
  mul!(G, mu, mu', -m, 1.0)
  G ./= std
  G ./= std'
  G
end

