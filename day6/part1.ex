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
import String, only: [split: 2, split: 3, to_integer: 1]

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

{obstacles_by_row, obstacles_by_col} = coordinates
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

{all_tiles, _, _} =
AoC.iterate_until(
    {[], initial_position, initial_direction},
    fn {tiles, position, direction} ->
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
                        c <- c1..c2 do
                            {r,c}
                    end
        {ob != nil, {new_tiles ++ tiles, new_position, new_direction}}
    end
)

all_tiles
|> uniq()
|> count()
|> IO.inspect()
