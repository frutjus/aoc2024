defmodule Parse do

defmodule State do
    defstruct text: "", position: {1,1}
end

def init_state(str) do
    %State{text: str}
end

def run(str, parser) do
    init_state(str)
    |> then(parser)
    |> then(fn
        {a, b} -> {a, b}
        {a, b, _} -> {a, b}
    end)
end

def just(x) do
    fn input -> {:succeed, x, input} end
end

def fail(msg) do
    fn %State{position: {l, c}} -> {:fail, "Parse failed at #{l}:#{c}: #{msg}"} end
end

def bind(p, f) do
    fn input ->
        case p.(input) do
            {:fail, _} = err -> err
            {:succeed, x, rest} -> f.(x).(rest)
        end
    end
end

def bind_(p1, p2) do
    bind(p1, fn _ -> p2 end)
end

def alt(p1, p2) do
    fn input ->
        case p1.(input) do
            {:succeed, _, _} = result -> result
            {:fail, _} -> p2.(input)
        end
    end
end

def many(p) do
   (bind p, fn x ->
    bind many(p), fn xs ->
    just [x | xs]
    end end)
    |> alt(just [])
end

def some(p) do
    bind p, fn x ->
    bind many(p), fn xs ->
    just [x | xs]
    end end
end

def count(n, p) do
    if n <= 0 do
        just []
    else
        bind p, fn x ->
        bind count(n-1, p), fn xs ->
        just [x | xs]
        end end
    end
end

def sepBy(p, sep) do
    with_separator = bind_ sep, p
    (bind p, fn first ->
    bind many(with_separator), fn rest ->
    just [first | rest]
    end end)
    |> alt(just [])
end

def endBy(p, sep) do
    with_separator =
        bind p, fn res ->
        bind_ sep,
        just res
        end
    many(with_separator)
end

# def skip_until(p) do
#     alt p,
#     bind_(raw_char(), skip_until(p))
# end

def raw_char() do
    fn %State{text: ""} = st -> fail("reached end of input").(st)
       %State{text: text, position: {l,r}} = st ->
        {c, rest} = String.split_at(text, 1)
        {l1,r1} = {l,r+1}
        {:succeed, c, %{st | text: rest, position: {l1,r1}}}
    end
end

def satisfy(pred, desc) do
    bind(raw_char(), fn c ->
    if pred.(c) do just(c) else fail("expected #{desc}; found \"#{c}\"") end end)
end

def lower() do
    satisfy fn c -> c >= "a" and c <= "z" end, "lower case letter"
end

def upper() do
    satisfy fn c -> c >= "A" and c <= "Z" end, "upper case letter"
end

def alpha() do
    satisfy fn c -> (c >= "A" and c <= "Z") or (c >= "a" and c <= "z") end, "letter"
end

def digit() do
    satisfy fn c -> c >= "0" and c <= "9" end, "digit"
end

def alphanum() do
    satisfy fn c -> (c >= "A" and c <= "Z") or (c >= "a" and c <= "z") or (c >= "0" and c <= "9") end, "alphanumeric"
end

def whole_number() do
    bind some(digit()), fn ds ->
    just String.to_integer(Enum.join(ds, ""))
    end
end

def string_literal("") do
    just ""
end
def string_literal(str) do
   ({c, rest} = String.split_at(str, 1)
    bind satisfy(&(&1==c), "#{c}"), fn _ ->
    bind string_literal(rest), fn _ ->
    just str
    end end)
    |> alt(fail("expected \"#{str}\""))
end

def newline() do
    consume =
        string_literal("\r\n")
        |> alt(string_literal("\n"))
        |> alt(string_literal("\r"))
    bind consume, fn str ->
    fn %State{position: {l,_r}} = st ->
        {l1,r1} = {l+1,1}
        {:succeed, str, %{st | position: {l1,r1}}}
    end end
end

end