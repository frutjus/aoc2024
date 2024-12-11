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
end

import Enum, except: [split: 2]

initial_stones =
    "day11/input.txt" 
    |> File.read!()
    |> String.split(" ")
    |> map(&String.to_integer/1)
    |> group_by(&Function.identity/1)
    |> map(fn {x, xs} -> {x, count(xs)} end)

change_stone = fn
    0 -> [1]
    n ->
        digits = to_string(n)
        num_digits = String.length(digits)
        if rem(num_digits, 2) == 0 do
            {l,r} = String.split_at(digits, div(num_digits, 2))
            [String.to_integer(l), String.to_integer(r)]
        else
            [n * 2024]
        end
end

get_count = fn stones ->
    map(stones, fn {_, n} -> n end)
    |> sum()
end

reduce(
    1..75,
    initial_stones,
    fn i, stones ->
        for {x1, n} <- stones,
            x2 <- change_stone.(x1)
            do
            {x2, n}
        end
        |> group_by(fn {x, _} -> x end, fn {_, n} -> n end)
        |> map(fn {x, ns} -> {x, sum(ns)} end)
        |> tap(fn ss -> 
            IO.puts("#{i}: #{get_count.(ss)}")
            #IO.puts(inspect(ss))
        end)
    end
)
|> get_count.()
|> IO.inspect()
