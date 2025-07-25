# FOR CONVENIENCE, the MATPOWER file spec
# https://matpower.app/manual/matpower/DataFileFormat.html

macro as_nt(struct_expr)
    if struct_expr.head != :struct
        error("@to_namedtuple must be applied to a struct definition")
    end
    struct_name = struct_expr.args[2] isa Symbol ? struct_expr.args[2] : struct_expr.args[2].args[1]
    nt_expr = Expr(:tuple)
    for line in filter(child -> child isa Expr, struct_expr.args[3].args)
        push!(nt_expr.args, Expr(:(=), line.args[1], Expr(:., :obj, QuoteNode(line.args[1]))))
    end
    return esc(quote
        $struct_expr
        function struct_to_nt(obj::$struct_name{T})::NamedTuple where {T<:Real}
            $nt_expr
        end
    end)
end

@as_nt struct BusData{T <: Real}
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
@doc """
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
""" BusData

@as_nt struct BranchData{T <: Real}
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
end
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
    BranchData{T}(
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
@doc """
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
""" BranchData

@as_nt struct StorageData{T <: Real}
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
@doc """
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
""" StorageData

@as_nt struct GenData{T <: Real}
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
@doc """
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
""" GenData

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
struct PowerData{
    T <: Real,
    VBusT <: AbstractVector{BusData{T}},
    VGenT <: AbstractVector{GenData{T}},
    VBranchT <: AbstractVector{BranchData{T}},
    VStorageT <: AbstractVector{StorageData{T}}
}
    version :: String
    baseMVA :: T
    bus :: VBusT
    gen :: VGenT
    branch :: VBranchT
    storage :: VStorageT
end

function struct_to_nt(data::PowerData)
    (
        version = data.version,
        baseMVA = data.baseMVA,
        bus = struct_to_nt.(data.bus),
        gen = struct_to_nt.(data.gen),
        branch = struct_to_nt.(data.branch),
        storage = struct_to_nt.(data.storage),
    )
end

const MATPOWER_ARRAY_KEYS :: Vector{String} = ["bus", "gen", "branch", "storage", "gencost"]
const MATPOWER_KEYS :: Vector{String} = [["version", "baseMVA", "areas"]; MATPOWER_ARRAY_KEYS]
const INIT_WORDS_LEN = 25
const GITHUB_ISSUES = "https://github.com/MadNLP/ExaPowerIO.jl/issues."

struct WordedString
    s :: SubString{String}
    len :: Int
    extra_ends :: String
    WordedString(s::SubString{String}, extra_ends::String) = new(s, length(s), extra_ends)
end

function Base.iterate(worded_string :: WordedString)
    iterate(worded_string, 1)
end

@views function Base.iterate(worded_string :: WordedString, start :: Int) :: Union{Nothing, Tuple{SubString{String}, Int}}
    len = worded_string.len - start + 1
    if len <= 0
        return nothing
    end
    s = worded_string.s[start:end]
    left = 1
    while left <= len && isspace(s[left])
        left += 1
    end
    if left > len
        return nothing
    end
    should_end = c -> isspace(c) || contains(worded_string.extra_ends, c)
    right = left
    while right <= len && !should_end(s[right])
        right += 1
    end
    # right is non-inclusive
    if should_end(s[left])
        right += 1
    end
    (s[left:right-1], right + start - 1)
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

function parse_matpower(::Type{T}, ::Type{V}, fname :: String) where {T<:Real, V<:AbstractVector}
    fstring = read(open(fname), String)
    lines :: Vector{SubString{String}} = split(fstring, "\n")
    in_array = false
    cur_key :: String = ""
    bus :: Vector{BusData{T}} = []
    gen :: Vector{GenData{T}} = []
    branch :: Vector{BranchData{T}} = []
    storage :: Vector{StorageData{T}} = []

    row_num = 0
    for line in lines
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
    line_ind = 1
    line :: SubString{String} = lines[line_ind]
    version = ""
    baseMVA :: T = T(0.0)
    bus_map :: Dict{Int, Int} = Dict()
    words :: Vector{SubString{String}} = Vector(undef, INIT_WORDS_LEN)
    items = Vector(undef, INIT_WORDS_LEN)
    reallocated = false
    while true
        if length(line) != 0 && line[1] == '%'
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
                words = Vector(undef, num_words)
                items = Vector(undef, INIT_WORDS_LEN)
            end
            continue
        end

        if in_array && length(line) != 0 && line[1] != '%'
            squares = findall(s -> s == "]", words[1:num_words])
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
                        round(Int, items[1]),
                        round(Int, items[2]),
                        items[3] / baseMVA,
                        items[4] / baseMVA,
                        items[5],
                        items[6],
                        round(Int, items[7]),
                        items[8],
                        items[9],
                        items[10],
                        round(Int, items[11]),
                        items[12],
                        items[13],
                    )
                elseif cur_key == "gen"
                    gen[row_num] = GenData(
                        bus_map[round(Int, items[1])],
                        items[2] / baseMVA,
                        items[3] / baseMVA,
                        items[4] / baseMVA,
                        items[5] / baseMVA,
                        items[6],
                        items[7],
                        round(Int, items[8]),
                        items[9] / baseMVA,
                        items[10] / baseMVA,
                        row_num,
                        false,
                        T(0),
                        T(0),
                        0,
                        (T(0), T(0), T(0)),
                    )
                elseif cur_key == "gencost"
                    model_poly = items[1] == 2
                    n = round(Int, items[4])
                    normalize_cost = let baseMVA = baseMVA, items = items
                        function normalize_cost(i :: Int)
                            c = items[4 + i]
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
                        items[2],
                        items[3],
                        n,
                        ntuple(normalize_cost, 3)
                    )
                elseif cur_key == "branch"
                    branch[row_num] = BranchData{T}(
                        bus_map[round(Int, items[1])],
                        bus_map[round(Int, items[2])],
                        items[3],
                        items[4],
                        items[5] / T(2.0),
                        items[5] / T(2.0),
                        T(0.0),
                        T(0.0),
                        items[6] / baseMVA,
                        items[7] / baseMVA,
                        items[8] / baseMVA,
                        items[9],
                        (items[10]) / T(180.0) * T(pi),
                        round(Int, items[11]),
                        items[12] / T(180.0) * T(pi),
                        items[13] / T(180.0) * T(pi),
                    )
                elseif cur_key == "storage"
                    storage[row_num] = StorageData(
                        items[1],
                        items[2],
                        items[3],
                        items[4],
                        items[5],
                        items[6],
                        items[7],
                        items[8],
                        items[9],
                        items[10],
                        items[11],
                        items[12],
                        items[13],
                        items[14],
                        items[15],
                        items[16],
                        items[17],
                    )
                end
                row_num += 1
            end
        elseif length(line) != 0 && line[1] != '%' && words[1] != "function"
            for key in MATPOWER_KEYS
                full_name = "mpc.$key"
                idxs = findall(s -> s == full_name, words[1:num_words])
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

    has_gen = [false for _ in 1:length(bus)]
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

    return PowerData(version, baseMVA, V(bus), V(gen), V(branch), V(storage))
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
