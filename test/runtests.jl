using ExaPowerIO, Test, PowerModels

PowerModels.silence()
ExaPowerIO.silence()

CASES = [
    (Float16, "pglib_opf_case3_lmbd.m", false),
    (Float32, "pglib_opf_case3_lmbd.m", false),
    (Float64, "pglib_opf_case3_lmbd.m", false)
]

@testset "ExaPowerIO parsing tests" begin
    datadir = "../data/"
    for (type, dataset, is_custom) in CASES
        pp_output = if is_custom
            ExaPowerIO.parse_file(type, dataset; datadir, out_type=NamedTuple)
        else
            ExaPowerIO.parse_pglib(type, dataset, datadir; out_type=NamedTuple)
        end
        path = joinpath("../data/", dataset)
        pm_output = PowerModels.parse_file(path)
        PowerModels.standardize_cost_terms!(pm_output, order = 2)
        PowerModels.calc_thermal_limits!(pm_output)
        @test pm_output["source_version"] == pp_output.version
        @test isapprox(pm_output["baseMVA"], pp_output.baseMVA)
        # gs, bs
        for (i, pp_bus) in enumerate(pp_output.bus)
            pm_bus = pm_output["bus"][string(i)]
            pm_load = pm_output["load"][string(i)]
            @test isapprox(pp_bus.pd, pm_load["pd"])
            @test isapprox(pp_bus.qd, pm_load["qd"])
            @test isapprox(pp_bus.baseKV, pm_bus["base_kv"])
            @test isapprox(pp_bus.vm, pm_bus["vm"])
            @test isapprox(pp_bus.va, pm_bus["va"])

            @test pp_bus.type == pm_bus["bus_type"]
            @test pp_bus.bus_i == pm_bus["bus_i"]
            @test pp_bus.area == pm_bus["area"]
            @test pp_bus.zone == pm_bus["zone"]
        end
        for (i, pp_gen) in enumerate(pp_output.gen)
            pm_gen = pm_output["gen"][string(i)]
            @test isapprox(pp_gen.pg, pm_gen["pg"])
            @test isapprox(pp_gen.qg, pm_gen["qg"])
            @test isapprox(pp_gen.qmax, pm_gen["qmax"])
            @test isapprox(pp_gen.qmin, pm_gen["qmin"])
            @test isapprox(pp_gen.vg, pm_gen["vg"])
            @test isapprox(pp_gen.mbase, pm_gen["mbase"])
            @test isapprox(pp_gen.pmax, pm_gen["pmax"])
            @test isapprox(pp_gen.pmin, pm_gen["pmin"])
            @test isapprox(pp_gen.startup, pm_gen["startup"])
            @test isapprox(pp_gen.shutdown, pm_gen["shutdown"])

            @test pm_gen["gen_status"] == pp_gen.status
            @test pm_gen["ncost"] == pp_gen.n
            @test all(isapprox(pp_c, pm_c) for (pp_c, pm_c) in zip(pp_gen.c, pm_gen["cost"]))
        end
        for (i, pp_branch) in enumerate(pp_output.branch)
            pm_branch = pm_output["branch"][string(i)]
            @test isapprox(pp_branch.ratea, pm_branch["rate_a"])
            @test isapprox(pp_branch.rateb, pm_branch["rate_b"])
            @test isapprox(pp_branch.ratec, pm_branch["rate_c"])
            @test isapprox(pp_branch.angmax, pm_branch["angmax"])
            @test isapprox(pp_branch.angmin, pm_branch["angmin"])
            @test isapprox(pp_branch.r, pm_branch["br_r"])
            @test isapprox(pp_branch.x, pm_branch["br_x"])
            @test isapprox(pp_branch.b, pm_branch["b_to"] + pm_branch["b_fr"])

            @test pp_branch.status == pm_branch["br_status"]
            @test pp_branch.tbus == pm_branch["t_bus"]
            @test pp_branch.fbus == pm_branch["f_bus"]
        end
        for (i, pp_storage) in enumerate(pp_output.storage)
            pm_storage = pm_output["storage"][string(i)]
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
        @assert(isbitstype(row_type), string(row_type) * " is not bits")
    end
end
