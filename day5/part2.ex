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
end

import Enum, except: [split: 2]
import String

defmodule Day5 do
    # This was an attempt to figure out the full list of pages that each page has to be to the left of
    # it did not work... because the input contains cycles!
    def populate_ultimate_rules([], ult, _) do
        ult
    end
    def populate_ultimate_rules([{key, vals} | rest], ult, rules) do
        if Map.has_key?(ult, key) do
            populate_ultimate_rules(rest, ult, rules)
        else
            IO.inspect(key)
            {ult_vals, ult2} = reduce(vals, {[], ult}, fn val, {vals, ult} ->
                new_ult = populate_ultimate_rules([{val,Map.get(rules,val,[])}], ult, rules)
                {vals ++ new_ult[val], new_ult}
            end)
            ult3 = Map.put(ult2, key, uniq(ult_vals ++ vals))
            populate_ultimate_rules(rest, ult3, rules)
        end
    end

end

file_str = File.read!("day5/input.txt")

[rules_str,updates_str] = split(file_str, "\r\n\r\n")

rules = for str <- split(rules_str, "\r\n"),
    [l,r] = split(str, "|"),
    reduce: %{} do
        acc -> Map.update(acc, l, [r], fn ls -> [r | ls] end)
end

updates = split(updates_str, "\r\n")
    |> map(fn ln -> split(ln, ",") end)

reject(updates, fn update ->
    all?(AoC.heads(update), fn ns ->
        [n | ls] = Enum.reverse(ns)
        ls -- Map.get(rules, n, []) == ls
    end)
end)
|> map(fn update ->
    filter(update, fn page -> Kernel.length(filter(rules[page], fn r -> r in update end)) == div(Kernel.length(update)-1,2) end)
    |> hd
    |> to_integer()
end)
|> sum()
|> IO.inspect()
