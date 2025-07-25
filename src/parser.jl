# FOR CONVENIENCE, the MATPOWER file spec
# https://matpower.app/manual/matpower/DataFileFormat.html

"""
    struct BusData{T <: Real}
        bus_i :: Int
        type :: Int
        pd :: T
        qd :: T
        gs :: T
        bs :: T
        area :: Int
        vm :: T
        va :: T
        baseKV :: T
        zone :: Int
        vmax :: T
        vmin :: T
    end
"""
struct BusData{T <: Real}
    bus_i :: Int
    type :: Int
    pd :: T
    qd :: T
    gs :: T
    bs :: T
    area :: Int
    vm :: T
    va :: T
    baseKV :: T
    zone :: Int
    vmax :: T
    vmin :: T
end
"""
    struct BranchData{T <: Real}
        fbus :: Int
        tbus :: Int
        br_r :: T
        br_x :: T
        b_fr :: T,
        b_to :: T,
        g_fr :: T,
        g_to :: T,
        ratea ::T
        rateb :: T
        ratec :: T
        tap :: T
        shift :: T
        status :: Int
        angmin :: T
        angmax :: T
        c1 :: T
        c2 :: T
        c3 :: T
        c4 :: T
        c5 :: T
        c6 :: T
        c7 :: T
        c8 :: T
    end

fbus and tbus are indices into the PowerData.bus Vector, not bus_i values
"""
struct BranchData{T <: Real}
    fbus :: Int
    tbus :: Int
    br_r :: T
    br_x :: T
    b_fr :: T
    b_to :: T
    g_fr :: T
    g_to :: T
    ratea ::T
    rateb :: T
    ratec :: T
    tap :: T
    shift :: T
    status :: Int
    angmin :: T
    angmax :: T
    c1 :: T
    c2 :: T
    c3 :: T
    c4 :: T
    c5 :: T
    c6 :: T
    c7 :: T
    c8 :: T
    function BranchData{T}(
        fbus::Int,
        tbus::Int,
        br_r::T,
        br_x::T,
        b_fr::T,
        b_to::T,
        g_fr::T,
        g_to::T,
        ratea::T,
        rateb::T,
        ratec::T,
        tap::T,
        shift::T,
        status::Int,
        angmin::T,
        angmax::T,
    ) where {T<:Real}
        x = br_r + im * br_x
        xi = inv(x)
        y = ifelse(isfinite(xi), xi, zero(xi))
        g = real(y)
        b = imag(y)
        if isapprox(tap, T(0.0))
            tap = T(1.0)
        end
        tr = tap * cos(shift)
        ti = tap * sin(shift)
        ttm = tr^2 + ti^2
        c1 = (-g * tr - b * ti) / ttm
        c2 = (-b * tr + g * ti) / ttm
        c3 = (-g * tr + b * ti) / ttm
        c4 = (-b * tr - g * ti) / ttm
        c5 = (g + g_fr) / ttm
        c6 = (b + b_fr) / ttm
        c7 = (g + g_to)
        c8 = (b + b_to)
        new{T}(
            fbus,
            tbus,
            br_r,
            br_x,
            b_fr,
            b_to,
            g_fr,
            g_to,
            ratea,
            rateb,
            ratec,
            tap,
            shift,
            status,
            angmin,
            angmax,
            c1,
            c2,
            c3,
            c4,
            c5,
            c6,
            c7,
            c8,
        )
    end
end

"""
    struct StorageData{T <: Real}
        storage_bus :: T
        ps :: Int
        qs :: T
        energy :: T
        energy_rating :: T
        charge_rating :: T
        discharge_rating :: T
        charge_efficiency :: T
        discharge_efficiency :: T
        thermal_rating :: T
        qmin :: T
        qmax :: T
        r :: T
        x :: T
        p_loss :: T
        q_loss :: T
        status :: Int
    end
"""
struct StorageData{T <: Real}
    storage_bus :: T
    ps :: Int
    qs :: T
    energy :: T
    energy_rating :: T
    charge_rating :: T
    discharge_rating :: T
    charge_efficiency :: T
    discharge_efficiency :: T
    thermal_rating :: T
    qmin :: T
    qmax :: T
    r :: T
    x :: T
    p_loss :: T
    q_loss :: T
    status :: Int
