defmodule JSONSchema do
  defp field_typedef_simple(root, name, type) do
    %{
      "$id": root <> "/properties/" <> Atom.to_string(name),
      type: type
    }
  end

  defp schema_properties(x, root) do
    import Enum, only: [map: 2, reject: 2]

    {:ok, [type: typedef]} = Code.Typespec.fetch_types(x)
    {:t, {:type, _lineno, :map, fields}, []} = typedef

    fields |> map(&remove_lineno/1) |> map(&field(root, &1)) |> reject(&is_nil/1)
  end

  defp remove_lineno(t) do
    Tuple.delete_at(t, 1)
  end

  defp field_typedef(root, field_name, typedef) do
    case typedef do
      {:type, :integer, []} ->
        field_typedef_simple(root, field_name, "integer")

      {:type, :float, []} ->
        field_typedef_simple(root, field_name, "number")

      {:remote_type, [{:atom, 0, String}, {:atom, 0, :t}, []]} ->
        field_typedef_simple(root, field_name, "string")

      {:remote_type, [{:atom, 0, module}, {:atom, 0, :t}, []]} ->
        schema(module, root <> "/properties/" <> Atom.to_string(field_name))

      _ ->
        typedef
    end
  end

  defp field(_root, {:type, :map_field_exact, [{:atom, _, :__struct__} | _]}) do
    nil
  end

  defp field(root, {:type, :map_field_exact, [{:atom, _, field_name} | typedef]}) do
    {field_name, field_typedef(root, field_name, typedef |> Enum.map(&remove_lineno/1) |> hd)}
  end

  def schema(module) do
    schema(module, "#")
  end

  def schema(module, name) do
    %{
      "$id": name,
      type: "object",
      properties: schema_properties(module, name)
    }
  end
end
