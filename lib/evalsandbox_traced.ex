defmodule EvalSandbox.TracedEvaluator do
  defmacro eval(string, namespace) do
    caller_env = Macro.escape(__CALLER__)
    quote do: Exbox.Evaluator.evaluate(unquote(string), unquote(namespace), unquote(caller_env))
  end

  def evaluate(string, namespace, env) when is_binary(string) do
    evaluate(namespaced(string, namespace, env))
  end

  defp evaluate(quoted_code) when is_tuple(quoted_code) do
    {result, _binding} =
      Code.eval_quoted(
        quoted_code,
        aliases: [],
        requires: [],
        functions: [],
        macros: []
      )

    result
  end

  defp remove_meta(q, env) do
    remove_line = fn node ->
      Macro.update_meta(node, &Keyword.delete(&1, :line))
    end

    Macro.prewalk(q, remove_line)
  end

  defp remove_meta(q) do
    remove_line = fn node ->
      Macro.update_meta(node, &Keyword.delete(&1, :line))
    end

    Macro.prewalk(q, remove_line)
  end

  defp do_namespace3(code, namespace) do
    Macro.prewalk(code, fn x -> 
      do_namespace2(x, namespace)
    end
    )
  end

  defp do_namespace2({:__aliases__, meta, aliases}, namespace) do
    {
      :__aliases__,
      meta,
      Module.concat(Module.split(namespace) ++ aliases)
    }
  end


  defp do_namespace2({:__aliases__, meta, aliases}, namespace) do
    {
      :__aliases__,
      meta,
      Module.concat(Module.split(namespace) ++ aliases)
    }
  end

  defp do_namespace2(quoted_code, _namespace) do
    quoted_code
  end

  defp maybeeval({varname, meta, nil}, acc) when is_atom(varname) do
    {{varname, meta, nil}, acc}
  end

 # defp maybeeval({:__block__, meta, statements}) do
 #   {:__block___, meta, statements |> Enum.map(fn stmt ->
 #     IO.puts("stmt#>>>")
 #     IO.inspect(stmt)
 #     IO.puts("\n")
 #     stmt
 #   end)}
 # end


 defp maybeeval({:=, meta, args}, acc) do
  IO.puts(">>>===")
  IO.inspect({:=, meta, args})
  {result, bindings} = Code.eval_quoted({:=, meta, args}, acc)
  IO.inspect({result, bindings})
  
  {{:=, meta, args}, bindings}
 end


 defp maybeeval({{:., meta, ivok_target_args}, meat2, args2}, acc)  do
  IO.puts(">>>CALL")
  IO.inspect({{:., meta, ivok_target_args}, meat2, args2})
  {result, bindings} = Code.eval_quoted({{:., meta, ivok_target_args}, meat2, args2}, acc)
  IO.inspect({result, bindings})


  {result, bindings}
 end

  defguard is_literal(x) when is_atom(x) or is_binary(x) or is_bitstring(x) or is_boolean(x) or is_float(x)

  defp maybeeval(literal, acc) when is_literal(literal) do
    {literal, acc}
  end

  defp maybeeval(literal, acc) do
      {literal, acc}
  end

  defp namespaced(string, namespace, env) when is_binary(string) do
    {:ok, quoted_code} = Code.string_to_quoted(string)

    post_traversal = fn node, acc ->
      #IO.write("#x " <> String.duplicate(" ", acc))
      #IO.inspect(node)

      maybeeval(node, acc)
    end

    IO.inspect(remove_meta(quoted_code))
    Macro.postwalk(remove_meta(quoted_code), [a: 123], post_traversal)

    do_namespace3(quoted_code, namespace)
  end
end
