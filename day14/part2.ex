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

initial =
file
|> File.read!()
|> then(fn str -> Regex.scan(parser, str, [capture: :all_but_first]) end)

simulate = fn steps ->
    map(initial, fn vals ->
        map(vals, &String.to_integer/1)
        |> then(fn [x,y,dx,dy] ->
            {AoC.mod(x + dx*steps, x_max), AoC.mod(y + dy*steps, y_max)}
        end)
    end)
end

display = fn robots ->
    map(0..y_max-1, fn y ->
        map(0..x_max-1, fn x ->
            c = filter(robots, & &1 == {x,y}) |> count() |> to_string()
            IO.write(if c == "0" do "." else c end)
        end)
        IO.write("\r\n")
    end)
end

variance = fn robots ->
    xs = map(robots, fn {x,_} -> x end)
    ys = map(robots, fn {_,y} -> y end)
    x_mean = sum(xs) / count(xs)
    y_mean = sum(ys) / count(ys)
    x_var = map(xs, fn x -> (x - x_mean) ** 2 end) |> sum()
    y_var = map(ys, fn y -> (y - y_mean) ** 2 end) |> sum()
    x_var + y_var
end

# for inp_str <- IO.stream() do
#     inp = String.trim(inp_str)
#     case Integer.parse(inp) do
#         {i,""} -> display.(simulate.(i))
#         _ -> nil
#     end
# end

1..10000
|> map(fn steps -> simulate.(steps) |> variance.() |> then(fn v -> {steps, v} end) end)
|> min_by(fn {_,v} -> v end)
|> then(fn {steps,_} ->
    IO.inspect(steps)
    display.(simulate.(steps))
end)