defmodule AoC do
    def main() do
        input = File.read!("day1/day1.txt")
        answer = solve(input)
        IO.puts(inspect(answer))
    end

    def solve(input) do
        lines = String.split(input, "\r\n")
        words = Enum.map(lines, fn ln -> String.split(ln, "   ") |> Enum.map(&String.to_integer/1) end)
        sorted = Enum.zip(words) |> Enum.map(fn ls -> Enum.sort(Tuple.to_list(ls)) end)
        paired = Enum.zip(sorted)
        diffs = Enum.map(paired, fn {l,r} -> abs(l - r) end)
        Enum.sum(diffs)
    end
end

AoC.main()