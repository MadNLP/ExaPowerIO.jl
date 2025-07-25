module ExaPowerIO

import PGLib

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
    out_type=PowerData{T}
) :: Union{PowerData{T}, NamedTuple} where {T<:Real, V<:AbstractVector}
    pglib_matches = PGLib.find_pglib_case(dataset_query)
    dataset = if length(pglib_matches) == 0
        throw(error("No matches found for pglib dataset: $dataset_query"))
    elseif length(pglib_matches) > 1
        throw(error("Ambiguity when specifying dataset $dataset_query. Possible matches: $pglib_matches"))
    else
        pglib_matches[1]
    end
    parse_file(T, V, joinpath(PGLib.PGLib_opf, dataset); out_type)
end

function parse_pglib(
    dataset_query :: String;
    out_type=PowerData{Float64}
) :: Union{PowerData{Float64}, NamedTuple}
    parse_pglib(Float64, Vector, dataset_query; out_type)
end

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
    out_type=PowerData{T}
) :: Union{PowerData{T}, NamedTuple} where {T<:Real, V<:AbstractVector}
    if !(out_type <: PowerData) && out_type != NamedTuple
        @error "Argument out_type must have value NamedTuple | ExaPowerIO.Data"
    end
    @info "Loading MATPOWER file at " * fname
    data = parse_matpower(T, V, fname)
    standardize_cost_terms!(data, 2)
    calc_thermal_limits!(data)
    return out_type <: PowerData ? data : struct_to_nt(data)
end

function parse_file(
    fname :: String;
    out_type=PowerData{Float64}
) :: Union{PowerData{Float64}, NamedTuple}
    parse_file(Float64, Vector, fname; out_type)
end

export parse_file, parse_pglib, PowerData, BusData, GenData, BranchData, StorageData

end # module ExaPowerIO
