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

    def transpose(rows) do
        rows
        |> List.zip
        |> Enum.map(&Tuple.to_list/1)
    end
end

import Enum, except: [split: 2]
import String

count_horizontals = fn grid ->
    check_line = fn line ->
        for ["X","M","A","S" | _] <- [line | AoC.tails(line)], reduce: 0 do
            acc -> acc + 1
        end
    end
    map(grid, check_line)
    |> sum
end

count_orthogonals = fn grid ->
    count_horizontals.(grid) + 
    count_horizontals.(map(grid, &Enum.reverse/1)) + 
    count_horizontals.(AoC.transpose(grid)) +
    count_horizontals.(map(AoC.transpose(grid), &Enum.reverse/1))
end

make_diagonal = fn grid ->
    front_padding = grid
        |> hd
        |> AoC.tails
        |> map(fn row -> map(row, fn _ -> "." end) end)
    
    rear_padding = grid
        |> hd
        |> AoC.heads
        |> map(fn row -> map(row, fn _ -> "." end) end)
    
    front_padding
    |> zip_with(grid, &++/2)
    |> zip_with(rear_padding, &++/2)
    |> AoC.transpose
end

count_diagonals = fn grid ->
    count_horizontals.(make_diagonal.(grid)) +
    count_horizontals.(map(make_diagonal.(grid), &Enum.reverse/1)) +
    count_horizontals.(make_diagonal.(map(grid, &Enum.reverse/1))) +
    count_horizontals.(map(make_diagonal.(map(grid, &Enum.reverse/1)), &Enum.reverse/1))
end

count_all = fn grid ->
    count_orthogonals.(grid) + count_diagonals.(grid)
end

"day4/input.txt"
    |> File.read!()
    |> split("\r\n")
    |> map(fn ln -> split(ln, "", trim: true) end)
    |> count_all.()
    |> IO.inspect()
