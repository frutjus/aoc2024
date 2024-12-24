defmodule AoC do
    def zip_tail_with(xs, f) do
        Enum.zip_with(tl(xs), Enum.drop(xs, -1), f)
    end

    def heads(xs) do
        Enum.scan(xs, [], fn item, acc ->
            acc ++ [item]
        end)
    end

    def tails(xs) do
        Enum.scan(xs, xs, fn _, acc ->
            tl(acc)
        end)
    end

    def tails1(xs) do
        [xs | tails(xs)]
    end

    def transpose(rows) do
        rows
        |> List.zip
        |> Enum.map(&Tuple.to_list/1)
    end

    @spec iterate_until(state, (state -> {atom, state | term()})) :: state when state: var
    def iterate_until(state, function) do
        case function.(state) do
            {:iterate, new_state} -> iterate_until(new_state, function)
            {:stop, final_answer} -> final_answer
        end
    end

    def pairs(xs) do
        for {a, ai} <- Enum.with_index(xs),
            {b, bi} <- Enum.with_index(xs),
            ai != bi do
                {a,b}
        end
    end

    def insert_ordered(list, elem, f \\ &Function.identity/1)
    def insert_ordered([], elem, _) do
        [elem]
    end
    def insert_ordered([l | list], elem, f) do
        if f.(l) < f.(elem) do
            [l | insert_ordered(list, elem, f)]
        else
            [elem, l | list]
        end
    end

    def map_map(map, f) do
        for {key, val} <- map,
            into: %{} do
            {key, f.(val)}
        end
    end

    def grid_to_coords(str) do
        for {rw, r} <- str
                    |> String.split("\r\n")
                    |> Enum.with_index(),
            {ch, c} <-  rw
                    |> String.split("", trim: true)
                    |> Enum.with_index()
            do
            {{r,c}, ch}
        end
    end

    def mod(n, m) do
        remainder = rem(n, m)
        if remainder < 0 do
            remainder + m
        else
            remainder
        end
    end

    def map_move(map, key, newkey) do
        {val,new_map} = Map.pop!(map, key)
        if Map.has_key?(map, newkey) do
            raise "can't move #{key}; #{newkey} already exists!"
        else
            Map.put(new_map, newkey, val)
        end
    end
end

import Enum, except: [max: 2]

# Finally, an excuse to use an overcomplicated parsing library!!

import Parse, only: [bind: 2, bind_: 2, just: 1, alt: 2]

parse_wire_name =
    bind Parse.count(3, Parse.alphanum()), fn cs ->
    just join(cs)
    end

parse_initial_wire_value =
    bind parse_wire_name, fn name ->
    bind_ Parse.string_literal(": "),
    (bind Parse.digit(), fn digit ->
    just {name, String.to_integer(digit)}
    end) end

parse_initial_wire_values = Parse.endBy(parse_initial_wire_value, Parse.newline())

parse_and =
    bind_ Parse.string_literal("AND"),
    just fn
        0,0 -> 0
        0,1 -> 0
        1,0 -> 0
        1,1 -> 1
    end

parse_or =
    bind_ Parse.string_literal("OR"),
    just fn
        0,0 -> 0
        0,1 -> 1
        1,0 -> 1
        1,1 -> 1
    end

parse_xor =
    bind_ Parse.string_literal("XOR"),
    just fn
        0,0 -> 0
        0,1 -> 1
        1,0 -> 1
        1,1 -> 0
    end

parse_operation =
    parse_and
    |> alt(parse_or)
    |> alt(parse_xor)

parse_gate =
    bind parse_wire_name, fn w1 ->
    bind_ Parse.string_literal(" "),
    (bind parse_operation, fn op ->
    bind_ Parse.string_literal(" "),
    (bind parse_wire_name, fn w2 ->
    bind_ Parse.string_literal(" -> "),
    (bind parse_wire_name, fn w3 ->
    just {w1, w2, op, w3}
    end) end) end) end

parse_gates = Parse.sepBy(parse_gate, Parse.newline())

parse_all =
    bind parse_initial_wire_values, fn wires ->
    bind_ Parse.newline(),
    (bind parse_gates, fn gates ->
    just {wires, gates}
    end) end

# execute the parser

{:succeed, {wires, gates}} =
    "day24/sample2.txt"
    |> File.read!()
    |> Parse.run(parse_all)

# and solve

final_wires =
    AoC.iterate_until(
        {into(wires, %{}), gates},
        fn {resolved, unresolved} ->
            {new_resolved, new_unresolved} =
                reduce(
                    unresolved,
                    {resolved, []},
                    fn {in1, in2, f, out} = current, {resolved, unresolved} ->
                        if Map.has_key?(resolved, in1) and Map.has_key?(resolved, in2) do
                            result = f.(resolved[in1], resolved[in2])
                            {Map.put(resolved, out, result), unresolved}
                        else
                            {resolved, [current | unresolved]}
                        end
                    end
                )
            
            if empty?(new_unresolved) do
                {:stop, new_resolved}
            else
                {:iterate, {new_resolved, new_unresolved}}
            end
        end
    )

num_from_bits = fn bits ->
    with_index(bits)
    |> map(fn {b, i} -> b * 2 ** i end)
    |> sum()
end

get_num = fn char ->
    for {^char <> num, value} <- final_wires do
        {String.to_integer(num), value}
    end
    |> sort_by(fn {n,_} -> n end)
    |> map(fn {_,v} -> v end)
    |> then(num_from_bits)
end

IO.inspect(get_num.("x"))
IO.inspect(get_num.("y"))
IO.inspect(get_num.("z"))
