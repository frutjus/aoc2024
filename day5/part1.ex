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

file_str = File.read!("day5/input.txt")

[rules_str,updates_str] = split(file_str, "\r\n\r\n")

rules = for str <- split(rules_str, "\r\n"),
            [l,r] = split(str, "|"),
            reduce: %{} do
        acc -> Map.update(acc, l, [r], fn ls -> [r | ls] end)
    end

updates = split(updates_str, "\r\n")
    |> map(fn ln -> split(ln, ",") end)

filter(updates, fn update ->
    map(AoC.heads(update), fn ns ->
        [n | ls] = Enum.reverse(ns)
        ls -- Map.get(rules, n, []) == ls
    end)
    |> all?(&Function.identity/1)
end)
|> map(fn update ->
    Enum.at(update, (Kernel.length(update)-1) |> div(2))
    |> to_integer()
end)
|> sum()
|> IO.inspect()