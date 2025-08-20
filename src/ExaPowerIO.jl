module ExaPowerIO

using LazyArtifacts

include("shared.jl")
include("parser.jl")
include("sc.jl")

"""
    function parse_matpower(
        ::Type{T},
        ::Type{V},
        path :: String;
        library=nothing,
    ) :: PowerData{T} where {T<:Real, V<:AbstractVector}
    parse_matpower(path; library=nothing)
    parse_matpower(::Type{T}, path; library=nothing) where {T<:Real}
    parse_matpower(::Type{V}, path; library=nothing) where {V<:Vector}

`library` can be one of the following values:
- `:nothing` indicates that the filesystem should be searched for `path`
- `:pglib` indicates that the [PGLib database](https://github.com/power-grid-lib/pglib-opf) should be searched for `path`
- `:matpower` indicates that the [MATPOWER database](https://github.com/MATPOWER/matpower) should be searched for `path`
"""
function parse_matpower(
    ::Type{T},
    ::Type{V},
    path :: String;
    library=nothing,
) :: PowerData{T} where {T<:Real, V<:AbstractVector}
    if library == :pglib
        path = joinpath(get_path(:pglib), path)
    elseif library == :matpower
        path = joinpath(get_path(:matpower), path)
    end
    isfile(path) || throw(error("Invalid file $path for library $library"))
    return parse_matpower_inner(T, V, path)
end

parse_matpower(path; library=nothing) = parse_matpower(Float64, Vector, path; library)
parse_matpower(::Type{T}, path; library=nothing) where {T<:Real} = parse_matpower(T, Vector, path; library)
parse_matpower(::Type{V}, path; library=nothing) where {V<:Vector} = parse_matpower(Float64, V, path; library)

function get_path(library::Symbol)
    library == :pglib && return joinpath(artifact"PGLib_opf", "pglib-opf-23.07")
    library == :matpower && return joinpath(artifact"MATPOWER_opf", "matpower-8.1/data")
    error("Invalid library passed to ExaPowerIO.get_path")
end

"""
    function parse_goc3(::Type{T}, path::String) where T<:Real :: NamedTuple
    parse_goc3(path::String) where T<:Real :: NamedTuple

"""
function parse_goc3(::Type{T}, path::String) :: NamedTuple where T<:Real
    @info path
    sc_string = read(open(path), String)
    sc = parse_sc_data(T, sc_string)
    uc_string = read(open("$path.pop_solution.json"), String)
    uc = parse_uc_data(T, uc_string)
    (uc=uc, sc=sc)
end

export parse_goc3, parse_matpower, PowerData, BusData, GenData, BranchData, ArcData, StorageData

end # module ExaPowerIO
