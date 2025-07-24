module ExaPowerIO

import JLD2
import PGLib

include("parser.jl")

global SILENCED = false;

"""
    parse_pglib(
        ::Type{T},
        dataset_query :: String,
        datadir :: String;
        out_type=Data{T}
    )
Searches the [PGLib database](https://github.com/power-grid-lib/pglib-opf) for ```dataset_query```, and errors if there is not exactly 1 result.
Otherwise, the matching file is downloaded and parsed to return a value of type out_type.

Each value will be parsed as a ```::Type{T}```.

Currently, out_type can only be ```Data{T}```, or ```NamedTuple```.

The result will be cached to data_dir, which will be created if it does not exist.
"""
function parse_pglib(
    ::Type{T},
    dataset_query :: String;
    datadir=nothing,
    out_type=Data{T}
) :: Union{Data{T}, NamedTuple} where T <: Real
    pglib_matches = PGLib.find_pglib_case(dataset_query)
    dataset = if length(pglib_matches) == 0
        throw(error("No matches found for pglib dataset: $dataset_query"))
    elseif length(pglib_matches) > 1
        throw(error("Ambiguity when specifying dataset $dataset_query. Possible matches: $pglib_matches"))
    else
        pglib_matches[1]
    end
    parse_file(T, joinpath(PGLib.PGLib_opf, dataset); datadir, out_type)
end

"""
    parse_file(
        ::Type{T},
        fname :: String;
        datadir=nothing,
        out_type=Data{T}
    )
Parses the Matpower file specified by fname, and returns a value of type out_type.

Each value will be parsed as a ```::Type{T}```.

Currently, out_type can only be ```Data{T}```, or ```NamedTuple```.

The result will be cached to data_dir, which will be created if it does not exist.
"""
function parse_file(
    ::Type{T},
    fname :: String;
    datadir=nothing,
    out_type=Data{T}
) :: Union{Data{T}, NamedTuple} where T <: Real
    if out_type != Data && out_type != NamedTuple
        @error "Argument out_type must have value NamedTuple | ExaPowerIO.Data"
    end
    _, f = splitdir(fname)
    name, _ = splitext(f)
    cached_path = nothing
    struct_output = out_type <: Data
    if !isnothing(datadir)
        cached_path = joinpath(datadir, "$(name)_$T.jld2")
        if !isdir(datadir)
            mkdir(datadir)
        end
    end

    if !isnothing(cached_path) && isfile(cached_path)
        SILENCED || @info "Loading cached JLD2 file at " * cached_path
        data = JLD2.load(cached_path)["data"]
        return struct_output ? data : struct_to_nt(data)
    else
        SILENCED || @info "Loading MATPOWER file at " * fname
        data = process_ac_power_data(T, fname)
        if !isnothing(cached_path)
            SILENCED || @info "Caching parsed matpower file to " * cached_path
            JLD2.save(cached_path, "data", data)
        end
        return struct_output ? data : struct_to_nt(data)
    end
end

function silence()
    @info "ExaPowerIO.jl has been silenced for the rest of the session."
    global SILENCED = true
end

export parse_file, parse_pglib, struct_to_nt, Data, BusData, GenData, BranchData, StorageData

end # module ExaPowerIO
