defmodule AoC do
    def main() do
        input = File.read!("day1/day1.txt")
        answer = solve(input)
        IO.puts(inspect(answer))
    end

    def solve(input) do
        lines = String.split(input, "\r\n")
        words = Enum.map(lines, fn ln -> String.split(ln, "   ") |> Enum.map(&String.to_integer/1) end)
        [leftCol, rightCol] = Enum.zip(words) |> Enum.map(&Tuple.to_list/1)
        similarities = Enum.map(leftCol, fn l -> Enum.count(rightCol, fn r -> l == r end) * l end)
        Enum.sum(similarities)
    end
end

AoC.main()