end
"""
    struct GenData{T <: Real}
        bus :: Int
        pg :: T
        qg :: T
        qmax :: T
        qmin :: T
        vg :: T
        mbase :: T
        status :: Int
        pmax :: T
        pmin :: T
        i :: Int
        model_poly :: Bool
        startup :: T
        shutdown :: T
        n :: Int
        c :: NTuple{3, T}
    end

bus is an index into the PowerData.bus Vector, not bus_i values
"""
struct GenData{T <: Real}
    bus :: Int
    pg :: T
    qg :: T
    qmax :: T
    qmin :: T
    vg :: T
    mbase :: T
    status :: Int
    pmax :: T
    pmin :: T
    i :: Int
    model_poly :: Bool
    startup :: T
    shutdown :: T
    n :: Int
    c :: NTuple{3, T}
end

"""
    struct Data{T <: Real}
        version :: String
        baseMVA :: T
        bus :: Vector{BusData{T}}
        gen :: Vector{GenData{T}}
        branch :: Vector{BranchData{T}}
        storage :: Vector{StorageData{T}}
    end
```version```, ```baseMVA```, ```bus```, ```gen```, ```branch```, and ```storage```
all corespond to members of the mpc object created by a matpower file.
Their fields correspond exactly with the columns of the relevant ```mpc``` member.
"""
struct PowerData{T <: Real}
    version :: String
    baseMVA :: T
    bus :: Vector{BusData{T}}
    gen :: Vector{GenData{T}}
    branch :: Vector{BranchData{T}}
    storage :: Vector{StorageData{T}}
end

const EMPTY_SUBSTRING = SubString("", 1, 0)
const MATPOWER_ARRAY_KEYS :: Vector{String} = ["bus", "gen", "branch", "storage", "gencost"]
const MATPOWER_KEYS :: Vector{String} = [["version", "baseMVA", "areas"]; MATPOWER_ARRAY_KEYS]
const INIT_WORDS_LEN = 25
const GITHUB_ISSUES = "https://github.com/MadNLP/ExaPowerIO.jl/issues."

struct WordedString
    s :: SubString{String}
    extra_ends :: String
end

function Base.iterate(worded_string :: WordedString)
    iterate(worded_string, 1)
end

function Base.iterate(worded_string :: WordedString, start :: Int) :: Union{Nothing, Tuple{SubString{String}, Int}}
    if start > length(worded_string.s)
        return nothing
    end
    s = SubString(worded_string.s, start, length(worded_string.s))
    left = 1
    while left <= length(s) && isspace(s[left])
        left += 1
    end
    if left > length(s)
        return nothing
    end
    should_end = c -> isspace(c) || contains(worded_string.extra_ends, c)
    right = left
    while right <= length(s) && !should_end(s[right])
        right += 1
    end
    # right is non-inclusive
    if should_end(s[left])
        right += 1
    end
    (SubString(s, left, right - 1), right + start - 1)
end

function Base.length(worded_string :: WordedString)
    is_end = c -> isspace(c) || contains(worded_string.extra_ends, c)
    len = 0
    last_was_end = true
    for c in worded_string.s
        cur_is_end = is_end(c)
        if (last_was_end && !cur_is_end) || cur_is_end
            len += 1
        end
        last_was_end = cur_is_end
    end
    len
end

