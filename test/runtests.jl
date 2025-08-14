using ExaPowerIO, Test, PowerModels, PGLib, Memento

mutable struct StorageHandler{F} <: Handler{F}
    records::Vector{String}
    StorageHandler{F}() where F = new{F}([])
end

Memento.log(handler::StorageHandler, record::Memento.Record) = push!(handler.records, record.msg)

@views function pglib_num_buses(s::String)
    s = s[length("pglib_opf_case")+1:end]
    s = s[1:findfirst(c -> !isdigit(c), s)-1]
    return parse(Int, s)
end
const CASES = sort!(PGLib.find_pglib_case(""); by=pglib_num_buses)
@info CASES

# this is copied from the old parser.jl
# power models filters out inactive branches
function parse_pm(filename, num_branch)
    data = PowerModels.parse_file(filename)
    PowerModels.standardize_cost_terms!(data, order = 2)
    PowerModels.calc_thermal_limits!(data)

    ref = PowerModels.build_ref(data)[:it][:pm][:nw][0]

    arc = Dict()
    for (i, b) in ref[:branch]
        merge!(arc, Dict(i => (;:bus => b["f_bus"], :rate_a => b["rate_a"],),
                                 (i+num_branch) => (;:bus => b["t_bus"], :rate_a => b["rate_a"],)))
    end

    data =  (
        version = ref[:source_version],
        baseMVA = ref[:baseMVA],
        bus = Dict(
            begin
                bus_loads = [ref[:load][l] for l in ref[:bus_loads][k]]
                bus_shunts = [ref[:shunt][s] for s in ref[:bus_shunts][k]]
                k => (;
                 :pd => sum(load["pd"] for load in bus_loads; init = 0.0),
                 :gs => sum(shunt["gs"] for shunt in bus_shunts; init = 0.0),
                 :qd => sum(load["qd"] for load in bus_loads; init = 0.0),
                 :bs => sum(shunt["bs"] for shunt in bus_shunts; init = 0.0),
                 :baseKV => v["base_kv"],
                 :type => v["bus_type"],
                 (Symbol(s) => v[s] for s in ["bus_i", "area", "vm", "va", "zone", "vmax", "vmin"])...,
                )
            end for (k, v) in ref[:bus]
        ),
        gen = Dict(
            k => (;
                :c => ntuple(i -> v["cost"][i], 3),
                :n => v["ncost"],
                :bus => v["gen_bus"],
                :model_poly => v["model"] == 2,
                :status => v["gen_status"],
                (Symbol(s) => v[s] for s in ["pg", "qg", "qmax", "qmin", "vg", "mbase", "pmax", "pmin", "startup", "shutdown"])...,
            ) for (k, v) in ref[:gen]
        ),
        arc = arc,
        branch = Dict(
            begin
                g, b = PowerModels.calc_branch_y(branch)
                tr, ti = PowerModels.calc_branch_t(branch)
                ttm = tr^2 + ti^2
                g_fr = branch["g_fr"]
                b_fr = branch["b_fr"]
                g_to = branch["g_to"]
                b_to = branch["b_to"]
                c1 = (-g * tr - b * ti) / ttm
                c2 = (-b * tr + g * ti) / ttm
                c3 = (-g * tr + b * ti) / ttm
                c4 = (-b * tr - g * ti) / ttm
                c5 = (g + g_fr) / ttm
                c6 = (b + b_fr) / ttm
                c7 = (g + g_to)
                c8 = (b + b_to)
                i => (;
                    :j => 1,
                    :f_idx => i,
                    :t_idx => i + num_branch,
                    :f_bus => branch["f_bus"],
                    :t_bus => branch["t_bus"],
                    :c1 => c1,
                    :c2 => c2,
                    :c3 => c3,
                    :c4 => c4,
                    :c5 => c5,
                    :c6 => c6,
                    :c7 => c7,
                    :c8 => c8,
                    :status => branch["br_status"],
                    (Symbol(s) => branch[s] for s in ["br_r", "br_x","b_fr", "b_to", "g_fr", "g_to", "rate_a", "rate_b", "rate_c", "tap", "shift", "angmin", "angmax"])...,
                )
            end for (i, branch) in ref[:branch]
        ),
        storage = isempty(ref[:storage]) ?  empty_data = Dict{Int, NamedTuple{(:i,), Tuple{Int64}}}() : Dict(
            begin
                i => (;:c => i,
                :bus => stor["storage_bus"],
                (Symbol(s) = stor[s] for s in ["energy", "energy_rating", "charge_rating", "discharge_rating", "discharge_efficiency", "thermal_rating", "charge_efficiency", "qmix", "qmax", "r", "x", "p_loss", "q_loss", "ps", "qs"])...,
               )
            end for (i, stor) in ref[:storage]
        ),
    )

    return data
end

