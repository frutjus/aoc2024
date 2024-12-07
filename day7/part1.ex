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

    @spec iterate_until(state, (state -> {boolean, state})) :: state when state: var
    def iterate_until(state, function) do
        case function.(state) do
            {true, newstate} -> iterate_until(newstate, function)
            {false, newstate} -> newstate
        end
    end

    def bind_list(list, function) do
        for l1 <- list,
            l2 <- function.(l1) do
                l2
        end
    end
end

import Enum, except: [split: 2]
import String, only: [split: 2, split: 3, to_integer: 1]

input = "day7/input.txt"
    |> File.read!()
    |> split("\r\n")
    |> map(fn ln ->
        split(ln, ":")
        |> then(fn [result_text,equation_text] ->
            result = to_integer(result_text)
            equation = split(equation_text, " ", trim: true) |> map(&to_integer/1)
            {result,equation}
        end)
end)

test_equation = fn {result,[final_val | vals]} ->
    reverse(vals)
    |> reduce(
        [{result, []}],
        fn val, solutions ->
        for {sol,ops} <- solutions,
            {op,op_str} <- [{&-/2,"+"},{&//2,"*"}],
            new_res = sol |> op.(val),
            new_res >= final_val do
                {new_res, [op_str | ops]}
        end
    end)
    |> filter(fn {sol,_} -> sol == final_val end)
    |> map(fn {_,ops} -> ops end)
end

for {{result, vals} = inp, index} <- with_index(input) do
    solutions = test_equation.(inp)
    for ops <- solutions do
        equation = reduce(reverse(zip_with(vals, ops, fn val, op -> to_string(val) <> op end)), "", &<>/2) <> to_string(List.last(vals))
        IO.puts("#{index}: #{result} = #{equation}")
    end
    if not empty?(solutions) do result else 0 end
end
|> sum()
|> IO.inspect()