function parse_matpower(::Type{T}, fname :: String) :: PowerData{T} where T <: Real
    fstring = read(open(fname), String)
    lines :: Vector{SubString{String}} = split(fstring, "\n")
    in_array = false
    cur_key :: String = ""
    version = ""
    baseMVA :: T = T(0.0)
    bus :: Vector{BusData{T}} = []
    gen :: Vector{GenData{T}} = []
    branch :: Vector{BranchData{T}} = []
    storage :: Vector{StorageData{T}} = []
    line_ind = 1
    line :: SubString{String} = lines[line_ind]
    type = Missing
    comment = EMPTY_SUBSTRING
    col_inds :: Dict{String, Int} = Dict()
    words :: Vector{SubString{String}} = [EMPTY_SUBSTRING for _ in 1:INIT_WORDS_LEN]
    items = [T(0.0) for _ in 1:INIT_WORDS_LEN]
    reallocated = false
    bus_map :: Dict{Int, Int} = Dict()

    row_num = 0
    @views for line in lines
        if in_array && length(line) >= 1 && line[1] == ']'
            if cur_key == "bus"
                bus = Vector(undef, row_num)
            elseif cur_key == "gen"
                gen = Vector(undef, row_num)
            elseif cur_key == "branch"
                branch = Vector(undef, row_num)
            elseif cur_key == "storage"
                storage = Vector(undef, row_num)
            end
            row_num = 0
            in_array = false
        elseif in_array && ';' in line
            row_num += 1
        elseif length(line) > length("mpc.")
            cur_key = iterate(WordedString(line, ""))[1][length("mpc.")+1:end]
            if cur_key in MATPOWER_ARRAY_KEYS
                in_array = true
            end
        end
    end

    row_num = 1
    while true
        if length(line) != 0 && line[1] == '%'
            comment = line
            line = lines[line_ind += 1] :: SubString{String}
            continue
        end
        num_words = 0
        for (i, word) in enumerate(WordedString(line, "=;[]%"))
            if word == "%"
                break
            end
            num_words = i
            reallocated && continue
            i > length(words) && (reallocated = true; continue)
            words[i] = word
        end
        if reallocated
            println(stderr, "ExaPowerIO.jl was forced to grow the words vector to length $num_words. Please ensure your input file is valid, and then open an issue at $GITHUB_ISSUES")
            reallocated = false
            let line = line
                words = [EMPTY_SUBSTRING for _ in 1:num_words]
            end
            items = [T(0.0) for _ in 1:num_words]
            continue
        end

        if in_array && length(line) != 0 && line[1] != '%'
            squares = findall(s -> s == "]", words)
            first_sq = length(squares) == 0 ? typemax(Int64) : squares[1]
            first_semi = length(squares) == 0 ? typemax(Int64) : squares[1]
            num_items = min(min(first_semi - 1, first_sq - 1), num_words - 1)
            for i in 1:num_items
                items[i] = parse(T, words[i]) :: T
            end

            if num_items == 0 && num_words >= 2 && words[num_words-1] == "]" && words[num_words] == ";"
                if cur_key == "bus"
                    bus_map = Dict(bus.bus_i => i for (i, bus) in enumerate(bus))
                end
                in_array = false
            elseif num_words != 0 && words[num_words] != ";"
                error("Invalid matpower file. Line $(line_ind) array doesn't end with ; or ];")
            elseif length(items) != 0
                if cur_key == "bus"
                    bus[row_num] = BusData(
                        round(Int, items[col_inds["bus_i"]]),
                        round(Int, items[col_inds["type"]]),
                        items[col_inds["Pd"]] / baseMVA,
                        items[col_inds["Qd"]] / baseMVA,
                        items[col_inds["Gs"]],
                        items[col_inds["Bs"]],
                        round(Int, items[col_inds["area"]]),
                        items[col_inds["Vm"]],
                        items[col_inds["Va"]],
                        items[col_inds["baseKV"]],
                        round(Int, items[col_inds["zone"]]),
                        items[col_inds["Vmax"]],
                        items[col_inds["Vmin"]],
                    )
                elseif cur_key == "gen"
                    gen[row_num] = GenData(
                        bus_map[round(Int, items[col_inds["bus"]])],
                        items[col_inds["Pg"]] / baseMVA,
                        items[col_inds["Qg"]] / baseMVA,
                        items[col_inds["Qmax"]] / baseMVA,
                        items[col_inds["Qmin"]] / baseMVA,
                        items[col_inds["Vg"]],
                        items[col_inds["mBase"]],
                        round(Int, items[col_inds["status"]]),
                        items[col_inds["Pmax"]] / baseMVA,
                        items[col_inds["Pmin"]] / baseMVA,
                        row_num,
                        false,
                        T(0),
                        T(0),
                        0,
                        (T(0), T(0), T(0)),
                    )
                elseif cur_key == "gencost"
                    first_cost_col = col_inds["n"] + 1
                    # pglib puts the column name as "2" for some reason, so we cant use col_inds
                    model_poly = items[1] == 2
                    n = round(Int, items[col_inds["n"]])
                    normalize_cost = let baseMVA = baseMVA, items = items
                        function normalize_cost(i :: Int)
                            c = items[first_cost_col+i-1]
                            return model_poly ? baseMVA ^ (n-i) * c : c
                        end
                    end
                    gen[row_num] = GenData(
                        round(Int, gen[row_num].bus),
                        gen[row_num].pg,
                        gen[row_num].qg,
                        gen[row_num].qmax,
                        gen[row_num].qmin,
                        gen[row_num].vg,
                        gen[row_num].mbase,
                        gen[row_num].status,
                        gen[row_num].pmax,
                        gen[row_num].pmin,
                        row_num,
                        model_poly,
                        items[col_inds["startup"]],
                        items[col_inds["shutdown"]],
                        n,
                        ntuple(normalize_cost, 3)
                    )
                elseif cur_key == "branch"
                    br_b = items[haskey(col_inds, "b") ? col_inds["b"] : col_inds["br_b"]]
                    branch[row_num] = BranchData{T}(
                        bus_map[round(Int, items[col_inds["fbus"]])],
                        bus_map[round(Int, items[col_inds["tbus"]])],
                        items[haskey(col_inds, "r") ? col_inds["r"] : col_inds["br_r"]],
                        items[haskey(col_inds, "x") ? col_inds["x"] : col_inds["br_x"]],
                        haskey(col_inds, "b_fr") ? items[col_inds["b_fr"]] : br_b / T(2.0),
                        haskey(col_inds, "b_to") ? items[col_inds["b_to"]] : br_b / T(2.0),
                        haskey(col_inds, "g_fr") ? items[col_inds["g_fr"]] : T(0.0),
                        haskey(col_inds, "g_to") ? items[col_inds["g_to"]] : T(0.0),
                        items[col_inds["rateA"]] / baseMVA,
                        items[col_inds["rateB"]] / baseMVA,
                        items[col_inds["rateC"]] / baseMVA,
                        items[haskey(col_inds, "tap") ? col_inds["tap"] : col_inds["ratio"]],
                        (items[haskey(col_inds, "shift") ? col_inds["shift"] : col_inds["angle"]]) / T(180.0) * T(pi),
                        round(Int, items[col_inds["status"]]),
                        items[col_inds["angmin"]] / T(180.0) * T(pi),
                        items[col_inds["angmax"]] / T(180.0) * T(pi),
                    )
                elseif cur_key == "storage"
                    storage[row_num] = StorageData(
                        items[col_inds["storage_bus"]],
                        items[col_inds["ps"]],
                        items[col_inds["qs"]],
                        items[col_inds["energy"]],
                        items[col_inds["energy_rating"]],
                        items[col_inds["charge_rating"]],
                        items[col_inds["discharge_rating"]],
                        items[col_inds["charge_efficiency"]],
                        items[col_inds["discharge_efficiency"]],
                        items[col_inds["thermal_rating"]],
                        items[col_inds["qmin"]],
                        items[col_inds["qmax"]],
                        items[col_inds["r"]],
                        items[col_inds["x"]],
                        items[col_inds["p_loss"]],
                        items[col_inds["q_loss"]],
                        items[col_inds["status"]],
                    )
                end
                row_num += 1
            end
        elseif length(line) != 0 && line[1] != '%' && words[1] != "function"
            col_inds = Dict(column => i for (i, column) in
                            enumerate(Base.Iterators.drop(WordedString(comment, ""), 1)))
            comment = EMPTY_SUBSTRING
            cur_key = ""
            type = Any

            for key in MATPOWER_KEYS
                full_name = "mpc.$key"
                idxs = findall(s -> s == full_name, words) 
                if idxs != []
                    cur_key = key
                    break
                end
            end

            if cur_key == ""
                error("Error parsing data. Invalid variable assignment on line $(line_ind).")
            end
            if cur_key == "version"
                raw_data = words[num_words-1]
                version = String(raw_data[2:length(raw_data)-1])
            elseif cur_key == "baseMVA"
                baseMVA = parse(T, words[num_words-1]) :: T
            else
                in_array = true
                row_num = 1
            end
        end

        if line_ind < length(lines)
            line = lines[line_ind += 1] :: SubString{String}
        else
            break
        end
    end

    has_gen = [false for _ in 1:length(bus) ]
    for gen in gen
        if gen.status == 1
            has_gen[gen.bus] = true
        end
    end
    for (i, b) in enumerate(bus)
        if has_gen[i] && b.type == 1
            bus[i] = BusData(
                b.bus_i,
                2,
                b.pd,
                b.qd,
                b.gs,
                b.bs,
                b.area,
                b.vm,
                b.va,
                b.baseKV,
                b.zone,
                b.vmax,
                b.vmin
            )
        elseif !has_gen[i] && b.type == 2
            bus[i] = BusData(
                b.bus_i,
                1,
                b.pd,
                b.qd,
                b.gs,
                b.bs,
                b.area,
                b.vm,
                b.va,
                b.baseKV,
                b.zone,
                b.vmax,
                b.vmin
            )
        end
    end

    return PowerData(version, baseMVA, bus, gen, branch, storage)
