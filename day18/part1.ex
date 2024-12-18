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

# parameters

mode = :actual
{file_path, x_max, y_max, bytes} =
    case mode do
        :sample -> {"day18/sample.txt", 6, 6, 12}
        :actual -> {"day18/input.txt", 70, 70, 1024}
    end

start_position = {0,0}
end_position = {x_max,y_max}

# read input

corrupted =
    file_path
    |> File.read!()
    |> String.split("\r\n")
    |> map(fn ln ->
        String.split(ln, ",")
        |> map(&String.to_integer/1)
        |> List.to_tuple()
    end)
    |> take(bytes)
    |> into(MapSet.new())

# find the path

AoC.iterate_until(
    %{live_routes: [{[start_position], 0}],
      tile_routes: %{start_position => {[start_position], 0}},
      step: 0
    },
    fn state ->
        new_live_routes =
            for {[{x,y} | _] = route, cost} <- state.live_routes,
                {x1,y1} = neighbour <- [
                    {x-1,y},
                    {x,y+1},
                    {x+1,y},
                    {x,y-1}],
                x1 >= 0 and x1 <= x_max,
                y1 >= 0 and y1 <= y_max,
                not member?(corrupted, neighbour),
                not Map.has_key?(state.tile_routes, neighbour),
                new_cost = cost + 1
                do
                {[neighbour | route], new_cost}
            end
            |> uniq_by(fn {[pos| _], _} -> pos end)
        
        new_tile_routes =
            reduce(
                new_live_routes,
                state.tile_routes,
                fn {[pos | _] = route, cost}, tile_routes ->
                    Map.put(tile_routes, pos, {route, cost})
                end
            )
        
        # print obstacles on grid
        # for y <- 0..y_max do
        #     for x <- 0..x_max do
        #         ch =
        #         if Map.has_key?(new_tile_routes, {x,y}) do
        #             "O"
        #         else if member?(corrupted, {x,y}) do
        #             "#"
        #         else
        #             "."
        #         end
        #         end
        #         IO.write(ch)
        #     end
        #     IO.write("\r\n")
        # end
        # IO.gets("")
        
        if empty?(new_live_routes) do
            IO.puts("took #{state.step} steps")
            {:stop, new_tile_routes}
        else
            {:iterate, %{live_routes: new_live_routes, tile_routes: new_tile_routes, step: state.step + count(new_live_routes)}}
        end
    end
)[end_position]
|> elem(1)
|> IO.inspect()

