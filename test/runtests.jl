using ExaPowerIO, Test, PowerModels, PGLib

CASES = PGLib.find_pglib_case("")

PowerModels.silence()

@testset "ExaPowerIO parsing tests" begin
    datadir = "../data/"
    for dataset in CASES
        path = joinpath(PGLib.PGLib_opf, dataset)
        @info "Testing with dataset: $dataset"
        @info path
        ep_output = ExaPowerIO.parse_matpower(dataset; library=:pglib)
        pm_output = PowerModels.parse_file(path)
        PowerModels.standardize_cost_terms!(pm_output, order = 2)
        PowerModels.calc_thermal_limits!(pm_output)

        @test pm_output["source_version"] == ep_output.version
        @test isapprox(pm_output["baseMVA"], ep_output.baseMVA)
        # gs, bs
        pm_i = 0
        for (i, ep_bus) in enumerate(ep_output.bus)
            if ep_bus.pd == 0.0 && ep_bus.qd == 0.0
                continue
            end
            pm_i += 1
            pm_bus = pm_output["bus"][string(ep_bus.bus_i)]
            pm_load = pm_output["load"][string(pm_i)]
            @test isapprox(ep_bus.pd, pm_load["pd"])
            @test isapprox(ep_bus.qd, pm_load["qd"])
            @test isapprox(ep_bus.baseKV, pm_bus["base_kv"])
            @test isapprox(ep_bus.vm, pm_bus["vm"])
            @test isapprox(ep_bus.va, pm_bus["va"])

            @test ep_bus.type == pm_bus["bus_type"]
            @test ep_bus.bus_i == pm_bus["bus_i"]
            @test ep_bus.area == pm_bus["area"]
            @test ep_bus.zone == pm_bus["zone"]
        end
        @test pm_i == length(pm_output["load"])
        for (i, ep_gen) in enumerate(ep_output.gen)
            pm_gen = pm_output["gen"][string(i)]
            @test isapprox(ep_gen.pg, pm_gen["pg"])
            @test isapprox(ep_gen.qg, pm_gen["qg"])
            @test isapprox(ep_gen.qmax, pm_gen["qmax"])
            @test isapprox(ep_gen.qmin, pm_gen["qmin"])
            @test isapprox(ep_gen.vg, pm_gen["vg"])
            @test isapprox(ep_gen.mbase, pm_gen["mbase"])
            @test isapprox(ep_gen.pmax, pm_gen["pmax"])
            @test isapprox(ep_gen.pmin, pm_gen["pmin"])
            @test isapprox(ep_gen.startup, pm_gen["startup"])
            @test isapprox(ep_gen.shutdown, pm_gen["shutdown"])

            @test pm_gen["gen_status"] == ep_gen.status
            @test pm_gen["ncost"] == ep_gen.n
            @test all(isapprox(ep_c, pm_c) for (ep_c, pm_c) in zip(ep_gen.c, pm_gen["cost"]))
        end
        for (i, ep_branch) in enumerate(ep_output.branch)
            pm_branch = pm_output["branch"][string(i)]
            ep_tbus = ep_output.bus[ep_branch.t_bus].bus_i
            ep_fbus = ep_output.bus[ep_branch.f_bus].bus_i
            if pm_branch["f_bus"] == ep_tbus && pm_branch["t_bus"] == ep_fbus
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
                    ep_branch.t_idx,
                    ep_branch.f_idx
                )
                ep_tbus = ep_output.bus[ep_branch.t_bus].bus_i
                ep_fbus = ep_output.bus[ep_branch.f_bus].bus_i
            end
            @test isapprox(ep_branch.rate_a, pm_branch["rate_a"])
            @test isapprox(ep_branch.rate_b, pm_branch["rate_b"])
            @test isapprox(ep_branch.rate_c, pm_branch["rate_c"])
            @test isapprox(ep_branch.angmax, pm_branch["angmax"])
            @test isapprox(ep_branch.angmin, pm_branch["angmin"])
            @test isapprox(ep_branch.br_r, pm_branch["br_r"])
            @test isapprox(ep_branch.br_x, pm_branch["br_x"])
            @test isapprox(ep_branch.b_fr, pm_branch["b_fr"])
            @test isapprox(ep_branch.b_to, pm_branch["b_to"])
            @test isapprox(ep_branch.g_fr, pm_branch["g_fr"])
            @test isapprox(ep_branch.g_to, pm_branch["g_to"])
            @test isapprox(ep_branch.tap, pm_branch["tap"])
            @test isapprox(ep_branch.shift, pm_branch["shift"])

            @test ep_branch.status == pm_branch["br_status"]
            @test ep_fbus == pm_branch["f_bus"]
            @test ep_tbus == pm_branch["t_bus"]
        end
        for (i, ep_storage) in enumerate(ep_output.storage)
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
        @test isbitstype(row_type)
    end
end
