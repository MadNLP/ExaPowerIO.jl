using Parsers

@enum SpecNodeTag float=1 int=2 string=3 list=4 dict=5

struct SpecNode
    name::SubString{String}
    sym::Symbol
    kids::Vector{SpecNode}
    tag::SpecNodeTag
end

@views macro gen_parser(fname, out_name)
    mod_path = isnothing(pathof(@__MODULE__)) ? "src/" : "$(dirname(pathof(@__MODULE__)))/"
    file = read(open("$mod_path$fname"), String)

    stack = [SpecNode(NULL_VIEW, gensym(), [], float)]
    parse_string = quote
        @inline @inbounds @views function $(:parse_string)(words, start)::Tuple{SubString{String}, Int64}
            escaped = false
            i = start
            while isspace(codeunit(words.s, i))
                i += 1
            end
            i += 1
            start = i
            while codeunit(words.s, i) != UInt8('"') || escaped
                escaped = words.s[i] == '\\'
                i += 1
            end
            return words.s[start:i-1], i+1
        end
    end
    parse_int = quote
        @inbounds @inline function $(:parse_int)(words, start)::Tuple{Int64, Int64}
            raw, start = iterate(words, start)
            return parse(Int64, words.s[raw]), start
        end
    end
    parse_float = quote
        @inbounds @inline function ($(:parse_float)(::Type{T}, words, start)::Tuple{T, Int64}) where T<:Real
            raw, start = iterate(words, start)
            return parse(T, words.s[raw]), start
        end
    end
    parsers = [parse_string, parse_int, parse_float]
    name = NULL_VIEW
    words = WordedString(file)
    for word in words
        if words.s[word[1]] == '['
            push!(stack, SpecNode(name, gensym(), [], list))
        elseif words.s[word[1]] == '{'
            push!(stack, SpecNode(name, gensym(), [], dict))
        elseif words.s[word] == "string"
            parser_name = gensym()
            push!(stack[end].kids, SpecNode(name, parser_name, [], string))
            push!(parsers, :(($parser_name(::Type{T}, words, start)::Tuple{String, Int64}) where T<:Real = parse_string(words, start)))
        elseif words.s[word] == "int"
            parser_name = gensym()
            push!(stack[end].kids, SpecNode(name, parser_name, [], int))
            push!(parsers, :(($parser_name(::Type{T}, words, start)::Tuple{Int64, Int64}) where T<:Real = parse_int(words, start)))
        elseif words.s[word] == "float"
            parser_name = gensym()
            push!(stack[end].kids, SpecNode(name, parser_name, [], float))
            push!(parsers, :(($parser_name(::Type{T}, words, start)::Tuple{T, Int64}) where T<:Real = parse_float(T, words, start)))
        elseif words.s[word[1]] == ']'
            last = pop!(stack)
            parser_name = last.sym
            child_parser = last.kids[1].sym
            parser = quote
                @inbounds @inline function ($parser_name(::Type{T}, words::WordedStringUnchecked, start::Int)) where T<:Real
                    word = NULL_VIEW
                    result = []
                    word, start = iterate(words, start)
                    next_word, next_start = iterate(words, start)
                    if words.s[next_word[1]] == ']'
                        return result, next_start
                    end
                    while words.s[word[1]] != ']'
                        kid, start = $child_parser(T, words, start)
                        push!(result, kid)
                        word, start = iterate(words, start)
                    end
                    return result, start
                end
            end
            push!(parsers, parser)
            push!(stack[end].kids, last)
        elseif words.s[word[1]] == '}'
            last = pop!(stack)
            parser_name = last.sym
            calls = Vector(undef, length(last.kids) * 2)
            for (i, kid) in enumerate(last.kids)
                calls[2*i-1] = quote
                    word, start = iterate(words, start)
                    name = $(kid.name)
                    @assert words.s[word] == "\"$name\":"
                    $(Symbol(kid.name)), start = $(kid.sym)(T, words, start)
                end
                calls[2*i] = quote word, start = iterate(words, start) end
            end
            result = map(kid -> :($(Symbol(kid.name)) = $(Symbol(kid.name))), last.kids)
            parser = quote
                @inbounds @inline function ($parser_name(::Type{T}, words::WordedStringUnchecked, start::Int)) where T<:Real
                    word, start = iterate(words, start)
                    $(calls...)
                    (($(result...),), start)
                end
            end
            push!(parsers, parser)
            push!(stack[end].kids, last)
        else
            name = words.s[word]
        end
    end
    final_name = Symbol("parse_$(stack[1].kids[1].name)")
    result = quote
        $(parsers...)
        function ($(esc(out_name))(::Type{T}, s)) where T<:Real
            $(stack[1].kids[1].sym)(T, WordedStringUnchecked(s), 1)[1]
        end
    end
    return result
end
@gen_parser "goc3_uc.spec" parse_uc_data
@gen_parser "goc3_static.spec" parse_sc_data
