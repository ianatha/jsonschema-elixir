defmodule Box do
  defmacro __using__(_env) do
    quote do
      import Box
    end
  end

  def reduce_meta_attrs({k, v}, acc) do
    if String.starts_with?(Atom.to_string(k), "__") do
      last_keyword = acc |> hd |> elem(0)

      Keyword.get_and_update(
        acc,
        last_keyword,
        &{&1,
         Keyword.put_new(&1, k |> Atom.to_string() |> String.trim("_") |> String.to_atom(), v)}
      )
      |> elem(1)
    else
      Keyword.put_new(acc, k, [])
    end
  end

  defmacro defbox(name, attrs \\ []) do
    attrs_without_meta =
      Keyword.to_list(attrs)
      |> Enum.filter(fn {k, _} -> not String.starts_with?(Atom.to_string(k), "__") end)

    keys = attrs_without_meta |> Keyword.keys()
    meta = Enum.reduce(attrs, [], &reduce_meta_attrs/2)

    quote do
      defmodule unquote(name) do
        @derive [Poison.Encoder]
        @enforce_keys unquote(keys)
        defstruct unquote(keys)

        def __meta do
          unquote(meta)
        end

        @type t :: %__MODULE__{
                unquote_splicing(attrs_without_meta)
              }
      end
    end
  end
end
