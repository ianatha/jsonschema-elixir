defmodule Box do
  defmacro __using__(_env) do
    quote do
      import Box
    end
  end

  def type_check2(type, v) do
    case type do
      {:type, _lineno, :map_field_exact, [{:atom, _lineno2, :__struct__} | _ ]} ->
        :ok
      {:type, _lineno, :map_field_exact, [{:atom, _lineno2, fieldname}, {:type, _lineno3, :integer, []}]} ->
        if(is_integer(Map.get(v, fieldname)), do: :ok, else: :not_an_integer)
      {:type, _lineno, :map_field_exact, [{:atom, _lineno2, fieldname}, {:type, _lineno3, :boolean, []}]} ->
        if(is_boolean(Map.get(v, fieldname)), do: :ok, else: :not_a_boolean)
      v -> {:unknown, v}
    end
  end

  def type_check(module, type, v) do
    {:ok, types_kw} = Code.Typespec.fetch_types(module)
    types = Enum.map(types_kw, fn {:type, {tname, tspec, []}} -> {tname, tspec} end)

    case types[type] do
      {:type, _lineno, :map, fields} ->
        res = fields |> Enum.map(&type_check2(&1, v))
        if(Enum.all?(res, &(&1 == :ok)), do: :ok, else: res)

      {:type, _lineno, :union, _union_members} ->
        :union

      _ ->
        {:error, types[type]}
    end
  end

  def type_check(module, v) do
    if (not is_map(v)) or (not (v.__struct__ == module)) do
      {:error, "__struct__ mistmatch"}
    else
      type_check(module, :t, v)
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

        def __type_check(v) do
          Box.type_check(__MODULE__, v)
        end

        @type t :: %__MODULE__{
                unquote_splicing(attrs_without_meta)
              }
      end
    end
  end
end
