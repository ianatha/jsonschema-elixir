defmodule EvalSandbox.TracedEvaluator do
  require Tap

  defmacro eval(string, namespace) do
    quote do:
            EvalSandbox.TracedEvaluator.evaluate(
              unquote(string),
              unquote(namespace)
            )
  end

  def evaluate(string, namespace) when is_binary(string) do
    {code, bindings} = namespaced(string, namespace)
    evaluate(code, bindings)
  end

  defp loop(ignore_pid) do
    receive do
      {:trace_ts, sender_pid, :call, args, ts} ->
        unless sender_pid == ignore_pid, do: IO.inspect({
          ts,
          :trace,
          sender_pid,
          :call,
          :args,
          args
        })
        loop(ignore_pid)
      {:trace_ts, sender_pid, :return_from, args, returnval, ts} ->
        unless sender_pid == ignore_pid, do: IO.inspect({
          ts,
          :trace,
            sender_pid,
          :return_from,
          :args,
          args,
          :return_val,
          returnval
        })
        loop(ignore_pid)
      x ->
        IO.inspect({:x, x})
        loop(ignore_pid)
    end
  end

  def evaluate(quoted_code, _) when is_tuple(quoted_code) do
    #Tap.call(IO.inspect(_), max: 100)
    parent = self()

    tracer = spawn fn ->
      loop(parent)
    end

    #:erlang.trace_pattern({IO, :_, :_}, [ { :_, [], [{:return_trace}] } ], [])
    #:erlang.trace_pattern({String, :_, :_}, [ { :_, [], [{:return_trace}] } ], [])
    :erlang.trace_pattern({:_, :_, :_}, [ { :_, [], [{:return_trace}] } ], [])
    :erlang.trace(parent, true, [:call, :set_on_spawn, :monotonic_timestamp, {:tracer, tracer}])

    IO.inspect({ :hello_from_parent, parent })
    IO.inspect({ :hello_from_parent2, parent })


    tracee = spawn fn ->
      IO.inspect({ :hello_from_tracee, self() })
      IO.inspect({ :hello_from_tracee2, self() })
      Code.eval_quoted(
        quoted_code,
        aliases: [],
        requires: [],
        functions: [],
        macros: []
      )
    end
    IO.inspect({ :tracee_pid, tracee })
    :timer.sleep(1000)
  end


  #defp evaluate(quoted_code, bindings) when is_tuple(quoted_code) do
  #    Code.eval_quoted(
  #      quoted_code,
  #      bindings,
  #      aliases: [],
  #      requires: [],
  #      functions: [],
  #      macros: []
  #    )
  #end

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

 ## defp remove_meta(q) do
 ##   remove_line = fn node ->
 ##     Macro.update_meta(node, &Keyword.delete(&1, :line))
 ##   end
##
 ##   Macro.prewalk(q, remove_line)
 ## end
##
 ## defp do_eval(node, acc) do
 ##   {_, meta, _} = node
 ##   {result, bindings} = try do
 ##     {result, bindings} = Code.eval_quoted(node, acc)
 ##     filtered_acc = acc |> Enum.filter(fn {k, _} -> not String.starts_with?(Atom.to_string(k), "__") end)
##
 ##     {result, Keyword.put(bindings, String.to_atom("__#{meta[:i]}"), [
 ##       bindings_pre: filtered_acc,
 ##       code_pre: node,
 ##       code_after: result,
 ##     ])}
 ##   rescue
 ##     CompileError -> {node, acc}
 ##   end
##
 ##   {result, bindings}
 ## end
##
 ## defguard is_literal(x)
 ##          when is_atom(x) or is_binary(x) or is_bitstring(x) or is_boolean(x) or is_float(x)
##
 ## defp maybeeval(literal, acc) do
 ##   case literal do
 ##     {varname, meta, nil} when is_atom(varname) -> {{varname, meta, nil}, acc}
 ##     {:=, meta, args} -> do_eval(literal, acc)
 ##     {{:., meta, ivok_target_args}, meat2, args2} -> do_eval(literal, acc)
 ##     literal when is_literal(literal) -> {literal, acc}
 ##     literal -> {literal, acc}
 ##   end
 ## end

  defp namespaced(string, _namespace) when is_binary(string) do
    {:ok, quoted_code} = Code.string_to_quoted(string)
    code = update_meta(quoted_code)

    #IO.inspect(code)
    #{result_code, bindings} = Macro.postwalk(code, [ctx: nil], &maybeeval/2)
    #IO.inspect(result_code)
    #IO.inspect(bindings)

    {code, []}
  end
end
