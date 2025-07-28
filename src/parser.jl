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

const MATPOWER_KEYS :: Vector{String} = ["version", "baseMVA", "areas", "bus", "gencost", "gen", "branch", "storage"];
const NULL_VIEW::SubString{String} = SubString("", 1, 0)
const PRINTABLE_ASCII = 96
const ASCII_OFFSET = 31
is_end(c::Char) = isspace(c) || c in "=;[]%"
const ENDS = ntuple(i -> is_end(Char(i + ASCII_OFFSET)), PRINTABLE_ASCII)
const KEY_MIN_LEN = 4

struct WordedString
    s :: SubString{String}
    len :: Int
end

@inbounds @views function iter_ws(ws :: WordedString, start :: Int) :: Tuple{SubString{String}, Int}
    if start > ws.len
        return (NULL_VIEW, 0)
    end
    left = start
    while isspace(ws.s[left]) && left <= ws.len
        left += 1
    end
    if left > ws.len || ws.s[left] == '%'
        return (NULL_VIEW, 0)
    end
    right = left
    should_end = c -> c > ASCII_OFFSET && ENDS[c - ASCII_OFFSET]
    while right <= ws.len && !should_end(Int8(ws.s[right]))
        right += 1
    end
    # right is non-inclusive
    if should_end(Int8(ws.s[left]))
        right += 1
    end
    (ws.s[left:right-1], right)
end

macro iter_to_ntuple(N, iter_expr)
    n = if N isa Integer
        N
    else
        try
            eval(__module__, N)
        catch
            error("N must be a constant integer")
        end
    end
    n isa Integer || error("N must be an integer")
    n >= 0 || error("N must be non-negative")

    iter_sym = gensym("iter")
    state_sym = gensym("state")
    x_syms = [gensym("x") for _ in 1:n]

    body = Expr[]
    push!(body, :($iter_sym = $(esc(iter_expr))))
    push!(body, :($state_sym = iter_ws($iter_sym, 1)))
    
    for i in 1:n
        push!(body, :($(x_syms[i]) = $state_sym[1]))
        if i < n
            push!(body, :($state_sym = $state_sym[2] == 0 ? (NULL_VIEW, 0) : iter_ws($iter_sym, $state_sym[2])))
        end
    end
    push!(body, Expr(:tuple, x_syms...))

    return Expr(:block, body...)
end

