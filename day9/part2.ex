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

_expand_disk_structure = fn disk_map ->
    for {n, i} <- with_index(disk_map),
        _ <- 1..n//1 do
            if rem(i,2) == 0 do
                to_string(div(i,2))
            else
                "."
            end
    end
    |> List.foldr("", &<>/2)
end

[filled, empty] =
    "day9/input.txt" 
    |> File.read!()
    |> String.split("", trim: true)
    |> map(&String.to_integer/1)
    #|> tap(fn x -> expand_disk_structure.(x) |> IO.puts() end)
    |> with_index()
    |> scan({nil, nil, nil, 0}, fn {n, i}, {_, _, _, acc} -> {n, div(i,2), acc, acc + n} end)
    |> map(fn {a,b,c,_} -> {a,b,c} end)
    |> chunk_every(2,2, [nil])
    |> AoC.transpose()

empty_spaces =
    empty
    |> filter(fn nil -> false; _ -> true end)
    |> group_by(fn {size,_,_} -> size end)

_print_state = fn {filled, spaces} ->
    IO.write("filled = ")
    IO.inspect(filled)
    IO.write("empty = ")
    map(spaces, fn {i, es} -> {i, hd(es)} end)
    |> into(%{})
    |> IO.inspect()
    {filled, spaces}
end

# IO.puts("[initial state]")
# print_state.({reverse(filled), empty_spaces})
# IO.puts("[iterations]")

reduce(
    reverse(filled),
    {[], empty_spaces},
    fn {fsize, fid, findex}, {out, spaces} ->
        # find new location for file
        # either move it to a large enough space to the left
        # or keep it in the same place
        {size_found, new_index} =
        for s <- fsize..9,
            [{_,_,eindex} | _] <- [spaces[s]],
            eindex < findex
            do {s, eindex}
        end |> then(fn
            [] -> {nil, findex}
            xs -> min_by(xs, fn {_, i} -> i end)
            end)

        # update the map of spaces if the file was moved into one
        new_spaces = if size_found == nil do
            spaces
        else
            removed = Map.update!(spaces, size_found, fn [_ | es] -> es end)
            if size_found > fsize do
                new_esize = size_found - fsize
                new_eindex = new_index + fsize
                new_e = {new_esize, nil, new_eindex}
                Map.update(removed, new_esize, [new_e], fn es ->
                    AoC.insert_ordered(es, new_e, fn {_,_,i} -> i end)
                end)
            else
                removed
            end
        end

        {[{fsize, fid, new_index} | out], new_spaces} #|> print_state.()
    end
)
|> elem(0)
|> map(fn {size, id, index} ->
    max_index = index + size - 1
    min_index = Kernel.max(index - 1, 0)
    (div(max_index * (max_index + 1), 2) - div(min_index * (min_index + 1), 2)) * id
end)
|> sum()
|> IO.inspect()
