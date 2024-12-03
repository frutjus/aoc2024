defmodule AoC do
    def zip_tail_with(xs, f) do
        Enum.zip_with(tl(xs), Enum.drop(xs, -1), f)
    end
end

import Enum, except: [split: 2]
import String

import Parse, only: [just: 1, bind: 2, bind_: 2, alt: 2]

defmodule Day3 do
    def parse_instruction() do
        bind_ Parse.string_literal("mul("),
        bind(Parse.whole_number(), fn x1 ->
        bind_(Parse.string_literal(","),
        bind(Parse.whole_number(), fn x2 ->
        bind_(Parse.string_literal(")"),
        just(x1 * x2))
        end)) end)
    end

    def parse_program() do
        bind((Parse.skip_until(parse_instruction())), fn xs ->
        just sum(xs)
        end)
    end

    def test() do
        Parse.skip_until(Parse.string_literal("xmul"))
    end
end

File.read!("day3/sample.txt")
    |> Parse.init_state()
    |> Day3.test().()
    |> IO.inspect()
