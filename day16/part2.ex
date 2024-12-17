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
            {ch, c} <- rw
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

%{"S" => [start_position],
  "E" => [end_position],
  "." => empty_tiles,
  "#" => _
} = "day16/input.txt"
    |> File.read!()
    |> AoC.grid_to_coords()
    |> group_by(fn {_,c} -> c end, fn {pos,_} -> pos end)

_row_max = map(empty_tiles, fn {r,_} -> r end) |> max() |> then(& &1 + 1)
_col_max = map(empty_tiles, fn {_,c} -> c end) |> max() |> then(& &1 + 1)

AoC.iterate_until(
    %{live_routes: [[{start_position, :rt, 0}]],
      tile_routes: map([end_position | empty_tiles], fn pos ->
        {pos, %{up: {:infinity, []},
                rt: {:infinity, []},
                dn: {:infinity, []},
                lf: {:infinity, []}}}
        end) |> into(%{})
    },
    fn state ->
        new_live_routes =
            for [{{r,c},dir,cost} | _] = route <- state.live_routes,
                {neighbour, new_dir} <- [
                    {{r-1,c}, :up},
                    {{r,c+1}, :rt},
                    {{r+1,c}, :dn},
                    {{r,c-1}, :lf}],
                (case dir do
                    :up -> new_dir != :dn
                    :rt -> new_dir != :lf
                    :dn -> new_dir != :up
                    :lf -> new_dir != :rt
                end),
                new_cost = (if new_dir == dir do 1 else 1001 end + cost),
                Map.has_key?(state.tile_routes, neighbour),
                {existing_cost, _} = state.tile_routes[neighbour][new_dir],
                new_cost <= existing_cost
                do
                [{neighbour, new_dir, new_cost} | route]
            end
        
        new_tile_routes =
            reduce(
                new_live_routes,
                state.tile_routes,
                fn [{pos, dir, cost} | _] = route, tile_routes ->
                    update_in(tile_routes[pos][dir], fn {existing_cost, existing_routes} ->
                        if cost < existing_cost do
                            {cost, [route]}
                        else
                            {existing_cost, [route | existing_routes]}
                        end
                    end)
                end
            )
        
        if empty?(new_live_routes) do
            {:stop, new_tile_routes}
        else
            {:iterate, %{live_routes: new_live_routes, tile_routes: new_tile_routes}}
        end
    end
)[end_position]
|> min_by(fn {_,{c,_}} -> c end)
|> then(fn {_,{_,r}} -> r end)
|> concat()
|> map(fn {pos,_,_} -> pos end)
|> uniq()
|> count()
|> IO.inspect()
