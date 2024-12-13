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
end

import Enum

parser = ~r{Button A: X\+(\d+), Y\+(\d+)\r\nButton B: X\+(\d+), Y\+(\d+)\r\nPrize: X=(\d+), Y=(\d+)}

"day13/input.txt" 
|> File.read!()
|> then(fn str -> Regex.scan(parser, str, [capture: :all_but_first]) end)
|> with_index()
|> map(fn {vals, i} ->
    map(vals, &String.to_integer()/1)
    |> then(fn [ax,ay,bx,by,x1,y1] ->
        x = 10000000000000 + x1
        y = 10000000000000 + y1
        bnum = ax*y - ay*x
        bdenom = by*ax - bx*ay
        IO.puts("#{String.pad_leading(to_string(i),3," ")}: A = (#{ax},#{ay}), B = (#{bx},#{by}), Prize = (#{x},#{y}),\tax.Y - ay.X = #{bnum}\tby.ax - bx.ay = #{bdenom}")
        cond do
            bnum == 0 and bdenom == 0 ->
                :infinite
            bnum == 0 or bdenom == 0 ->
                :zero
            rem(bnum, bdenom) != 0 ->
                :zero_whole_b
            true ->
                b = div(bnum, bdenom)
                if rem(x - bx*b, ax) != 0 do
                    :zero_whole_a
                else
                    a = div(x - bx*b, ax)
                    if a < 0 or b < 0 do
                        :negative
                    else
                        {a,b}
                    end
                end
        end
    end)
end)
|> tap(fn sols ->
    for {a,b} <- sols do
        a * 3 + b
    end
    |> sum()
    |> IO.inspect()
end)
|> group_by(fn
    a when is_atom(a) -> a
    _ -> :else
end)
|> AoC.map_map(&count/1)
|> IO.inspect()