end

function standardize_cost_terms!(data :: PowerData{T}, order) where T <: Real
    gen_order = 1
    for (_, gen) in enumerate(data.gen)
        max_ind = 1
        for i in 1:length(gen.c)
            max_ind = i
            if gen.c[i] != 0
                break
            end
            gen_order = max(gen_order, length(gen.c) - max_ind + 1)
        end
    end
    gen_order = max(gen_order, order + 1)
    for (i, gen) in enumerate(data.gen)
        if length(gen.c) == gen_order
            continue
        end
        std_cost = [0.0 for _ in 1:gen_order]
        cur_cost = reverse(gen.c)
        for i in 1:min(gen_order, length(cur_cost))
            std_cost[i] = cur_cost[i]
        end
        c = reverse(std_cost)
        n = length(gen_order)
        data.gen[i] = GenData(
            data.gen[i].bus,
            data.gen[i].pg,
            data.gen[i].qg,
            data.gen[i].qmax,
            data.gen[i].qmin,
            data.gen[i].vg,
            data.gen[i].mbase,
            data.gen[i].status,
            data.gen[i].pmax,
            data.gen[i].pmin,
            data.gen[i].i,
            data.gen[i].startup,
            data.gen[i].shutdown,
            n,
            c,
        )
    end
end

function calc_thermal_limits!(data :: PowerData{T}) where T <: Real
    for branch in filter(branch -> branch.ratea <= 0, data.branch)
        xi = inv(branch.r + im * branch.x)
        y_mag = abs.(ifelse(isfinite(xi), xi, zero(xi)))

        fr_vmax = data.bus[branch.fbus].vmax
        to_vmax = data.bus[branch.tbus].vmax
        m_vmax = max(fr_vmax, to_vmax)

        theta_max = max(abs(branch.angmin), abs(branch.angmax))
        c_max = sqrt(fr_vmax^2 + to_vmax^2 - 2*fr_vmax*to_vmax*cos(theta_max))

        branch.rateA = y_mag * m_vmax * c_max
    end
