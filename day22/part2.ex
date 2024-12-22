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

seeds =
    "day22/input.txt"
    |> File.read!()
    |> String.split("\r\n")
    |> map(&String.to_integer/1)

next_pseudorandom_number = fn previous_number ->
    step = fn n, f -> rem(Bitwise.bxor(n, f.(n)), 16777216) end

    previous_number
    |> step.(& &1 * 64)
    |> step.(& div(&1, 32))
    |> step.(& &1 * 2048)
end

map(seeds, fn seed ->
    Stream.iterate(seed, next_pseudorandom_number)
    |> Stream.map(& rem(&1,10))
    |> Stream.scan(
        {{nil,nil,nil,nil},nil},
        fn n, {{_,d2,d3,d4},m} ->
            diff =
                if m == nil do
                    nil
                else
                    n - m
                end

            {{d2,d3,d4,diff},n}
        end
    )
    |> Stream.drop(1) # drop the seed value
    |> Stream.take(2000) # take the 2000 values to be considered
    |> Stream.drop(3) # drop the first 3 values since they do not have four preceding changes
    |> group_by(fn {diffs,_} -> diffs end, fn {_,value} -> value end)
    |> AoC.map_map(&hd/1)
end)
|> reduce(
    %{},
    fn item, acc ->
        Map.merge(item, acc, fn _, val1, val2 -> val1 + val2 end)
    end
)
|> max_by(fn {_, val} -> val end)
|> IO.inspect()
