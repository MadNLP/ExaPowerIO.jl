using ExaPowerIO, Test, PowerModels, PGLib

CASES = [
    (Float64, "pglib_opf_case3_lmbd.m"),
    (Float64, "pglib_opf_case1803_snem.m"),
    (Float64, "pglib_opf_case118_ieee.m"),
    (Float64, "pglib_opf_case1888_rte.m"),
    (Float64, "pglib_opf_case13659_pegase.m"),
    (Float64, "pglib_opf_case1354_pegase.m"),
    (Float64, "pglib_opf_case10000_goc.m"),
    (Float64, "pglib_opf_case10192_epigrids.m"),
    (Float64, "pglib_opf_case10480_goc.m"),
    (Float64, "pglib_opf_case14_ieee.m"),
    (Float64, "pglib_opf_case162_ieee_dtc.m"),
    (Float64, "pglib_opf_case179_goc.m"),
    (Float64, "pglib_opf_case19402_goc.m"),
    (Float64, "pglib_opf_case1951_rte.m"),
    (Float64, "pglib_opf_case197_snem.m"),
    (Float64, "pglib_opf_case2000_goc.m"),
    (Float64, "pglib_opf_case200_activ.m"),
    (Float64, "pglib_opf_case20758_epigrids.m"),
    (Float64, "pglib_opf_case2312_goc.m"),
    (Float64, "pglib_opf_case2383wp_k.m"),
    (Float64, "pglib_opf_case240_pserc.m"),
    (Float64, "pglib_opf_case24464_goc.m"),
    (Float64, "pglib_opf_case24_ieee_rts.m"),
    (Float64, "pglib_opf_case2736sp_k.m"),
    (Float64, "pglib_opf_case2737sop_k.m"),
    (Float64, "pglib_opf_case2742_goc.m"),
    (Float64, "pglib_opf_case2746wop_k.m"),
    (Float64, "pglib_opf_case2746wp_k.m"),
    (Float64, "pglib_opf_case2848_rte.m"),
    (Float64, "pglib_opf_case2853_sdet.m"),
    (Float64, "pglib_opf_case2868_rte.m"),
    (Float64, "pglib_opf_case2869_pegase.m"),
    (Float64, "pglib_opf_case30000_goc.m"),
    (Float64, "pglib_opf_case300_ieee.m"),
    (Float64, "pglib_opf_case3012wp_k.m"),
    (Float64, "pglib_opf_case3022_goc.m"),
    (Float64, "pglib_opf_case30_as.m"),
    (Float64, "pglib_opf_case30_ieee.m"),
    (Float64, "pglib_opf_case3120sp_k.m"),
    (Float64, "pglib_opf_case3375wp_k.m"),
    (Float64, "pglib_opf_case3970_goc.m"),
    (Float64, "pglib_opf_case39_epri.m"),
    (Float64, "pglib_opf_case4020_goc.m"),
    (Float64, "pglib_opf_case4601_goc.m"),
    (Float64, "pglib_opf_case4619_goc.m"),
    (Float64, "pglib_opf_case4661_sdet.m"),
    (Float64, "pglib_opf_case4837_goc.m"),
    (Float64, "pglib_opf_case4917_goc.m"),
    (Float64, "pglib_opf_case500_goc.m"),
    (Float64, "pglib_opf_case5658_epigrids.m"),
    (Float64, "pglib_opf_case57_ieee.m"),
    (Float64, "pglib_opf_case588_sdet.m"),
    (Float64, "pglib_opf_case5_pjm.m"),
    (Float64, "pglib_opf_case60_c.m"),
    (Float64, "pglib_opf_case6468_rte.m"),
    (Float64, "pglib_opf_case6470_rte.m"),
    (Float64, "pglib_opf_case6495_rte.m"),
    (Float64, "pglib_opf_case6515_rte.m"),
    (Float64, "pglib_opf_case7336_epigrids.m"),
    (Float64, "pglib_opf_case73_ieee_rts.m"),
    (Float64, "pglib_opf_case78484_epigrids.m"),
    (Float64, "pglib_opf_case793_goc.m"),
    (Float64, "pglib_opf_case8387_pegase.m"),
    (Float64, "pglib_opf_case89_pegase.m"),
    (Float64, "pglib_opf_case9241_pegase.m"),
    (Float64, "pglib_opf_case9591_goc.m"),
]

