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

check = fn
    [["M", _ ,"S"],
     [ _ ,"A", _ ],
     ["M", _ ,"S"]
    ] -> true
    [["M", _ ,"M"],
     [ _ ,"A", _ ],
     ["S", _ ,"S"]
    ] -> true
    [["S", _ ,"M"],
     [ _ ,"A", _ ],
     ["S", _ ,"M"]
    ] -> true
    [["S", _ ,"S"],
     [ _ ,"A", _ ],
     ["M", _ ,"M"]
    ] -> true
    _ -> false
end

count_x_mas = fn grid ->
    for [r1,r2,r3 | _] <- AoC.tails1(grid),
        [c1,c2,c3 | _] <- AoC.tails1(AoC.transpose([r1,r2,r3])),
        check.([c1,c2,c3]),
        reduce: 0 do
        acc -> acc + 1
    end
end

"day4/input.txt"
    |> File.read!()
    |> split("\r\n")
    |> map(fn ln -> split(ln, "", trim: true) end)
    |> count_x_mas.()
    |> IO.inspect()
