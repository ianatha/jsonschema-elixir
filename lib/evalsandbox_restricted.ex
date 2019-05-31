defmodule EvalSandbox.RestrictedEvaluator do
  def evaluate_restricted(string, namespace) when is_binary(string) do
    evaluate_restricted(namespaced(string, namespace))
  end

  defp evaluate_restricted(quoted_code) when is_tuple(quoted_code) do
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

  defp do_namespace({:__aliases__, meta, aliases}, namespace) do
    {
      :__aliases__,
      meta,
      Module.concat(Module.split(namespace) ++ aliases)
    }
  end

  defp do_namespace({:., meta, callref}, namespace) do
    case hd(callref) do
      {:__aliases__, _, _} -> {:., meta, callref}
      a when is_atom(a) -> {:., meta, [:Disallowed] ++ callref}
    end
  end

  defp do_namespace(quoted_code, _namespace) do
    #IO.inspect(quoted_code)
    quoted_code
  end

  defp namespaced(string, namespace) when is_binary(string) do
    {:ok, quoted_code} = Code.string_to_quoted(string)

    Macro.prewalk(quoted_code, fn node -> 
      do_namespace(node, namespace)
    end)
  end
end
