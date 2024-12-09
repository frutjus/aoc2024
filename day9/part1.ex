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

_expand_disk_structure = fn disk_map ->
    for {n, i} <- with_index(disk_map),
        _ <- 1..n//1 do
            if rem(i,2) == 0 do
                to_string(div(i,2))
            else
                "."
            end
    end
    |> reduce("", &<>/2)
    |> String.reverse()
end

[filled, empty] =
    "day9/input.txt" 
    |> File.read!()
    |> String.split("", trim: true)
    |> map(&String.to_integer/1)
    |> with_index()
    |> scan({nil, nil, nil, 0}, fn {n, i}, {_, _, _, acc} -> {n, div(i,2), acc, acc + n} end)
    |> map(fn {a,b,c,_} -> {a,b,c} end)
    |> chunk_every(2,2, [nil])
    |> AoC.transpose()

total_filled_blocks =
    filled
    |> map(fn {size, _, _} -> size end)
    |> sum

moved = AoC.iterate_until(
    {drop(empty, -1), reverse(filled), []}, fn
    {[], _, _} = done -> {false, done}
    {_, [], _} = done -> {false, done}
    {[{esize,eid,eindex} | es], [{fsize,fid,findex} | fs], xs} -> {true,
        cond do
        esize < fsize ->
            {es, [{fsize - esize, fid, findex + esize} | fs], [{esize, fid, eindex} | xs]}
        esize > fsize ->
            {[{esize - fsize, eid, eindex + fsize} | es], fs, [{fsize, fid, eindex} | xs]}
        esize == fsize ->
            {es, fs, [{esize, fid, eindex} | xs]}
        end}
    end
) |> then(fn {_, _, xs} -> xs end)

for {size, id, index} <- filled ++ moved,
    index <= total_filled_blocks do
    max_index = Kernel.min(index + size - 1, total_filled_blocks - 1)
    min_index = Kernel.max(index - 1, 0)
    (div(max_index * (max_index + 1), 2) - div(min_index * (min_index + 1), 2)) * id
end
|> sum()
|> IO.inspect()
