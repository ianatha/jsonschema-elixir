defmodule EvalSandbox.TracedEvaluator do
  defmacro eval(string, namespace) do
    caller_env = Macro.escape(__CALLER__)

    quote do:
            EvalSandbox.TracedEvaluator.evaluate(
              unquote(string),
              unquote(namespace),
              unquote(caller_env)
            )
  end

  def evaluate(string, namespace, env) when is_binary(string) do
    IO.puts("\n\nEvaluating:\n>>>>>>>\n#{string}\n<<<<<<<\n...\n")
    {code, bindings} = namespaced(string, namespace, env)
    evaluate(code, bindings)
  end

  defp evaluate(quoted_code, bindings) when is_tuple(quoted_code) do
      Code.eval_quoted(
        quoted_code,
        bindings,
        aliases: [],
        requires: [],
        functions: [],
        macros: []
      )
  end

  defp annotate_node(literal, acc) do
    case literal do
      {:=, meta, args} -> {{:=, Keyword.put(meta, :i, acc), args}, acc + 1}
      {{:., meta1, args1}, meta2, args2} -> {{{:., meta1, args1}, Keyword.put(meta2, :i, acc), args2}, acc + 1}
      literal -> {literal, acc}
    end
  end

  defp update_meta(q) do
    Macro.postwalk(q, 0, &annotate_node/2)
  end

  defp remove_meta(q) do
    remove_line = fn node ->
      Macro.update_meta(node, &Keyword.delete(&1, :line))
    end

    Macro.prewalk(q, remove_line)
  end

  defp do_eval(node, acc) do
    IO.puts(">>>===")
    IO.inspect(node)
    {_, meta, _} = node
    {result, bindings} = try do
      {result, bindings} = Code.eval_quoted(node, acc)
      filtered_acc = acc |> Enum.filter(fn {k, _} -> not String.starts_with?(Atom.to_string(k), "__") end)

      {result, Keyword.put(bindings, String.to_atom("__#{meta[:i]}"), [
        bindings_pre: filtered_acc,
        code_pre: node,
        code_after: result,
      ])}
    rescue
      CompileError -> {node, acc}
    end

    IO.inspect({result, bindings})

    {result, bindings}
  end

  defguard is_literal(x)
           when is_atom(x) or is_binary(x) or is_bitstring(x) or is_boolean(x) or is_float(x)

  defp maybeeval(literal, acc) do
    case literal do
      {varname, meta, nil} when is_atom(varname) -> {{varname, meta, nil}, acc}
      {:=, meta, args} -> do_eval(literal, acc)
      {{:., meta, ivok_target_args}, meat2, args2} -> do_eval(literal, acc)
      literal when is_literal(literal) -> {literal, acc}
      literal -> {literal, acc}
    end
  end

  defp namespaced(string, namespace, env) when is_binary(string) do
    {:ok, quoted_code} = Code.string_to_quoted(string)
    code = update_meta(remove_meta(quoted_code))

    IO.inspect(code)
    {result_code, bindings} = Macro.postwalk(code, [ctx: nil], &maybeeval/2)
    IO.inspect(result_code)
    IO.inspect(bindings)

    # do_namespace3(code, namespace)
    {result_code, bindings}
  end
end
