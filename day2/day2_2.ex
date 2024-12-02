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

File.read!("day2/day2.txt")
    |> split("\r\n")
    |> map(fn ln
        -> split(ln, " ")
        |> map(&to_integer/1)
        |> then(fn report -> zip_with([[]] ++ AoC.heads(report), AoC.tails(report) ++ [[]], &++/2) end)
        |> map(fn report_version
            -> AoC.zip_tail_with(report_version, &-/2)
            |> then(fn [x | _] = diffs -> if x < 0 do map(diffs, fn y -> -y end) else diffs end end)
            |> all?(fn x -> x >= 1 and x <= 3 end)
            end)
        |> any?(&Function.identity/1)
        end)
    |> count(&Function.identity/1)
    |> IO.inspect()
