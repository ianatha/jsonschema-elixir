defmodule JSONSchema do
  defp field_typedef_simple(root, name, type) do
    %{
      "$id": root <> "/properties/" <> name,
      type: type
    }
  end

  defp field_typedef(root, field_name, typedef) do
    case typedef do
      {:type, _lineno, :integer, []} ->
        field_typedef_simple(root, field_name, "integer")

      {:type, _lineno, :float, []} ->
        field_typedef_simple(root, field_name, "number")

      {:type, _lineno, :boolean, []} ->
        field_typedef_simple(root, field_name, "boolean")

      {:type, _lineno, :list, subtype} ->
        Map.merge(field_typedef_simple(root, field_name, "array"), %{
          items: field_typedef(root, field_name <> "/items", hd(subtype))
        })

      {:remote_type, _lineno, [{:atom, 0, String}, {:atom, 0, :t}, []]} ->
        field_typedef_simple(root, field_name, "string")

      {:remote_type, _lineno, [{:atom, 0, module}, {:atom, 0, :t}, []]} ->
        field_typedef_object(module, root <> "/properties/" <> field_name)

      _ ->
        {:error, typedef}
    end
  end

  defp field(_root, {:type, _lineno, :map_field_exact, [{:atom, _, :__struct__} | _]}) do
    nil
  end

  defp field(root, {:type, _lineno, :map_field_exact, [{:atom, _, field_name} | typedef]}) do
    {field_name, field_typedef(root, Atom.to_string(field_name), typedef |> hd)}
  end

  def schema(module) do
    field_typedef_object(module, "#")
  end

  def field_typedef_object(module, name) do
    import Enum, only: [map: 2, reject: 2]

    {:ok, [type: typedef]} = Code.Typespec.fetch_types(module)
    {:t, {:type, _lineno, :map, fields}, []} = typedef

    properties = fields |> map(&field(name, &1)) |> reject(&is_nil/1) |> Map.new()

    %{
      "$id": name,
      type: "object",
      properties: properties
    }
  end

  def schemaFromModule(module) do
    field_typedef("#", "root", {:remote_type, 0, [{:atom, 0, module}, {:atom, 0, :t}, []]})
  end
end
