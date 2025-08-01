module ExaPowerIO

using Artifacts

const PGLib_opf = joinpath(artifact"PGLib_opf","pglib-opf-23.07")

include("parser.jl")

"""
    function parse_pglib(
        ::Type{T<:Real},
        dataset_query :: String;
        out_type=PowerData{T}
    ) :: Union{PowerData{T}, NamedTuple} where T

Searches the [PGLib database](https://github.com/power-grid-lib/pglib-opf) for ```dataset_query```, and errors if there is not exactly 1 result.
Otherwise, the matching file is downloaded and parsed to return a value of type out_type.

Each value will be parsed as a ```T```.

Currently, out_type can only be ```ExaPowerIO.PowerData{T}```, or ```NamedTuple```.

```julia
parse_file(dataset_query; out_file) will return parse_file(Float64, dataset_query; out_file)
```
"""
function parse_pglib(
    ::Type{T},
    ::Type{V},
    dataset_query :: String;
    out_type=PowerData
) :: Union{NamedTuple, PowerData{T}} where {T<:Real, V<:AbstractVector}
    pglib_file = joinpath(PGLib_opf, dataset_query)
    if !isfile(pglib_file)
        throw(error("No matches found for pglib dataset: $dataset_query"))
    end
    parse_file(T, V, pglib_file; out_type)
end

convert(::Type{T}, data::PowerData) where T<:PowerData = data
convert(::Type{T}, data::PowerData) where T<:NamedTuple = struct_to_nt(data)

"""
    parse_file(
        fname :: String;
        out_type=PowerData{T}
    )

Parses the Matpower file specified by fname, and returns a value of type out_type.

Each value will be parsed as a ```T```.

Currently, out_type can only be ```ExaPowerIO.PowerData{T}```, or ```NamedTuple```.

```julia
parse_file(dataset_query; out_file) will return parse_file{Float64}(dataset_query; out_file)
```
"""
function parse_file(
    ::Type{T},
    ::Type{V},
    fname :: String;
    out_type=PowerData
) :: Union{NamedTuple, PowerData{T}} where {T<:Real, V<:AbstractVector}
    @info "Loading MATPOWER file at " * fname
    data = parse_matpower(T, V, fname)
    return convert(out_type, data)
end

export parse_file, parse_pglib, PowerData, BusData, GenData, BranchData, StorageData

end # module ExaPowerIO
