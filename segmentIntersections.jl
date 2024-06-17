module segmentIntersections
#=
	Let S0 = (p0 -> p1), and S1 = (q0 -> q1) be segments in R^D
	where p0::P{D,T}, p1::P{D,T}, q0::P{D,T}, q1::P{D,T} where {D, T<:Real}
	and P is an NTuple by default or wrapped to SVector.
	
	A = [	p1 - p0, 0, -I;
				0, q1 - q0, -I	]
	B = [ -p0;
				-q0	]
	X = A \ B = [t0, t1, p]
	
	A[1:D,1] 					.= p1.-p0
	A[(D+1):(2D),1] 	.= zero(T)
	A[1:D,2] 					.= zero(T)
	A[(D+1):(2D),2] 	.= q1.-q0
	A[3:(D+2),1:D] 		.= -I(D)
	A[3:(D+2),1:D] 		.= -I(D)
	B[1:D] 						.= -p0
	B[(D+1):(2D)] 		.= -q0
	
	ldiv!(X, lu!(A), B) works when D=2
	for D>2, we require forming the preconditioned problem first:
		(AT*A)*X = AT*B,
	which is really the original problem with slightly different sizes:
		S*X = B,
	where length(B) = 2+D, length(X) = 2+D
=#

export intersectionCache, createCache, fillCache!, checkSolution!, solveIntersection!

using StaticArrays, LinearAlgebra

@kwdef mutable struct intersectionCache{D1,D2,T} # D1,D2=2D,D+2
	A::MMatrix{D1,D2,T} 									= MMatrix{D1,D2,T}(undef)
	B::MVector{D1,T} 											= MVector{D1,T}(undef)
	X::MVector{D2,T} 											= MVector{D2,T}(undef)
	Aᵀ::Union{MMatrix{D2,D1,T},Nothing} 	= (D1==D2 ? nothing : MMatrix{D2,D1,T}(undef))
	S::Union{MMatrix{D2,D2,T},Nothing}		= (D1==D2 ? nothing : MMatrix{D2,D2,T}(undef))
end

function createCache(p0::NTuple{2,T}, p1::NTuple{2,T}, q0::NTuple{2,T}, q1::NTuple{2,T}) where {T<:Real}
	return intersectionCache{4,4,T}()
end

function createCache(p0::NTuple{D,T}, p1::NTuple{D,T}, q0::NTuple{D,T}, q1::NTuple{D,T}) where {D, T<:Real}
	return intersectionCache{2D,D+2,T}()
end

function fillCache!(cache::intersectionCache{4,4,T}, p0::NTuple{2,T}, p1::NTuple{2,T}, q0::NTuple{2,T}, q1::NTuple{2,T}) where {T<:Real}
	fillCache!(cache.A, cache.B, p0, p1, q0, q1)
	return nothing
end

function fillCache!(cache::intersectionCache{D1,D2,T}, p0::NTuple{D,T}, p1::NTuple{D,T}, q0::NTuple{D,T}, q1::NTuple{D,T}) where {D, D1, D2, T<:Real}
	fillCache!(cache.A, cache.B, cache.X, cache.Aᵀ, cache.S, p0, p1, q0, q1)
	return nothing
end

@inline function fillCache!(A, B, 
															p0::Union{NTuple{D,T}, SVector{D,T}}, 
															p1::Union{NTuple{D,T}, SVector{D,T}},
															q0::Union{NTuple{D,T}, SVector{D,T}},
															q1::Union{NTuple{D,T}, SVector{D,T}}) where {D, T<:Real}
	
	zT, mT = zero(T), -one(T)
	@inline Id(i,j)::T = (i!=j ? zT : mT)
	@inbounds for d in 1:D
		A[d,1] 							= p1[d]-p0[d]
		A[D+d,1] 						= zT
		A[d,2] 							= zT
		A[D+d,2] 						= q1[d]-q0[d]
	end
	@inbounds for i in 1:D, d in 1:D
		A[i,2+d] 						= Id(i,d)
		A[i+D,2+d] 					= Id(i,d)
	end
	@inbounds for d in 1:D
		B[d] 								= -p0[d]
		B[D+d] 							= -q0[d]
	end
	
	return nothing
end

function fillCache!(A, B, X, Aᵀ, S, 
															p0::Union{NTuple{D,T}, SVector{D,T}}, 
															p1::Union{NTuple{D,T}, SVector{D,T}},
															q0::Union{NTuple{D,T}, SVector{D,T}},
															q1::Union{NTuple{D,T}, SVector{D,T}}) where {D, T<:Real}
	fillCache!(A, B, p0, p1, q0, q1)	# size(A) = (2D,D+2), size(Aᵀ) = (D+2,2D), 
	transpose!(Aᵀ, A);
	mul!(X, Aᵀ, B);
	mul!(S, Aᵀ, A);
	return nothing
end

@inline function checkSolution!(X::MVector{D,T}) where {D,T<:Real}
	@inbounds begin
		if !(zero(T) <= X[1] && X[1] < one(T) && zero(T) <= X[2] && X[2] < one(T))
			fill!(X, T(NaN))
		end
	end
	return nothing
end

function solveIntersection!(cache::intersectionCache{4,4,T}) where {T<:Real}
	solveIntersection!(cache.X, cache.A, cache.B)
	return nothing
end

function solveIntersection!(cache::intersectionCache{D1,D2,T}) where {D1, D2, T<:Real}
	solveIntersection!(cache.X, cache.S)
	return nothing
end

function solveIntersection!(X::MVector{4,T}, A::MMatrix{4,4,T}, B::MVector{4,T}) where T <: Real
	#	Special-casing when D=2 since 2D==D+2
	try
		ldiv!(X, lu!(A), B)	# in-place LU decomposition of A, overwriting X
		checkSolution!(X)
	catch
		fill!(X, T(NaN))
	end
	return nothing
end	

function solveIntersection!(X::MVector{D,T}, S::MMatrix{D,D,T}) where {D,T <: Real}
	# When D ≠ 2: D+2 ≠ 2D
	ldiv!(lu!(S), X)	# in-place LU decomposition of A, overwriting X
	checkSolution!(X)
	return nothing
end	
	
end
