defmodule Parse do

defmodule State do
    defstruct text: "", position: {0,0}
end

def init_state(str) do
    %State{text: str}
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

def skip_until(p) do
    alt p,
    bind_(raw_char(), skip_until(p))
end

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

def digit() do
    satisfy fn c -> c >= "0" and c <= "9" end, "digit"
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



end