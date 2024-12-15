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

[grid_str, moves_str] =
    "day15/input.txt"
    |> File.read!()
    |> String.split("\r\n\r\n")

{initial_position, initial_tiles} =
    AoC.grid_to_coords(grid_str)
    |> reject(fn {_, c} -> c == "." end)
    |> split_with(fn {_, c} -> c == "@" end)
    |> then(fn {[{{r,c}, "@"}], tiles} -> {{r,c*2},
        flat_map(tiles, fn {{r,c}, ch} ->
            case ch do
                "O" -> [{{r,c*2}, :box_l}, {{r,c*2+1}, :box_r}]
                "#" -> [{{r,c*2}, :wall},  {{r,c*2+1}, :wall}]
            end
        end)
        |> into(%{})
    } end)

row_max = map(initial_tiles, fn {{r,_},_} -> r end) |> max()
col_max = map(initial_tiles, fn {{_,c},_} -> c end) |> max()

moves =
    String.replace(moves_str, "\r\n", "")
    |> String.split("", [trim: true])
    |> map(fn
        "^" -> :up
        "v" -> :dn
        "<" -> :lf
        ">" -> :rt
    end)

defmodule Day15 do
    def simulate_step(move, {_, {r,c} = position, tiles}) do
        {r1,c1} = new_position = case move do
            :up -> {r-1,c}
            :dn -> {r+1,c}
            :lf -> {r,c-1}
            :rt -> {r,c+1}
        end
        case tiles[new_position] do
            nil -> {:moved, new_position, tiles}
            :wall -> {:blocked, position, tiles}
            box -> if move in [:lf,:rt] do
                case simulate_step(move, {nil, new_position, tiles}) do
                    {:moved, new_box_position, altered_tiles} ->
                        final_tiles = AoC.map_move(altered_tiles, new_position, new_box_position)
                        {:moved, new_position, final_tiles}
                    {:blocked, _, _} -> {:blocked, position, tiles}
                end
            else
                other_new_position = case box do
                    :box_l -> {r1,c1+1}
                    :box_r -> {r1,c1-1}
                end
                case simulate_step(move, {nil, new_position, tiles}) do
                    {:moved, new_box_position, altered_tiles} ->
                        case simulate_step(move, {nil, other_new_position, altered_tiles}) do
                            {:moved, other_new_box_position, altered_tiles2} ->
                                final_tiles = AoC.map_move(altered_tiles2, new_position, new_box_position)
                                    |> AoC.map_move(other_new_position, other_new_box_position)
                                {:moved, new_position, final_tiles}
                            {:blocked, _, _} -> {:blocked, position, tiles}
                        end
                    {:blocked, _, _} -> {:blocked, position, tiles}
                end
            end
        end
    end
end

display_state = fn {_, position, tiles} = state ->
    all_tiles = Map.put(tiles, position, :robot)
    for r <- 0..row_max do
        for c <- 0..col_max do
            IO.write(case all_tiles[{r,c}] do
                nil    -> IO.ANSI.color(0) <> "." <> IO.ANSI.reset()
                :wall  -> IO.ANSI.color(7) <> "#" <> IO.ANSI.reset()
                :box_l -> IO.ANSI.color(2) <> "[" <> IO.ANSI.reset()
                :box_r -> IO.ANSI.color(2) <> "]" <> IO.ANSI.reset()
                :robot -> IO.ANSI.color(4) <> "@" <> IO.ANSI.reset()
            end)
        end
        IO.write("\r\n")
    end
    state
end

sum_GPS_coordinates = fn {_, _, tiles} ->
    tiles
    |> filter(fn {_,t} -> t == :box_l end)
    |> map(fn {{r,c},_} -> r*100 + c end)
    |> sum()
end

moves
|> reduce(
    {nil, initial_position, initial_tiles},
    &Day15.simulate_step/2
)
|> display_state.()
|> sum_GPS_coordinates.()
|> IO.inspect()
