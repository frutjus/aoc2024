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
end

import Enum

initial_grid =
for {row, r} <- "day12/input.txt" 
             |> File.read!()
             |> String.split("\r\n")
             |> with_index(),
    {char, c} <-  row
              |> String.split("", trim: true)
              |> with_index(),
    into: %{}
    do
    {{r,c}, char}
end

AoC.iterate_until(
    {initial_grid, [], nil, [], 0},
    fn {unassigned_pots, found_pots, current_region, regions, step} ->
        if empty?(found_pots) do
            if empty?(unassigned_pots) do
                IO.puts("took #{step} steps")
                {:stop, [current_region | regions]}
            else
                new_pot = hd(Map.keys(unassigned_pots))
                {new_symbol, new_unassigned_pots} = Map.pop!(unassigned_pots, new_pot)
                new_current_region = %{symbol: new_symbol, pots: MapSet.new(), area: 0, perimeter: 0}
                new_regions = if current_region == nil do regions else [current_region | regions] end
                {:iterate, {new_unassigned_pots, [new_pot], new_current_region, new_regions, step + 1}}
            end
        else
            reduce(
                found_pots,
                {unassigned_pots, [], current_region, regions, step},
                fn {r,c}, {unassigned_pots, found_pots, current_region, regions, step} ->
                    neighbours = [{r-1,c},
                                  {r,c+1},
                                  {r+1,c},
                                  {r,c-1}]
                    new_found_pots = Map.take(unassigned_pots, neighbours)
                        |> Map.filter(fn {_, symbol} -> symbol == current_region.symbol end)
                        |> Map.keys()
                    new_unassigned_pots = Map.drop(unassigned_pots, new_found_pots)
                    new_perimeter = Map.take(initial_grid, neighbours)
                        |> Map.filter(fn {_, symbol} -> symbol == current_region.symbol end)
                        |> count()
                        |> then(fn c -> 4 - c end)
                    new_current_region = current_region
                        |> update_in([:pots], fn pots -> MapSet.put(pots, {r,c}) end)
                        |> update_in([:area], fn a -> a + 1 end)
                        |> update_in([:perimeter], fn p -> p + new_perimeter end)
                    {new_unassigned_pots, new_found_pots ++ found_pots, new_current_region, regions, step + 1}
                end
            ) |> then(fn res -> {:iterate, res} end)
        end
    end
)
|> map(fn region ->
    region.pots
    |> flat_map(fn {r,c} ->
        [{r,c},{r,c+1},{r+1,c},{r+1,c+1}]
    end)
    |> uniq()
    |> map(fn {r,c} ->
        [{r-1,c-1},{r-1,c},{r,c-1},{r,c}]
        |> map(fn pot -> if MapSet.member?(region.pots, pot) do :x else :o end end)
        |> then(fn
            [:x,:x,
             :x,:x] -> 0

            [:o,:x,
             :x,:x] -> 1
            [:x,:o,
             :x,:x] -> 1
            [:x,:x,
             :o,:x] -> 1
            [:x,:x,
             :x,:o] -> 1

            [:o,:o,
             :x,:x] -> 0
            [:x,:o,
             :x,:o] -> 0
            [:x,:x,
             :o,:o] -> 0
            [:o,:x,
             :o,:x] -> 0

            [:o,:x,
             :x,:o] -> 2
            [:x,:o,
             :o,:x] -> 2

            [:x,:o,
             :o,:o] -> 1
            [:o,:x,
             :o,:o] -> 1
            [:o,:o,
             :o,:x] -> 1
            [:o,:o,
             :x,:o] -> 1

            [:o,:o,
             :o,:o] -> 0
        end)
    end)
    |> sum()
    |> tap(fn s -> IO.puts("#{region.symbol}: #{region.area} * #{s} = #{s * region.area}") end)
    |> then(fn s -> s * region.area end)
end)
|> sum()
|> IO.inspect()