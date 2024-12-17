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

# disassemble the virtual machine logic

act = fn state ->
    opcode = Map.get(state.program, state.instruction_pointer, -1)
    operand = Map.get(state.program, state.instruction_pointer + 1, nil)

    if opcode != -1 and operand == nil do
        raise "ran off end of program!"
    end
    
    combo = fn operand ->
        case operand do
            4 -> "a"
            5 -> "b"
            6 -> "c"
            x -> x
        end
    end

    case opcode do
        -1 -> :halt
            {:stop, state}
        0 -> :adv
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| adv #{combo.(operand)} \t| a = a / 2^#{combo.(operand)}")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        1 -> :bxl
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| bxl #{operand} \t| b = b xor #{operand}")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        2 -> :bst
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| bst #{combo.(operand)} \t| b = #{combo.(operand)} % 8")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        3 -> :jnz
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| jnz #{operand} \t| if a != 0: jmp #{operand}")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        4 -> :bxc
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| bxc #{operand} \t| b = b xor c")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        5 -> :out
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| out #{combo.(operand)} \t| out #{combo.(operand)} % 8")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        6 -> :bdv
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| adv #{combo.(operand)} \t| b = a / 2^#{combo.(operand)}")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
        7 -> :cdv
            IO.puts("#{state.instruction_pointer} \t| #{opcode} #{operand} \t| adv #{combo.(operand)} \t| c = a / 2^#{combo.(operand)}")
            {:iterate, state
            |> update_in([:instruction_pointer], fn ip -> ip + 2 end)
            }
    end
end

run = fn state ->
    AoC.iterate_until(state, act)
end

# print out instructions
run.(initial_state)
