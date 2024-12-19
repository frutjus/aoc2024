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

    @spec iterate_until(state, (state -> {boolean, state | term()})) :: state when state: var
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

import Enum

[patterns_str, designs_str] =
    "day19/input.txt"
    |> File.read!()
    |> String.split("\r\n\r\n")

patterns =
    patterns_str
    |> String.split(", ")

designs =
    designs_str
    |> String.split("\r\n")

defmodule Day19 do
    def evaluate_design("", _, memo) do {1, memo} end
    def evaluate_design(design, patterns, memo) do
        if Map.has_key?(memo, design) do
            #IO.puts(IO.ANSI.color(3) <> "remembered #{design} = #{memo[design]}" <> IO.ANSI.reset())
            {memo[design], memo}
        else
            parses =
                for pattern <- patterns,
                    ^pattern <> rest <- [design]
                    do
                    {pattern, rest}
                end
            
            reduce(
                parses,
                {0, memo},
                fn {_, rest}, {possibilities, acc_memo} ->
                    {subpossibilities, acc_memo2} = evaluate_design(rest, patterns, acc_memo)
                    add_possibilities = possibilities + subpossibilities
                    update_memo = Map.put(acc_memo2, design, add_possibilities)
                    {add_possibilities, update_memo}
                end
            )
            #|> tap(fn {result, _} -> IO.puts(IO.ANSI.color(2) <> "figured out #{design} = #{result}" <> IO.ANSI.reset()) end)
        end
    end
end

designs
|> reduce(
    {[], %{}},
    fn design, {results, memo} ->
    {new_result, new_memo} = Day19.evaluate_design(design, patterns, memo)
    #IO.puts(IO.ANSI.color(4) <> "finally we know that #{design} = #{new_result}" <> IO.ANSI.reset())
    #IO.gets("")
    {results ++ [new_result], new_memo}
end)
|> elem(0)
|> filter(& &1 > 0)
|> count()
|> IO.inspect()