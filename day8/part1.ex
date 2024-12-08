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

    @spec iterate_until(state, (state -> {boolean, state})) :: state when state: var
    def iterate_until(state, function) do
        case function.(state) do
            {true, newstate} -> iterate_until(newstate, function)
            {false, newstate} -> newstate
        end
    end

    def pairs(xs) do
        for {a, ai} <- Enum.with_index(xs),
            {b, bi} <- Enum.with_index(xs),
            ai != bi do
                {a,b}
        end
    end
end

import Enum, except: [split: 2]
import String, only: [split: 2, split: 3]

grid = "day8/input.txt" 
    |> File.read!()
    |> split("\r\n")
    |> map(& split(&1, "", trim: true))

row_max = length(grid) - 1
col_max = length(hd(grid)) - 1

for {row, r} <- grid |> with_index(),
    {char, c} <- row |> with_index(),
    char != "." do
    {r,c,char}
end
|> group_by(fn {_,_,c} -> c end)
|> map(fn {_,ls} ->
    for {{r1,c1,_},{r2,c2,_}} <- AoC.pairs(ls),
        {r3,c3} = {r2 + (r2-r1), c2 + (c2-c1)},
        0 <= r3 and r3 <= row_max,
        0 <= c3 and c3 <= col_max,
        uniq: true do
            {r3,c3}
    end
end)
|> concat()
|> uniq()
|> count()
|> IO.inspect()

