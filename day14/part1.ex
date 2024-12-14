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
end

import Enum

parser = ~r{p=(\d+),(\d+) v=(-?\d+),(-?\d+)}

mode = :actual
{file, x_max, y_max} = case mode do
    :sample -> {"day14/sample.txt", 11,  7  }
    :actual -> {"day14/input.txt",  101, 103}
end

steps = 100

x_mid = div(x_max, 2)
y_mid = div(y_max, 2)

file
|> File.read!()
|> then(fn str -> Regex.scan(parser, str, [capture: :all_but_first]) end)
|> map(fn vals ->
    map(vals, &String.to_integer/1)
    |> then(fn [x,y,dx,dy] ->
        {AoC.mod(x + dx*steps, x_max), AoC.mod(y + dy*steps, y_max)}
    end)
end)
|> tap(fn robots ->
    IO.puts(count(robots) |> to_string())
    map(0..y_max-1, fn y ->
        map(0..x_max-1, fn x ->
            c = filter(robots, & &1 == {x,y}) |> count() |> to_string()
            IO.write(if c == "0" do "." else c end)
        end)
        IO.write("\r\n")
    end)
end)
|> reject(fn {x,y} -> x == x_mid or y == y_mid end)
|> group_by(fn {x,y} ->
    cond do
        x < x_mid and y < y_mid -> 0
        x > x_mid and y < y_mid -> 1
        x < x_mid and y > y_mid -> 2
        x > x_mid and y > y_mid -> 3
    end
end)
|> map(fn {_, rs} -> count(rs) end)
|> product()
|> IO.inspect()
