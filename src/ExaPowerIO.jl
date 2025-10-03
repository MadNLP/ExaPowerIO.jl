module ExaPowerIO

using LazyArtifacts

include("parser.jl")

"""
    function parse_matpower(
        ::Type{T},
        ::Type{V},
        path :: String;
        library=nothing,
        filtered=true,
    ) :: PowerData{T} where {T<:Real, V<:AbstractVector}
    parse_matpower(path; library=nothing, filtered=true)
    parse_matpower(::Type{T}, path; library=nothing, filtered=true) where {T<:Real}
    parse_matpower(::Type{V}, path; library=nothing, filtered=true) where {V<:Vector}

T and V can be ommited and have default values `Float64`, and `Vector` respectively.

`library` can be one of the following values:
- `nothing` indicates that the filesystem should be searched for `path`
- `:pglib` indicates that the [PGLib database](https://github.com/power-grid-lib/pglib-opf) should be searched for `path`

Setting `filtered` to true will remove inactive generators / branches, and isolated branches.
"""
function parse_matpower(
    ::Type{T},
    ::Type{V},
    path :: String;
    library=nothing,
    filtered=true,
) :: PowerData{T} where {T<:Real, V<:AbstractVector}
    if library == :pglib
        PGLib_opf = joinpath(artifact"PGLib_opf", "pglib-opf-23.07")
        path = joinpath(PGLib_opf, path)
    end
    isfile(path) || throw(error("Invalid file $path for library $library"))
    return parse_matpower_inner(T, V, path, filtered)
end

parse_matpower(path; library=nothing, filtered=true) = parse_matpower(Float64, Vector, path; library, filtered)
parse_matpower(::Type{T}, path; library=nothing, filtered=true) where {T<:Real} = parse_matpower(T, Vector, path; library, filtered)
parse_matpower(::Type{V}, path; library=nothing, filtered=true) where {V<:Vector} = parse_matpower(Float64, V, path; library, filtered)

function get_path(library::Symbol)
    library == :pglib && return joinpath(artifact"PGLib_opf", "pglib-opf-23.07")
    error("Invalid library passed to ExaPowerIO.get_path")
end

export parse_matpower, PowerData, BusData, GenData, BranchData, ArcData, StorageData

end # module ExaPowerIO
