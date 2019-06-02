defmodule EvalSandbox.RestrictedEvaluator do
  def evaluate_restricted(code_string, namespace) when is_binary(code_string) do
    evaluate_restricted(namespaced(namespace, Code.string_to_quoted!(code_string)))
  end

  defp evaluate_restricted(namespaced_code) when is_tuple(namespaced_code) do
    {result, _binding} =
      Code.eval_quoted(
        namespaced_code,
        aliases: [],
        requires: [],
        functions: [],
        macros: []
      )

    result
  end

  defp do_namespace(namespace), do: &do_namespace(namespace, &1)

  defp do_namespace(namespace, code) do
    case code do
      {:__aliases__, meta, aliases} ->
        {:__aliases__, meta, Module.concat(namespace ++ aliases)}
      {:., meta, callref} ->
        case hd(callref) do
          {:__aliases__, _, _} -> {:., meta, callref}
          a when is_atom(a) -> {:., meta, [:SANDBOX_SAGT_VERBOTEN] ++ callref}
        end
      _ -> code
    end
  end

  def namespaced(namespace, code) do
    Macro.prewalk(code, do_namespace(Module.split(namespace)))
  end
end
