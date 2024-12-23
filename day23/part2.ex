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

connections =
    "day23/input.txt"
    |> File.read!()
    |> String.split("\r\n")
    |> map(fn ln ->
        String.split(ln, "-")
        |> MapSet.new()
    end)
    |> MapSet.new()

connections_by_computer =
    reduce(
        connections,
        %{},
        fn item, acc ->
            [computer1, computer2] = MapSet.to_list(item)
            acc
            |> Map.update(computer1, MapSet.new([computer2]), fn pcs -> MapSet.put(pcs, computer2) end)
            |> Map.update(computer2, MapSet.new([computer1]), fn pcs -> MapSet.put(pcs, computer1) end)
        end
    )

computers = Map.keys(connections_by_computer)

has_connection? = fn pc1, pc2 -> MapSet.member?(connections, MapSet.new([pc1,pc2])) end

reduce(
    computers,
    computers |> map(& MapSet.new([&1])),
    fn pc, groups ->
        for group <- groups do
            if all?(group, fn conn -> has_connection?.(pc, conn) end) do
                MapSet.put(group, pc)
            else
                group
            end
        end
    end
)
|> max_by(&MapSet.size/1)
|> join(",")
|> IO.inspect()
