module contours

#=
using MarchingCubes, GeometryBasics

#=
f(x,y,z) = [y + z, x+y+z, x-y+z]
#Define a cube  of side 14
xl = yl = zl = collect(Float64,range(-7.0, 7.0, length=150))
x = [xx for zz in zl, yy in yl, xx in xl]
y = [yy for zz in zl, yy in yl, xx in xl]
z = [zz for zz in zl, yy in yl, xx in xl];
fvals = [maximum([f(xx, yy, zz)[k] for k=1:3]) for zz in zl, yy in yl,  xx in xl]
#instantiate the structure MC (Marching Cube)
mc = MC(fvals, Int; x=xl, y=yl, z=zl)
m = march(mc, 0.0) #0.0 is the isovalue
msh = MarchingCubes.makemesh(GeometryBasics, mc)
=#

function generateLevelSet(u::Array{T,2}, lvl::T) where {T<:Real}
	tmp = Array{T,3}(undef, size(u)..., 2)
	@views tmp[:,:,1] .= u[:,:,1];
	@views tmp[:,:,2] .= u[:,:,1];
	tmp_set = generateLevelSet(tmp, lvl)
	
	
end

function generateLevelSet(u::Array{T,3}, lvl::T) where {T<:Real}

	mc = 	MC(u);
	march(mc, lvl);
	#=
	mc then contains mc.vertices and mc.triangles (indices to the mc.vertices)
	but this lacks closure information -- i.e., no explicit information about
	whether the triangle at index n is connected to triangle n+1 or n-1, thus
	it's very hard to determine which 
	=#
	
end
=#
using Makie
using Makie: Contours.contour
# using Makie for contours is suprisingly slow, and surprisingly dimension-specific
# I would prefer to use MarchingCubes, but the package is 3D specific and hard to
# parse the outputs in terms of continuous chains of vertices/tristrip in 2D/3D
# Actually, Makie.Contours.contour doesn't seem much slower in 2D...

export computeLevels

function computeLevels(u::Array{T,2}, lvl::T = zero(T)) where {T<:Real}
	sz = size(u)
	cs = Makie.Contours.contour(1:sz[1], 1:sz[2], u[:,:,1], lvl)
	return cs
end

function computeLevels(u::Array{T,3}, lvls::NTuple{2,T} = (zero(T), zero(T))) where T <: Number
	sz = size(u)
	if sz[3] != 2
		@warn "Input array `u` is size(u)=$size(u) -- (nx,ny,2) only!"
	else
		# compute the level sets
		cs0 = computeLevels(u[:,:,1], lvls[1])
		cs1 = computeLevels(u[:,:,2], lvls[2])
		return (cs0, cs1)
	end
end

end