PowerModels.silence()

@testset "ExaPowerIO parsing tests" begin
    datadir = "../data/"
    for (type, dataset) in CASES
        path = joinpath(PGLib.PGLib_opf, dataset)
        @info "Testing with repr: $type, dataset: $dataset"
        @info path
        pp_output = ExaPowerIO.parse_pglib(type, dataset; out_type=NamedTuple)
        pm_output = PowerModels.parse_file(path)
        PowerModels.standardize_cost_terms!(pm_output, order = 2)
        PowerModels.calc_thermal_limits!(pm_output)
        @test pm_output["source_version"] == pp_output.version
        @test isapprox(pm_output["baseMVA"], pp_output.baseMVA)
        # gs, bs
        pm_i = 0
        for (i, pp_bus) in enumerate(pp_output.bus)
            if pp_bus.pd == 0.0 && pp_bus.qd == 0.0
                continue
            end
            pm_i += 1
            pm_bus = pm_output["bus"][string(pp_bus.bus_i)]
            pm_load = pm_output["load"][string(pm_i)]
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
        @test pm_i == length(pm_output["load"])
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
            pp_tbus = pp_output.bus[pp_branch.tbus].bus_i
            pp_fbus = pp_output.bus[pp_branch.fbus].bus_i
            if pm_branch["f_bus"] == pp_tbus && pm_branch["t_bus"] == pp_fbus
                pp_branch = BranchData{type}(
                    pp_branch.tbus,
                    pp_branch.fbus,
                    pp_branch.br_r * pp_branch.tap^2,
                    pp_branch.br_x * pp_branch.tap^2,
                    pp_branch.b_to / pp_branch.tap^2,
                    pp_branch.b_fr * pp_branch.tap^2,
                    pp_branch.g_to / pp_branch.tap^2,
                    pp_branch.g_fr * pp_branch.tap^2,
                    pp_branch.ratea,
                    pp_branch.rateb,
                    pp_branch.ratec,
                    1 / pp_branch.tap,
                    -pp_branch.shift,
                    pp_branch.status,
                    -pp_branch.angmax,
                    -pp_branch.angmin,
                )
                pp_tbus = pp_output.bus[pp_branch.tbus].bus_i
                pp_fbus = pp_output.bus[pp_branch.fbus].bus_i
            end
            @test isapprox(pp_branch.ratea, pm_branch["rate_a"])
            @test isapprox(pp_branch.rateb, pm_branch["rate_b"])
            @test isapprox(pp_branch.ratec, pm_branch["rate_c"])
            @test isapprox(pp_branch.angmax, pm_branch["angmax"])
            @test isapprox(pp_branch.angmin, pm_branch["angmin"])
            @test isapprox(pp_branch.br_r, pm_branch["br_r"])
            @test isapprox(pp_branch.br_x, pm_branch["br_x"])
            @test isapprox(pp_branch.b_fr, pm_branch["b_fr"])
            @test isapprox(pp_branch.b_to, pm_branch["b_to"])
            @test isapprox(pp_branch.g_fr, pm_branch["g_fr"])
            @test isapprox(pp_branch.g_to, pm_branch["g_to"])
            @test isapprox(pp_branch.tap, pm_branch["tap"])
            @test isapprox(pp_branch.shift, pm_branch["shift"])

            @test pp_branch.status == pm_branch["br_status"]
            @test pp_tbus == pm_branch["t_bus"]
            @test pp_fbus == pm_branch["f_bus"]
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
        @test isbitstype(row_type)
    end
end
