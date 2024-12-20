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

import Enum

# read input into map of coordinates
%{"S" => [start_position],
  "E" => [end_position],
  "." => empty_tiles,
  "#" => wall_tiles
} = "day20/input.txt"
    |> File.read!()
    |> AoC.grid_to_coords()
    |> group_by(fn {_,c} -> c end, fn {pos,_} -> pos end)

row_max = map(wall_tiles, fn {r,_} -> r end) |> max()
col_max = map(wall_tiles, fn {_,c} -> c end) |> max()

# figure out the path (as a map of coordinates with the time it takes to get there)
%{visited: all_visited, unvisited: all_unvisited} = 
AoC.iterate_until(
    %{visited: %{}, unvisited: MapSet.new([end_position | empty_tiles]), position: start_position, step: 0},
    fn state ->
        {r,c} = state.position
        neighbours =
            [{r+1,c},{r-1,c},{r,c+1},{r,c-1}]
            |> filter(fn pos -> member?(state.unvisited, pos) end)
        
        case neighbours do
            [new_pos] ->
                new_visited = Map.put(state.visited, new_pos, state.step + 1)
                new_unvisited = MapSet.delete(state.unvisited, new_pos)
                new_state = %{visited: new_visited, unvisited: new_unvisited, position: new_pos, step: state.step + 1}
                if new_pos == end_position do
                    {:stop, new_state}
                else
                    {:iterate, new_state}
                end
            [] -> raise "found no paths from #{state.position}"
            _ -> raise "found multiple paths from #{state.position} to #{inspect(neighbours)}"
        end
    end
)

# print out the grid if needed
(fn ->
    for r <- 0..row_max do
        for c <- 0..col_max do
            pos = {r,c}
            cond do
                pos == start_position       -> IO.write(IO.ANSI.color(2) <> "S" <> IO.ANSI.reset())
                pos == end_position         -> IO.write(IO.ANSI.color(2) <> "E" <> IO.ANSI.reset())
                member?(all_visited, pos)   -> IO.write(IO.ANSI.color(3) <> "." <> IO.ANSI.reset())
                member?(all_unvisited, pos) -> IO.write(IO.ANSI.color(1) <> "." <> IO.ANSI.reset())
                member?(wall_tiles, pos)    -> IO.write(IO.ANSI.color(8) <> "#" <> IO.ANSI.reset())
            end
        end
        IO.write("\r\n")
    end
end)#.()

shortcut_offsets =
    for cheat <- 2..20,
        r <- -cheat..cheat,
        c <- (if abs(r) == cheat do [0] else [-(cheat - abs(r)), cheat - abs(r)] end)
        do
        {r,c,cheat}
    end

# solve this thing
for {{r,c}, cost} <- Map.put(all_visited, start_position, 0),
    {dr,dc, cheat_cost} <- shortcut_offsets,
    shortcut = {r + dr, c + dc},
    Map.has_key?(all_visited, shortcut),
    saving = all_visited[shortcut] - (cost + cheat_cost),
    saving > 0
    do
    {{r,c}, shortcut, saving}
end
|> group_by(fn {_,_,saving} -> saving end)
|> AoC.map_map(&count/1)
|> filter(fn {savings,_} -> savings >= 100 end)
|> map(fn {_,c} -> c end)
|> sum()
|> IO.inspect()