function compare_fields(lhs::L, rhs::R, fields) where {L,R}
    for field in fields
        if !isapprox(getfield(lhs, field), getfield(rhs, field))
            @info field
            @info lhs
            @info rhs
        end
        @test isapprox(getfield(lhs, field), getfield(rhs, field))
    end
end

@testset "ExaPowerIO parsing tests" begin
    root_logger = getlogger("")
    handler = StorageHandler{DefaultFormatter}()
    root_logger.handlers = Dict("storage_logger" => handler)

    datadir = "../data/"
    for dataset in CASES
        handler.records = []
        path = joinpath(PGLib.PGLib_opf, dataset)
        @info "Testing with dataset: $dataset"
        @info path
        ep_output = ExaPowerIO.parse_matpower(dataset; library=:pglib)
        pm_output = parse_pm(path, length(ep_output.branch))

        # when the reference bus gets changed, and there is a tie in pmax, the new ref is unknown
        if any(map(r -> occursin("as reference based on generator", r), handler.records))
            @info "Skipping case $dataset due to changed reference bus"
            continue
        end

        @test pm_output.version == ep_output.version
        @test isapprox(pm_output.baseMVA, ep_output.baseMVA)
        for (i, ep_bus) in enumerate(ep_output.bus)
            ep_bus.type == 4 && continue
            pm_bus = pm_output.bus[ep_bus.bus_i]
            compare_fields(ep_bus, pm_bus, fieldnames(ExaPowerIO.BusData))
        end
        for (i, ep_gen) in enumerate(ep_output.gen)
            ep_gen.status == 0 && continue
            pm_gen = pm_output.gen[i]
            compare_fields(ep_gen, pm_gen, [
                :pg,
                :qg,
                :qmax,
                :qmin,
                :vg,
                :mbase,
                :status,
                :pmax,
                :pmin,
                :model_poly,
                :startup,
                :shutdown,
                :n,
                :c
            ])
            @test ep_output.bus[ep_gen.bus].bus_i == pm_gen.bus
        end
        for (i, ep_branch) in enumerate(ep_output.branch)
            ep_branch.status == 0 && continue
            pm_branch = pm_output.branch[i]
            ep_tbus = ep_output.bus[ep_branch.t_bus].bus_i
            ep_fbus = ep_output.bus[ep_branch.f_bus].bus_i
            if pm_branch.f_bus == ep_tbus && pm_branch.t_bus == ep_fbus
                ep_branch = BranchData{Float64}(
                    ep_branch.t_bus,
                    ep_branch.f_bus,
                    ep_branch.br_r * ep_branch.tap^2,
                    ep_branch.br_x * ep_branch.tap^2,
                    ep_branch.b_to / ep_branch.tap^2,
                    ep_branch.b_fr * ep_branch.tap^2,
                    ep_branch.g_to / ep_branch.tap^2,
                    ep_branch.g_fr * ep_branch.tap^2,
                    ep_branch.rate_a,
                    ep_branch.rate_b,
                    ep_branch.rate_c,
                    1 / ep_branch.tap,
                    -ep_branch.shift,
                    ep_branch.status,
                    -ep_branch.angmax,
                    -ep_branch.angmin,
                    # we arent using pm arc calculations so no need to flip
                    ep_branch.f_idx,
                    ep_branch.t_idx
                )
                ep_output.arc[i], ep_output.arc[i+length(ep_output.branch)] = ep_output.arc[i+length(ep_output.branch)], ep_output.arc[i]
                ep_tbus = ep_output.bus[ep_branch.t_bus].bus_i
                ep_fbus = ep_output.bus[ep_branch.f_bus].bus_i
            end
            compare_fields(ep_branch, pm_branch, [
                :br_r,
                :br_x,
                :b_fr,
                :b_to,
                :g_fr,
                :g_to,
                :rate_a,
                :rate_b,
                :rate_c,
                :tap,
                :shift,
                :status,
                :angmin,
                :angmax,
                :f_idx,
                :t_idx,
                :c1,
                :c2,
                :c3,
                :c4,
                :c5,
                :c6,
                :c7,
                :c8,
            ])
            @test ep_fbus == pm_branch.f_bus
            @test ep_tbus == pm_branch.t_bus
        end
        for (i, ep_arc) in enumerate(ep_output.arc)
            # powermodels skips inactive branches
            haskey(pm_output.arc, i) || continue
            pm_arc = pm_output.arc[i]
            compare_fields(ep_arc, pm_arc, [:rate_a])
            @test ep_output.bus[ep_arc.bus].bus_i == pm_arc.bus
        end
        for (i, ep_storage) in enumerate(ep_output.storage)
            pm_storage = pm_output.storage[i]
            compare_fields(ep_storage, pm_storage, fieldnames(ExaPowerIO.StorageData))
        end
    end
end

ROW_TYPES = [
    BusData{Float64},
    GenData{Float64},
    BranchData{Float64},
    StorageData{Float64},
]

@testset "ExaPowerIO isbits tests" begin
    for row_type in ROW_TYPES
        @test isbitstype(row_type)
    end
end
