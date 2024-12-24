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

import Enum, except: [max: 2, min: 2]

# Finally, an excuse to use an overcomplicated parsing library!!

import Parse, only: [bind: 2, bind_: 2, just: 1, alt: 2]

parse_wire_name =
    bind Parse.count(3, Parse.alphanum()), fn cs ->
    just join(cs)
    end

parse_initial_wire_value =
    bind parse_wire_name, fn name ->
    bind_ Parse.string_literal(": "),
    (bind Parse.digit(), fn _digit ->
    just {name, name}
    end) end

parse_initial_wire_values = Parse.endBy(parse_initial_wire_value, Parse.newline())

op = fn a ->
    fn l,r -> {a,min(l,r),max(l,r)} end
end

parse_and =
    bind_ Parse.string_literal("AND"),
    just op.(:and)

parse_or =
    bind_ Parse.string_literal("OR"),
    just op.(:or)

parse_xor =
    bind_ Parse.string_literal("XOR"),
    just op.(:xor)

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
    "day24/input.txt"
    |> File.read!()
    |> Parse.run(parse_all)

# apply fixes to the swopped wires

swop = fn gs, w1, w2 ->
    map(gs, fn {in1, in2, f, out} ->
        new_out = case out do
            ^w1 -> w2
            ^w2 -> w1
            _ -> out
        end
        {in1, in2, f, new_out}
    end)
end

fixed_gates =
    gates
    |> swop.("cnk", "qwf")
    |> swop.("z14", "vhm")
    |> swop.("z27", "mps")
    |> swop.("z39", "msq")

# get the formula for each wire in a nice structure

relationships =
    map(
        fixed_gates,
        fn {in1, in2, f, out} -> {out, f.(in1,in2)} end
    )
    |> into(%{})

# build a tree of the full formula for each wire (as a function of the x and y wires)

final_wires =
    AoC.iterate_until(
        {into(wires, %{}), fixed_gates},
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

## now we set up the correct formula to use for each wire
# first see what variables we need for each z from 0 to 45

vars_for = fn
    0 -> ["z"]
    1 -> ["carry", "add", "z"]
    45 -> ["carrybelow", "carry", "z"]
    _ -> ["carrybelow", "carry", "anycarry", "add", "z"]
end

# then determine the formula for each variable, which depends on the index of that variable

label = fn name, index -> name <> String.pad_leading(to_string(index), 2, "0") end

formula_for = fn
    "carry", i -> {:and, label.("x", i-1), label.("y", i-1)}

    "add", i -> {:xor, label.("x", i), label.("y", i)}

    "carrybelow", 2 -> {:and, "carry01", "add01"}
    "carrybelow", i -> {:and, label.("anycarry", i-1), label.("add", i-1)}

    "anycarry", i -> {:or, label.("carrybelow", i), label.("carry", i)}

    "z", 0 -> {:xor, "x00", "y00"}
    "z", 1 -> {:xor, "carry01", "add01"}
    "z", 45 -> {:or, "carrybelow45", "carry45"}
    "z", i -> {:xor, label.("anycarry", i), label.("add", i)}
end

# set up the ultimate formula for each wire
# this structure "expected_wires" is comparable to the "final_wires" above
# except that that used the actual wire names ("pqj" etc) and contains some errors

expected_wires =
    reduce(
        0..45,
        into(wires, %{}),
        fn i, vars ->
            reduce(
                vars_for.(i),
                vars,
                fn var, vars ->
                    varname = label.(var, i)
                    {op, in1, in2} = formula_for.(var, i)
                    Map.put(vars, varname, {op, Map.fetch!(vars, in1), Map.fetch!(vars, in2)})
                end
            )
        end
    )

# the expected structure is a map from wire name to formula tree
# let's also create a map from formula to wire, for reasons

expected_by_ast =
    expected_wires
    |> into([])
    |> map(fn {key,val} -> {val,key} end)
    |> into(%{})

rename = fn wire ->
    Map.get(expected_by_ast, final_wires[wire], wire)
end

# compare the expected and actual structures by formula tree
# any wire that has a formula that doesn't match an expected formula will be listed here
# and will allow us to deduce where the errors are

final_wires
|> filter(fn {wire,ast} ->
    not Map.has_key?(expected_by_ast,ast) or
    (String.starts_with?(wire, "z") and wire != expected_by_ast[ast])
end)
|> filter(fn {wire,_} ->
    {_, in1, in2} = relationships[wire]
    Map.has_key?(expected_by_ast, final_wires[in1]) and
    Map.has_key?(expected_by_ast, final_wires[in2])
end)
|> map(fn {wire,_} ->
    {op, in1, in2} = relationships[wire]
    IO.puts("#{wire}: #{op} #{in1} #{in2} | #{rename.(in1)} #{rename.(in2)}")
end)

## Problems
# carry10 ~ add09 : cnk ~ qwf
# z14 ~ carry15 : z14 ~ vhm
# z27 ~ anycarry28 : z27 ~ mps
# z39 ~ carrybelow40 : z39 ~ msq

# okay... time for the final answer

["cnk", "qwf", "z14", "vhm", "z27", "mps", "z39", "msq"]
|> sort()
|> join(",")
|> IO.puts()

# the rest is miscellaneous playing around

# z00: (y00) XOR (x00)
# z01: ((x00) AND (y00)) XOR ((x01) XOR (y01))
# z02: ((x02) XOR (y02)) XOR (((y01) AND (x01)) OR (((x00) AND (y00)) AND ((x01) XOR (y01))))
# z03: ((x03) XOR {y03}) XOR {((((y01) AND {x01}) OR {((x00) AND {y00}) AND {(x01) XOR {y01}}}) AND {(x02) XOR {y02}}) OR {(x02) AND {y02}}}

# z00 = {:xor, "x00", "y00"}

# carry01 = {:and, "x00", "y00"}
# add01 = {:xor, "x01", "y01"}
# z01 = {:xor, carry01, add01}

# carrybelow02 = {:and, carry01, add01}
# carry02 = {:and, "x01", "y01"}
# anycarry02 = {:or, carrybelow02, carry02}
# add02 = {:xor, "x02", "y02"}
# z02 = {:xor, anycarry02, add02}

# carrybelow03 = {:and, anycarry02, add02}
# carry03 = {:and, "x02", "y02"}
# anycarry03 = {:or, carrybelow03, carry03}
# add03 = {:xor, "x03", "y03"}
# z03 = {:xor, anycarry03, add03}

# carrybelow04 = {:and, anycarry03, add03}
# carry04 = {:and, "x03", "y03"}
# anycarry04 = {:or, carrybelow04, carry04}
# add04 = {:xor, "x04", "y04"}
# z04 = {:xor, anycarry04, add04}
