defmodule EvalSandbox.Traced2Evaluator do
  require Tap

  defguard is_literal(x) when is_atom(x) or is_binary(x) or is_bitstring(x) or is_boolean(x) or is_number(x) or is_list(x)

  def random_func(x) do
    #IO.inspect({:invokation, c, :result, x})
    x
  end

  defp instrument(literal, acc) when is_literal(literal) do
    {literal, acc}
  end

  defp instrument({_1, _2} = literal, acc) do
    {literal, acc}
  end

  defp instrument({{:., _fnmeta, fnpath}, _meta, args} = code, acc) when is_list(fnpath) and is_list(args) do
    #new_code = quote do: EvalSandbox.Traced2Evaluator.random_func(unquote(Macro.escape(code)), unquote(code))
    new_code = quote do: EvalSandbox.Traced2Evaluator.random_func(unquote(code))
   # IO.inspect({:old_code_str, code |> Macro.expand(__ENV__) |> Macro.to_string, :new_code_str, new_code |> Macro.expand(__ENV__) |> Macro.to_string})
    {new_code, acc}
  end

  defp instrument({fnname, _meta, args} = code, acc) when is_atom(fnname) and is_list(args) do
    {code, acc}
  end

  defp instrument({varname, _meta, context} = code, acc) when is_atom(varname) and is_atom(context) do
    {code, acc}
  end

  def instrument(code) do
    Macro.postwalk(code, 0, &instrument/2)
  end

  # defp annotate_node(literal, acc) do
  #   case literal do
  #     {:=, meta, args} -> {{:=, Keyword.put(meta, :i, acc), args}, acc + 1}
  #     {{:., meta1, args1}, meta2, args2} -> {{{:., meta1, args1}, Keyword.put(meta2, :i, acc), args2}, acc + 1}
  #     literal -> {literal, acc}
  #   end
  # end
end
