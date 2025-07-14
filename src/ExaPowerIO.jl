module ExaPowerIO

import JLD2
import PGLib

include("parser.jl")

global SILENCED = false;

function parse_pglib(
    ::Type{T},
    dataset_query :: String,
    datadir :: String;
    out_type=Data{T}
) :: Union{Data{T}, NamedTuple} where T <: Real
    mkpath(datadir)
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
    named_tuple = out_type != Data{T}
    if isnothing(datadir)
        cached_path = joinpath(datadir, name * "_ " * string(T) * ".jld2")
    elseif !isdir(datadir)
        mkdir(datadir)
    end

    if !isnothing(cached_path) && isfile(cached_path)
        SILENCED || @info "Loading cached JLD2 file at " * cached_path
        data = JLD2.load(cached_path)["data"]
        return named_tuple ? struct_to_nt(data) : data
    else
        SILENCED || @info "Loading MATPOWER file at " * fname
        data = process_ac_power_data(T, fname)
        if !isnothing(cached_path)
            SILENCED || @info "Caching parsed matpower file to " * cached_path
            JLD2.save(cached_path, "data", data)
        end
        return named_tuple ? struct_to_nt(data) : data
    end
end

function silence()
    @info "ExaPowerIO.jl has been silenced for the rest of the session."
    global SILENCED = true
end

export parse_file, parse_pglib, Data, BusData, BranchData, StorageData, GenData

end # module ExaPowerIO
