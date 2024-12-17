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

    @spec iterate_until(state, (state -> {boolean, state | term()})) :: state when state: var
    def iterate_until(state, function) do
        case function.(state) do
            {:iterate, new_state} -> iterate_until(new_state, function)
            {:stop, final_answer} -> final_answer
        end
    end

    def pairs(xs) do
        for {a, ai} <- Enum.with_index(xs),
            {b, bi} <- Enum.with_index(xs),
            ai != bi do
                {a,b}
        end
    end

    def insert_ordered(list, elem, f \\ &Function.identity/1)
    def insert_ordered([], elem, _) do
        [elem]
    end
    def insert_ordered([l | list], elem, f) do
        if f.(l) < f.(elem) do
            [l | insert_ordered(list, elem, f)]
        else
            [elem, l | list]
        end
    end

    def map_map(map, f) do
        for {key, val} <- map,
            into: %{} do
            {key, f.(val)}
        end
    end

    def grid_to_coords(str) do
        for {rw, r} <- str
                    |> String.split("\r\n")
                    |> Enum.with_index(),
            {ch, c} <-  rw
                    |> String.split("", trim: true)
                    |> Enum.with_index()
            do
            {{r,c}, ch}
        end
    end

    def mod(n, m) do
        remainder = rem(n, m)
        if remainder < 0 do
            remainder + m
        else
            remainder
        end
    end

    def map_move(map, key, newkey) do
        {val,new_map} = Map.pop!(map, key)
        if Map.has_key?(map, newkey) do
            raise "can't move #{key}; #{newkey} already exists!"
        else
            Map.put(new_map, newkey, val)
        end
    end
end

import Enum

# parse the initial program

parser = ~r{Register A: (\d+)\r\nRegister B: (\d+)\r\nRegister C: (\d+)\r\n\r\nProgram: (.*)}

[[initial_a_str, initial_b_str, initial_c_str, program_str]] =
    "day17/input.txt"
    |> File.read!()
    |> then(fn str -> Regex.scan(parser, str, [capture: :all_but_first]) end)

[initial_a, initial_b, initial_c] = map([initial_a_str, initial_b_str, initial_c_str], &String.to_integer/1)

index = fn ls ->
    with_index(ls)
    |> map(fn {a,b} -> {b,a} end)
    |> into(%{})
end

initial_program =
    program_str
    |> String.split(",")
    |> map(&String.to_integer/1)
    |> index.()

initial_state = %{
    regs: %{a: initial_a, b: initial_b, c: initial_c},
    program: initial_program,
    instruction_pointer: 0,
    output: []
}

# programme the virtual machine logic

act = fn state ->
    opcode = Map.get(state.program, state.instruction_pointer, -1)
    operand = Map.get(state.program, state.instruction_pointer + 1, nil)

    if opcode != -1 and operand == nil do
        raise "ran off end of program!"
    end
    
    combo = fn operand ->
        case operand do
            4 -> state.regs.a
            5 -> state.regs.b
            6 -> state.regs.c
            x -> x
        end
    end

    case opcode do
        -1 -> :halt
            {:stop, state}
        0 -> :adv
            {:iterate, state
            |> update_in([:regs, :a], fn a -> div(a, 2 ** combo.(operand)) end)
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        1 -> :bxl
            {:iterate, state
            |> update_in([:regs, :b], fn b -> Bitwise.bxor(b, operand) end)
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        2 -> :bst
            {:iterate, state
            |> put_in([:regs, :b], rem(combo.(operand), 8))
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        3 -> :jnz
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> if state.regs.a == 0 do ip + 2 else operand end end)
            }
        4 -> :bxc
            {:iterate, state
            |> update_in([:regs, :b], fn b -> Bitwise.bxor(b, state.regs.c) end)
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        5 -> :out
            {:iterate, state
            |> update_in([:output], fn output -> output ++ [rem(combo.(operand), 8)] end)
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        6 -> :bdv
            {:iterate, state
            |> put_in([:regs, :b], div(state.regs.a, 2 ** combo.(operand)))
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        7 -> :cdv
            {:iterate, state
            |> put_in([:regs, :c], div(state.regs.a, 2 ** combo.(operand)))
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
    end
end

run = fn state ->
    AoC.iterate_until(state, act)
end

# tests from the puzzle description (will give a MatchError if they fail)
%{regs: %{b: 1}} = run.(%{
    regs: %{c: 9},
    program: index.([2,6]),
    instruction_pointer: 0
})

%{output: [0,1,2]} = run.(%{
    regs: %{a: 10},
    program: index.([5,0,5,1,5,4]),
    instruction_pointer: 0,
    output: []
})

%{output: [4,2,5,6,7,7,7,7,3,1,0], regs: %{a: 0}} = run.(%{
    regs: %{a: 2024},
    program: index.([0,1,5,4,3,0]),
    instruction_pointer: 0,
    output: []
})

%{regs: %{b: 26}} = run.(%{
    regs: %{b: 29},
    program: index.([1,7]),
    instruction_pointer: 0
})

%{regs: %{b: 44354}} = run.(%{
    regs: %{b: 2024, c: 43690},
    program: index.([4,0]),
    instruction_pointer: 0
})

# answer
run.(initial_state).output
|> join(",")
|> IO.puts()
