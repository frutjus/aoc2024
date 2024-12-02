defmodule AoC do
    def zip_tail_with(xs, f) do
        Enum.zip_with(tl(xs), Enum.drop(xs, -1), f)
    end
end

import Enum, except: [split: 2]
import String

File.read!("day2/day2.txt")
    |> split("\r\n")
    |> map(fn ln
        -> split(ln, " ")
        |> map(&to_integer/1)
        |> AoC.zip_tail_with(fn x, y -> x - y end)
        |> then(fn [x | _] = diffs -> if x < 0 do map(diffs, fn y -> -y end) else diffs end end)
        |> all?(fn x -> x >= 1 and x <= 3 end)
        end)
    |> count(&Function.identity/1)
    |> IO.inspect()
