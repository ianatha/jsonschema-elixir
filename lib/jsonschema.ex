defmodule JSONSchema do
  @type schema_result :: %{
          required(:"$id") => String.t(),
          optional(:properties) => map,
          required(:type) => String.t()
        }

  # @spec field_typedef_simple(String.t(), String.t(), String.t()) :: schema_result
  defp field_typedef_simple(root, name, type, meta \\ []) do
    %{
      "$id": root <> "/properties/" <> name,
      type: type
    }
    |> Map.merge(if meta[:examples], do: %{examples: meta[:examples]}, else: %{})
    |> Map.merge(if meta[:title], do: %{title: meta[:title]}, else: %{})
  end

  @spec get_meta(atom, atom) :: []
  defp get_meta(module, field_name_atom) do
    apply(module, :__meta, [])[field_name_atom]
  end

  @spec field_typedef(String.t(), String.t(), map) :: {:error, map} | schema_result
  defp field_typedef(root, field_name_atom, typedef, meta \\ []) do
    field_name = field_name_atom |> Atom.to_string()

    case typedef do
      {:type, _lineno, :integer, []} ->
        field_typedef_simple(root, field_name, "integer", meta)

      {:type, _lineno, :float, []} ->
        field_typedef_simple(root, field_name, "number", meta)

      {:type, _lineno, :boolean, []} ->
        field_typedef_simple(root, field_name, "boolean", meta)

      {:type, _lineno, :list, subtype} ->
        Map.merge(field_typedef_simple(root, field_name, "array"), %{
          items: field_typedef(root, String.to_atom(field_name <> "/items"), hd(subtype))
        })

      {:remote_type, _lineno, [{:atom, 0, String}, {:atom, 0, :t}, []]} ->
        field_typedef_simple(root, field_name, "string", meta)

      {:remote_type, _lineno, [{:atom, 0, module}, {:atom, 0, :t}, []]} ->
        field_typedef_object(module, root <> "/properties/" <> field_name)

      _ ->
        {:error, typedef}
    end
  end

  defp field(_module, _root, {:type, _lineno, :map_field_exact, [{:atom, _, :__struct__} | _]}) do
    nil
  end

  #  @spec field(String.t(), {:type, integer, :map_field_exact, nonempty_maybe_improper_list()}) ::
  # nil | {atom(), {:error, map()} | map()}
  defp field(module, root, {:type, _lineno, :map_field_exact, [{:atom, _, field_name} | typedef]}) do
    {field_name, field_typedef(root, field_name, typedef |> hd, get_meta(module, field_name))}
  end

  @spec field_typedef_object(atom(), String.t()) :: schema_result
  defp field_typedef_object(module, name) do
    import Enum, only: [map: 2, reject: 2]

    {:ok, [type: typedef]} = Code.Typespec.fetch_types(module)
    {:t, {:type, _lineno, :map, fields}, []} = typedef

    properties = fields |> map(&field(module, name, &1)) |> reject(&is_nil/1) |> Map.new()

    %{
      "$id": name,
      type: "object",
      properties: properties
    }
  end

  @spec schema(atom()) :: schema_result
  def schema(module) do
    field_typedef_object(module, "#")
  end
end
