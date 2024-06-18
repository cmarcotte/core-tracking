module dataParser
#=
	Incoming data is stored from fortran in binary files. We define the functions
	to read this data in the dataParser module
=#

export readFile!, filename

using FileIO, Printf

@inline function fastread!(io, x)
	unsafe_read(io, pointer(x), UInt(prod(size(x)))*sizeof(eltype(x)));
end

@inline function slowread!(io, x)
	read!(io, x);
end

function readFile!(x::Array{T,D}, fname::String, rfn = fastread!) where {T<:AbstractFloat, D}
	open(fname,"r") do io
	   read(io, Float32);
	   rfn(io, x)
	end
	return nothing
end

function readFile!(x::Array{T,D}, y::Array{T,D}, fname::String, rfn = fastread!) where {T<:AbstractFloat, D}
	open(fname,"r") do io
		read(io, Float32);
		rfn(io, x)
		rfn(io, y)
	end
	return nothing
end

function filename(baseDir::String, shape::NTuple{3,T}, t::T) where T<:Integer
	fname = @sprintf("%s/fenkar_%3d_%3d_%3d_%4d.dat",
										baseDir,
										shape...,
										t)
	if isfile(fname)
		return fname
	else
		return nothing
	end
end

function filename(baseDir::String, shape::NTuple{4,T}) where T<:Integer
	fname = @sprintf("%s/fenkar_%3d_%3d_%3d_%4d.dat",
										baseDir,
										shape...)
	if isfile(fname)
		return fname
	else
		return nothing
	end
end

end
