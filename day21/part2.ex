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

    @spec iterate_until(state, (state -> {atom, state | term()})) :: state when state: var
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

import Enum, except: [max: 2]

codes =
    "day21/input.txt"
    |> File.read!()
    |> String.split("\r\n")
    |> map(fn ln ->
        String.split(ln, "", trim: true)
    end)

# Numeric keypad
# +---+---+---+
# | 7 | 8 | 9 |
# +---+---+---+
# | 4 | 5 | 6 |
# +---+---+---+
# | 1 | 2 | 3 |
# +---+---+---+
#     | 0 | A |
#     +---+---+

# Directional keypad
#     +---+---+
#     | ^ | A |
# +---+---+---+
# | < | v | > |
# +---+---+---+

# Let's give up on trying to be functional
:ets.new(:memo_table, [:named_table, :public, read_concurrency: true])

defmodule Day21 do

    def moves_from_buttons(buttons) do
        scan(
            buttons,
            {nil, "A"},
            fn button, {_, from} -> {from, button} end
        )
    end

    def routes_from_move({a,b}) when a == b do [["A"]] end
    def routes_from_move({a,b}) do
        is_numeric? = ("0" <= a and a <= "9") or ("0" <= b and b <= "9")

        get_coords = fn
            # Numeric keypad
            "7" -> {0,0}; "8" -> {0,1}; "9" -> {0,2}
            "4" -> {1,0}; "5" -> {1,1}; "6" -> {1,2}
            "1" -> {2,0}; "2" -> {2,1}; "3" -> {2,2}
                        "0" -> {3,1}; "A" when is_numeric? -> {3,2}
            
            # Directional keypad
                        "^" -> {0,1}; "A" when not is_numeric? -> {0,2}
            "<" -> {1,0}; "v" -> {1,1}; ">" -> {1,2}
        end

        {ra,ca} = get_coords.(a)
        {rb,cb} = get_coords.(b)

        down_moves  = List.duplicate("v", max(rb - ra, 0))
        left_moves  = List.duplicate("<", max(ca - cb, 0))
        right_moves = List.duplicate(">", max(cb - ca, 0))
        up_moves    = List.duplicate("^", max(ra - rb, 0))

        all_moves = concat([down_moves, left_moves, right_moves, up_moves])

        is_constrained? = if is_numeric? do
            (ra == 3 and cb == 0) or (rb == 3 and ca == 0)
        else
            (ra == 0 and cb == 0) or (rb == 0 and ca == 0)
        end

        if is_constrained? do
            if is_numeric? do
                [reverse(all_moves) ++ ["A"]]
            else
                [all_moves ++ ["A"]]
            end
        else
            [reverse(all_moves) ++ ["A"], all_moves ++ ["A"]]
        end
    end

    def shortest_route(move, layers) do
        case :ets.lookup(:memo_table, {move, layers}) do
            [{_, result}] ->
                #IO.puts("remembered that shortest_route(#{inspect(move)}, #{layers}) = #{result}")
                result
            [] -> 
                routes = routes_from_move(move)
                result =
                    cond do
                        layers < 1 ->
                            raise "layers should never be less than 1"
                        layers == 1 ->
                            routes |> map(&length/1) |> min()
                        true ->
                            map(routes, fn route ->
                                next_moves = moves_from_buttons(route)
                                subroutes = map(next_moves, fn next_move -> shortest_route(next_move, layers - 1) end)
                                sum(subroutes)
                            end)
                            |> min()
                    end
                :ets.insert(:memo_table, {{move, layers}, result})
                result
        end
    end
end

map(codes, fn code ->
    moves = Day21.moves_from_buttons(code)
    subroutes = map(moves, fn move -> Day21.shortest_route(move, 26) end)
    sequence = sum(subroutes)
    {numeric_part,_} = Integer.parse(join(code))
    {(sequence), numeric_part}
    (sequence) * numeric_part
end)
|> sum()
|> IO.inspect()

# add_indirection.(at(codes, 4), 3)
# |> join()

## Me
#               3                                        7               9                          A
#         ^     A         ^ ^            <   <           A       > >     A            v v v         A
#    <    A  >  A    <    A A    v  <    A   A  > >   ^  A   v   A A  ^  A    v  <    A A A  >   ^  A
# v<<A >>^A vA ^A v<<A >>^A A  v<A <A >>^A   A vA A <^A >A v<A >^A A <A >A  v<A <A >>^A A A vA <^A >A

## Them
#               3                                        7               9                          A
#         ^     A                <  <           ^ ^      A       > >     A            v v v         A
#    <    A  >  A    v    < <    A  A    >   ^  A A   >  A   v   A A  ^  A    <  v    A A A  >   ^  A
# <v<A >>^A vA ^A  <vA   <A A >>^A  A   vA <^A >A A  vA ^A <vA >^A A <A >A <v<A >A  >^A A A vA <^A >A
