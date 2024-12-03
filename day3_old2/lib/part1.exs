defmodule AoC do
    def zip_tail_with(xs, f) do
        Enum.zip_with(tl(xs), Enum.drop(xs, -1), f)
    end
end

import Enum, except: [split: 2]
import String

defmodule Day3 do
    parse_instruction =
        ignore(string("mul("))
        |> integer(min: 1, max: 3)
        |> ignore(string(","))
        |> integer(min: 1, max: 3)
        |> ignore(string(")"))

    defparsec :parse_program, eventually(parse_instruction)
end

File.read!("day3/sample.txt")
    |> Day3.parse_program()
    |> IO.inspect()