@inbounds @inline @views function parse_matpower(::Type{T}, ::Type{V}, fname :: String) where {T<:Real, V<:AbstractVector}
    fstring = read(open(fname), String)
    lines = split(fstring, "\n")
    num_lines = length(lines)
    in_array = false
    cur_key = ""
    bus = BusData{T}[]
    gen = GenData{T}[]
    branch = BranchData{T}[]
    storage = StorageData{T}[]

    row_num = 0
    for line in lines
        line_len = line.ncodeunits
        if in_array && line_len >= 1 && line[1] == ']'
            if cur_key == "bus"
                bus = V(undef, row_num)
            elseif cur_key == "gen"
                gen = V(undef, row_num)
            elseif cur_key == "branch"
                branch = V(undef, row_num)
            elseif cur_key == "storage"
                storage = V(undef, row_num)
            end
            row_num = 0
            in_array = false
        elseif in_array && ';' in line
            row_num += 1
        elseif line_len > KEY_MIN_LEN && line[1:4] == "mpc." && line[end] == '['
            cur_key = iter_ws(WordedString(line, line_len), 1)[1][KEY_MIN_LEN+1:end]
            in_array = true
        end
    end

    row_num = 1
    line_ind = 1
    line = lines[line_ind]
    line_len = line.ncodeunits
    version = ""
    baseMVA :: T = T(0.0)
    bus_map :: Dict{Int, Int} = Dict()
    while true
        if line_len != 0 && line[1] == '%'
            line = lines[line_ind += 1]
            line_len = line.ncodeunits
            continue
        end
        if in_array && line_len != 0
            if startswith(line, "];")
                if cur_key == "bus"
                    bus_map = Dict(bus.bus_i => i for (i, bus) in enumerate(bus))
                end
                in_array = false
            elseif cur_key == "bus"
                bus_words = @iter_to_ntuple 13 WordedString(line, line_len)
                bus[row_num] = BusData(
                    parse(Int, bus_words[1]),
                    parse(Int, bus_words[2]),
                    parse(T, bus_words[3]) / baseMVA,
                    parse(T, bus_words[4]) / baseMVA,
                    parse(T, bus_words[5]),
                    parse(T, bus_words[6]),
                    parse(Int, bus_words[7]),
                    parse(T, bus_words[8]),
                    parse(T, bus_words[9]),
                    parse(T, bus_words[10]),
                    parse(Int, bus_words[11]),
                    parse(T, bus_words[12]),
                    parse(T, bus_words[13]),
                )
            elseif cur_key == "gen"
                gen_words = @iter_to_ntuple 10 WordedString(line, line_len)
                gen[row_num] = GenData(
                    bus_map[parse(Int, gen_words[1])],
                    parse(T, gen_words[2]) / baseMVA,
                    parse(T, gen_words[3]) / baseMVA,
                    parse(T, gen_words[4]) / baseMVA,
                    parse(T, gen_words[5]) / baseMVA,
                    parse(T, gen_words[6]),
                    parse(T, gen_words[7]),
                    parse(Int, gen_words[8]),
                    parse(T, gen_words[9]) / baseMVA,
                    parse(T, gen_words[10]) / baseMVA,
                    row_num,
                    false,
                    T(0),
                    T(0),
                    0,
                    (T(0), T(0), T(0)),
                )
            elseif cur_key == "gencost"
                genc_words = @iter_to_ntuple 7 WordedString(line, line_len)
                model_poly = parse(Int, genc_words[1]) == 2
                n = parse(Int, genc_words[4])
                normalize_cost = let baseMVA = baseMVA
                    function normalize_cost(i :: Int)
                        c = parse(T, genc_words[4 + i])
                        return model_poly ? baseMVA ^ (n-i) * c : c
                    end
                end
                gen[row_num] = GenData(
                    gen[row_num].bus,
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
                    parse(T, genc_words[2]),
                    parse(T, genc_words[3]),
                    n,
                    ntuple(normalize_cost, 3)
                )
            elseif cur_key == "branch"
                branch_words = @iter_to_ntuple 13 WordedString(line, line_len)
                br_b = parse(T, branch_words[5])
                branch[row_num] = BranchData{T}(
                    bus_map[parse(Int, branch_words[1])],
                    bus_map[parse(Int, branch_words[2])],
                    parse(T, branch_words[3]),
                    parse(T, branch_words[4]),
                    br_b / T(2.0),
                    br_b / T(2.0),
                    T(0.0),
                    T(0.0),
                    parse(T, branch_words[6]) / baseMVA,
                    parse(T, branch_words[7]) / baseMVA,
                    parse(T, branch_words[8]) / baseMVA,
                    parse(T, branch_words[9]),
                    (parse(T, branch_words[10])) / T(180.0) * T(pi),
                    parse(Int, branch_words[11]),
                    parse(T, branch_words[12]) / T(180.0) * T(pi),
                    parse(T, branch_words[13]) / T(180.0) * T(pi),
                )
            elseif cur_key == "storage"
                storage_words = @iter_to_ntuple 17 WordedString(line, line_len)
                storage[row_num] = StorageData(
                    parse(T, storage_words[1]),
                    parse(T, storage_words[2]),
                    parse(T, storage_words[3]),
                    parse(T, storage_words[4]),
                    parse(T, storage_words[5]),
                    parse(T, storage_words[6]),
                    parse(T, storage_words[7]),
                    parse(T, storage_words[8]),
                    parse(T, storage_words[9]),
                    parse(T, storage_words[10]),
                    parse(T, storage_words[11]),
                    parse(T, storage_words[12]),
                    parse(T, storage_words[13]),
                    parse(T, storage_words[14]),
                    parse(T, storage_words[15]),
                    parse(T, storage_words[16]),
                    parse(T, storage_words[17]),
                )
            end
            if in_array
                row_num += 1
            end
        elseif !startswith(line, "function") && line_len > 0
            cur_key = ""
            for key in MATPOWER_KEYS
                full_name = "mpc.$key"
                if startswith(line, full_name)
                    cur_key = key
                    break
                end
            end

            if cur_key == ""
                error("Error parsing data. Invalid variable assignment on line $(line_ind).")
            end
            words = @iter_to_ntuple 3 WordedString(line, line_len)
            if cur_key == "version"
                raw_data = words[3]
                version = String(raw_data[2:raw_data.ncodeunits-1])
            elseif cur_key == "baseMVA"
                baseMVA = parse(T, words[3]) :: T
            else
                in_array = true
                row_num = 1
            end
        end

        if line_ind < num_lines
            line = lines[line_ind += 1]
            line_len = line.ncodeunits
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

    return PowerData(version, baseMVA, bus, gen, branch, storage)
end

@inline function standardize_cost_terms!(data :: PowerData{T}, order) where T <: Real
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
