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

{start_position, tiles} =
    "day16/input.txt"
    |> File.read!()
    |> AoC.grid_to_coords()
    |> filter(fn {_,c} -> c != "#" end)
    |> map(fn {cd,c} -> case c do
        "." -> {cd,:path}
        "S" -> {cd,:start}
        "E" -> {cd,:end}
        end
    end)
    |> split_with(fn {_,t} -> t == :start end)
    |> then(fn {[{start,:start}], tiles} ->
        {start, into(tiles, %{})}
    end)

AoC.iterate_until(
    {[{start_position, :rt, 0}], tiles},
    fn {[{{r,c}, dir, cost} | positions], unvisited} ->
        new_positions =
        for {neighbour, new_dir} <- [
                {{r-1,c}, :up},
                {{r,c+1}, :rt},
                {{r+1,c}, :dn},
                {{r,c-1}, :lf}],
            Map.has_key?(unvisited, neighbour)
            do
            move_cost = if new_dir == dir do 1 else 1001 end
            {neighbour, new_dir, cost + move_cost}
        end
        
        new_unvisited = Map.drop(unvisited, map(new_positions, fn {pos,_,_} -> pos end))

        case split_with(new_positions, fn {pos,_,_} -> tiles[pos] == :end end) do
            {[{_,_,c}], _} -> {:stop, c}
            {[], _} ->
                all_new_positions = reduce(
                    new_positions,
                    positions,
                    fn p, ps ->
                        AoC.insert_ordered(ps, p, fn {_,_,c} -> c end)
                    end
                )
                {:iterate, {all_new_positions, new_unvisited}}
        end
    end
)
|> IO.inspect()