end

function process_ac_power_data(::Type{T}, filename) :: PowerData{T} where T <: Real
    data = parse_matpower(T, filename)
    standardize_cost_terms!(data, 2)
    calc_thermal_limits!(data)
    return data
end

should_recurse(fields) :: Bool =
    all(typeof(field) == Symbol for field in fields) && !isempty(fields)
"""
    struct_to_nt(data :: T) :: NamedTuple where T

This is a general purpose function for converting structs to named tuples.

It is used internally when ```out_type=NamedTuple``` is passed to ```parse_pglib``` or ```parse_file```,
and is more expensive than the actual parsing in both cases.

We export this function for those wishing to compare the performance of ```out_type=ExaPowerIO.PowerData``` with ```out_type=NamedTuple```,
as well as benchmarking reasons.
"""
function struct_to_nt(data :: T) :: NamedTuple where T
    result = NamedTuple()
    for field in fieldnames(T)
        val = getfield(data, field)
        next_fields = fieldnames(typeof(val))
        if typeof(val) <: Vector
            if !isempty(val) && should_recurse(fieldnames(typeof(val[1])))
                val = map(struct_to_nt, val)
            end
        elseif should_recurse(next_fields)
            val = struct_to_nt(val)
        end
        result = merge(result, (;field => val))
    end
    return result
end
