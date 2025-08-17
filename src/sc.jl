include("shared.jl")

@enum SpecNodeTag float=1 int=2 string=3 list=4 dict=5

struct SpecNode
    name::SubString{String}
    id::Int64
    kids::Vector{SpecNode}
    tag::SpecNodeTag
end

@views macro gen_parser(fname)
    file = read(open(fname), String)

    stack = [SpecNode(NULL_VIEW, 0, [], float)]
    parse_string = quote
        @inline @inbounds @views function $(:parse_string)(words, start)::Tuple{SubString{String}, Int64}
            escaped = false
            i = start
            while isspace(words.s[i])
                i += 1
            end
            i += 1
            while words.s[i] != '"' || escaped
                escaped = words.s[i] == '\\'
                i += 1
            end
            return words.s[start+1:i-1], i+1
        end
    end
    parse_int = quote
        @inline function $(:parse_int)(words, start)::Tuple{Int64, Int64}
            raw, start = iterate(words, start)
            return parse(Int64, raw), start
        end
    end
    parse_float = quote
        @inline function $(:parse_float)(words, start)::Tuple{Float64, Int64}
            raw, start = iterate(words, start)
            return parse(Float64, raw), start
        end
    end
    parsers = [parse_string, parse_int, parse_float]
    name = NULL_VIEW
    for word in WordedString(file, length(file))
        if word[1] == '['
            push!(stack, SpecNode(name, length(parsers), [], list))
            push!(parsers, :())
        elseif word[1] == '{'
            push!(stack, SpecNode(name, length(parsers), [], dict))
            push!(parsers, :())
        elseif word == "string"
            parser_name = Symbol("parse_$(length(parsers))")
            push!(stack[end].kids, SpecNode(name, length(parsers), [], string))
            push!(parsers, :($parser_name(words, start)::Tuple{String, Int64} = parse_string(words, start)))
        elseif word == "int"
            parser_name = Symbol("parse_$(length(parsers))")
            push!(stack[end].kids, SpecNode(name, length(parsers), [], int))
            push!(parsers, :($parser_name(words, start)::Tuple{Int64, Int64} = parse_int(words, start)))
        elseif word == "float"
            parser_name = Symbol("parse_$(length(parsers))")
            push!(stack[end].kids, SpecNode(name, length(parsers), [], float))
            push!(parsers, :($parser_name(words, start)::Tuple{Float64, Int64} = parse_float(words, start)))
        elseif word[1] == ']'
            last = pop!(stack)
            parser_name = Symbol("parse_$(last.id)")
            child_parser = Symbol("parse_$(last.kids[1].id)")
            parsers[last.id + 1] = quote
                @inline function $parser_name(words::WordedString, start::Int)
                    word = NULL_VIEW
                    result = []
                    word, start = iterate(words, start)
                    next_word, next_start = iterate(words, start)
                    if next_word[1] == ']'
                        return result, next_start
                    end
                    while word[1] != ']'
                        kid, start = $child_parser(words, start)
                        push!(result, kid)
                        word, start = iterate(words, start)
                    end
                    return result, start
                end
            end
            push!(stack[end].kids, last)
        elseif word[1] == '}'
            last = pop!(stack)
            parser_name = Symbol("parse_$(last.id)")
            calls = Vector(undef, length(last.kids) * 2)
            for (i, kid) in enumerate(last.kids)
                calls[2*i-1] = quote
                    word, start = iterate(words, start)
                    $(Symbol(kid.name)), start = $(Symbol("parse_$(kid.id)"))(words, start)
                end
                calls[2*i] = quote word, start = iterate(words, start) end
            end
            result = map(kid -> :($(Symbol(kid.name)) = $(Symbol(kid.name))), last.kids)
            parsers[last.id + 1] = quote
                @inline function $parser_name(words::WordedString, start::Int)
                    word, start = iterate(words, start)
                    $(calls...)
                    (($(result...),), start)
                end
            end
            push!(stack[end].kids, last)
        else
            name = word
        end
    end
    final_name = Symbol("parse_$(stack[1].kids[1].name)")
    result= quote
        $(parsers...)
        $(esc(Symbol("parse_$(stack[1].kids[1].name)"))) = $(Symbol("parse_$(stack[1].kids[1].id)"))
    end
    return result
end
