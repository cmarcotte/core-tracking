module pairIterator

export PairIterator

# pair iterator
struct PairIterator{T}
    it::Vector{T}
end

# Required method
function Base.iterate(p::PairIterator, i::Int=1)
    @inline
    Base.@_nothrow_meta 
    return (1 <= i < length(p.it)) ? ((p.it[i], p.it[i+1]), i + 1) : nothing
end

# Important optional methods
Base.eltype(::Type{PairIterator{T}}) where {T} = Tuple{T,T}
Base.length(p::PairIterator) = length(p.it)-1

end
