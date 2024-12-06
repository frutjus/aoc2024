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
end

import Enum, except: [split: 2]
import String, only: [split: 2, split: 3]

grid = "day6/input.txt"
    |> File.read!()
    |> split("\r\n")
    |> map(fn ln -> split(ln, "", trim: true) end)

row_max = length(grid) - 1
col_max = length(hd(grid)) - 1

coordinates =
for {row, r} <- with_index(grid),
    {val, c} <- with_index(row),
    val != "." do
        {r,c,val}
end

[initial_position] = for {r,c,"^"} <- coordinates, do: {r,c}
initial_direction = :up

run = fn coords ->
    {obstacles_by_row, obstacles_by_col} = coords
        |> filter(fn {_,_,"^"} -> false
                    _ -> true end)
        |> reduce(
            {%{},%{}},
            fn {r,c,_}, {row_obs,col_obs} ->
                { Map.update(row_obs, r, [c], fn ls -> [c | ls] end),
                Map.update(col_obs, c, [r], fn ls -> [r | ls] end)
                }
            end
        )

    next_obstacle = fn {r,c}, direction ->
        case direction do
            :up ->
                Map.get(obstacles_by_col, c, [])
                |> filter(& &1 < r)
                |> max(&>=/2, fn -> nil end)
            :right ->
                Map.get(obstacles_by_row, r, [])
                |> filter(& &1 > c)
                |> min(&<=/2, fn -> nil end)
            :down ->
                Map.get(obstacles_by_col, c, [])
                |> filter(& &1 > r)
                |> min(&<=/2, fn -> nil end)
            :left ->
                Map.get(obstacles_by_row, r, [])
                |> filter(& &1 < c)
                |> max(&>=/2, fn -> nil end)
        end
    end

    AoC.iterate_until(
        {%{}, initial_position, initial_direction, 0, false},
        fn {tiles, position, direction, step, false} ->
            ob = next_obstacle.(position, direction)
            {r1,c1} = position
            new_position = case direction do
                :up    -> {if ob == nil do 0 else ob + 1 end, c1}
                :right -> {r1, if ob == nil do col_max else ob - 1 end}
                :down  -> {if ob == nil do row_max else ob - 1 end, c1}
                :left  -> {r1, if ob == nil do 0 else ob + 1 end}
            end
            new_direction = case direction do
                :up    -> :right
                :right -> :down
                :down  -> :left
                :left  -> :up
            end
            {r2,c2} = new_position
            new_tiles = for r <- r1..r2,
                            c <- c1..c2,
                            into: %{} do
                                {{r,c}, [{{direction, if {r,c} == new_position do new_direction else direction end}, step}]}
                        end
            merged_tiles = Map.merge(tiles, new_tiles, fn _, v1, v2 -> v1 ++ v2 end)
            loop? = Map.get(tiles, new_position, [])
                |> filter(fn {{_,dir},_} -> dir == new_direction end)
                |> empty?()
                |> then(&not/1)
            {ob != nil and not loop?, {merged_tiles, new_position, new_direction, step + 1, loop?}}
        end
    )
end

{all_tiles, _, _, _, _} = run.(coordinates)

#print out a nice terminal visualisation
fn ->
    0..row_max
    |> each(fn r ->
        0..col_max
        |> each(fn c ->
            has_obstacle = member?(coordinates, {r,c,"#"})
            {dir, step} = Map.get(all_tiles, {r,c}, []) |> List.first({nil, 0})
            move = case dir do
                    {:up,:up}       -> "┃"
                    {:right,:right} -> "━"
                    {:down,:down}   -> "┇"
                    {:left,:left}   -> "┅"
                    {:up,:right}    -> "┏"
                    {:right,:down}  -> "┓"
                    {:down,:left}   -> "┛"
                    {:left,:up}     -> "┗"
                    nil             -> " "
            end |> then(fn c -> IO.ANSI.color(div(step,4)+1) <> c <> IO.ANSI.reset() end)
            IO.write(if has_obstacle do "▉" else move end)
        end)
        IO.write("\n")
    end)
    IO.write("\n")
end#.()

# attempt 1
# does not find all the possibilities :(
for {{r1,c1},visits} <- all_tiles,
    {{dir1,dir1},step1} <- visits,
    turn = (case dir1 do
        :up    -> {r1,c1+1}
        :right -> {r1+1,c1}
        :down  -> {r1,c1-1}
        :left  -> {r1-1,c1}
    end),
    {{dir2,_},step2} <- Map.get(all_tiles, turn, []),
    dir2 == (case dir1 do
        :up    -> :right
        :right -> :down
        :down  -> :left
        :left  -> :up
    end),
    step2 < step1,
    new_obs = (case dir1 do
        :up    -> {r1-1,c1}
        :right -> {r1,c1+1}
        :down  -> {r1+1,c1}
        :left  -> {r1,c1-1}
    end),
    Map.get(all_tiles, new_obs, [])
    |> filter(fn {_,step3} -> step3 < step2 end)
    |> empty?()
    do
        new_obs
end
|> count()
#|> IO.inspect()

# attempt 2
# this one works :)
for {{r,c},_} <- all_tiles,
    coords = [{r,c,"#"} | coordinates],
    {_,_,_,_,loop?} = run.(coords),
    loop?
    do
        IO.inspect({r,c})
        {r,c}
end
|> count()
|> IO.inspect()
