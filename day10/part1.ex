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
end

import Enum, except: [split: 2]

heightmap =
for {row, r} <-
        "day10/input.txt" 
        |> File.read!()
        |> String.split("\r\n")
        |> with_index(),
    {digit, c} <-
        row
        |> String.split("", trim: true)
        |> with_index(),
    into: %{}
    do
    {{r,c},String.to_integer(digit)}
end

trailheads =
for {pos, 0} <- heightmap
    do
    pos
end

for trailhead <- trailheads do
    AoC.iterate_until(
        {[trailhead], 0},
        fn {positions, 9}    -> {:stop, positions}
           {positions, step} ->
            new_positions =
            for {r,c} <- positions,
                neighbour <- [
                    {r-1,c},
                    {r,c+1},
                    {r+1,c},
                    {r,c-1}],
                Map.get(heightmap, neighbour, nil) == step + 1,
                uniq: true
                do
                neighbour
            end
            {:iterate, {new_positions, step + 1}}
        end
    ) |> count()
end
|> sum()
|> IO.inspect()