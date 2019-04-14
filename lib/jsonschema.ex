defmodule JSONSchema do
  @type jsonscheme_type :: :integer | :number | :boolean | :array | :string | :object

  @type schema_result :: %{
          required(:"$id") => String.t(),
          optional(:properties) => map,
          required(:type) => jsonscheme_type
        }

  @spec field_typedef_simple(String.t(), String.t(), atom, keyword()) :: schema_result
  defp field_typedef_simple(root, name, type, meta \\ []) do
    %{
      "$id": root <> "/properties/" <> name,
      type: type
    }
    |> Map.merge(Enum.into(meta, %{}))
  end

  @spec get_meta(atom, atom) :: []
  defp get_meta(module, field_name_atom) do
    apply(module, :__meta, [])[field_name_atom]
  end

  @spec field_typedef(String.t(), atom, map, keyword) :: {:error, map} | schema_result
  defp field_typedef(root, field_name_atom, typedef, meta \\ []) do
    field_name = field_name_atom |> Atom.to_string()

    case typedef do
      {:type, _lineno, :integer, []} ->
        field_typedef_simple(root, field_name, :integer, meta)

      {:type, _lineno, :float, []} ->
        field_typedef_simple(root, field_name, :number, meta)

      {:type, _lineno, :boolean, []} ->
        field_typedef_simple(root, field_name, :boolean, meta)

      {:type, _lineno, :list, subtype} ->
        Map.merge(field_typedef_simple(root, field_name, :array), %{
          items: field_typedef(root, String.to_atom(field_name <> "/items"), hd(subtype))
        })

      {:remote_type, _lineno, [{:atom, 0, String}, {:atom, 0, :t}, []]} ->
        field_typedef_simple(root, field_name, :string, meta)

      {:remote_type, _lineno, [{:atom, 0, module}, {:atom, 0, typename}, []]} ->
        field_typedef_remotetype(module, typename, root <> "/properties/" <> field_name)

      _ ->
        {:error, typedef}
    end
  end

  @spec field(atom, String.t(), {:type, integer, :map_field_exact, nonempty_list}) ::
          nil | {:error, map} | {atom, map}

  defp field(_module, _root, {:type, _lineno, :map_field_exact, [{:atom, _, :__struct__} | _]}) do
    nil
  end

  defp field(module, root, {:type, _lineno, :map_field_exact, [{:atom, _, field_name} | typedef]}) do
    field_schema = field_typedef(root, field_name, typedef |> hd, get_meta(module, field_name))

    case field_schema do
      {:error, _} -> field_schema
      _ -> {field_name, field_schema}
    end
  end

  @spec field_typedef_remotetype(atom, atom, String.t()) :: schema_result
  def field_typedef_remotetype(module, typename, name) do
    {:ok, types_kw} = Code.Typespec.fetch_types(module)
    types = Enum.map(types_kw, fn {:type, {tname, tspec, []}} -> {tname, tspec} end)

    case types[typename] do
      {:type, _lineno, :map, fields} ->
        %{
          "$id": name,
          type: :object,
          properties:
            fields |> Enum.map(&field(module, name, &1)) |> Enum.reject(&is_nil/1) |> Map.new()
        }

      _ ->
        {:error, types[typename]}
    end
  end

  @spec schema(atom) :: schema_result
  def schema(module) do
    field_typedef_remotetype(module, :t, "#")
  end

  @spec schema_and_form(atom) :: %{:schema => schema_result, :form => any}
  def schema_and_form(module) do
    %{
      schema: schema(module),
      form: [
        %{
          key: "name"
        },
        %{
          key: "password"
        }
      ]
    }
  end
end
