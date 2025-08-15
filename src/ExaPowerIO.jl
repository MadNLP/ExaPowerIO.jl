module ExaPowerIO

using LazyArtifacts

include("parser.jl")

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

T and V can be ommited and have default values `Float64`, and `Vector` respectively.

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
) :: Tuple{PowerData{T}, String} where {T<:Real, V<:AbstractVector}
    if library == :pglib
        PGLib_opf = joinpath(artifact"PGLib_opf", "pglib-opf-23.07")
        path = joinpath(PGLib_opf, path)
    elseif library == :matpower
        MATPOWER_opf = joinpath(artifact"MATPOWER_opf", "matpower-8.1/data")
        path = joinpath(MATPOWER_opf, path)
    end
    isfile(path) || throw(error("Invalid file $path for library $library"))
    return (parse_matpower_inner(T, V, path), path)
end

parse_matpower(path; library=nothing) = parse_matpower(Float64, Vector, path; library)
parse_matpower(::Type{T}, path; library=nothing) where {T<:Real} = parse_matpower(T, Vector, path; library)
parse_matpower(::Type{V}, path; library=nothing) where {V<:Vector} = parse_matpower(Float64, V, path; library)

export parse_matpower, PowerData, BusData, GenData, BranchData, ArcData, StorageData

end # module ExaPowerIO
