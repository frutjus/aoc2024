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
end

import Enum, except: [split: 2]
import String

instruction = ~r{mul\((\d+),(\d+)\)|do\(\)|don't\(\)}

filter_valid = fn instructions ->
    reduce(instructions, {true, []}, fn item, {inc, is} ->
        cond do
            item == "do()" ->
                {true, is}
            item == "don't()" ->
                {false, is}
            inc ->
                {inc, [item | is]}
            true ->
                {inc, is}
        end
    end)
    |> elem(1)
    |> Enum.reverse()
end

File.read!("day3/input.txt")
    |> split(instruction, include_captures: true)
    |> filter(&(String.match?(&1, instruction)))
    |> filter_valid.()
    |> map( fn str ->
        Regex.scan(instruction, str, capture: :all_but_first)
        |> hd
        |> map(&to_integer/1)
        |> then(fn [x,y] -> x * y end)
    end)
    |> sum
    |> IO.inspect()
