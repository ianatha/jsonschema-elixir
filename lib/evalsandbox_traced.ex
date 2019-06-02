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
    {:ok, quoted_code} = Code.string_to_quoted(string)
    code = EvalSandbox.RestrictedEvaluator.namespaced(namespace, update_meta(quoted_code))

    traced_evaluate(code)
  end

  defp tracer_loop(ignore_pid) do
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
        tracer_loop(ignore_pid)
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
        tracer_loop(ignore_pid)
      x ->
        IO.inspect({:x, x})
        tracer_loop(ignore_pid)
    end
  end

  def traced_evaluate(quoted_code) when is_tuple(quoted_code) do
    Tap.call(SandboxAllowOnlyStringReverse.String.reverse(_), max: 100)
    parent = self()

    _tracer = spawn fn ->
      tracer_loop(parent)
    end

    #:erlang.trace_pattern({IO, :_, :_}, [ { :_, [], [{:return_trace}] } ], [])
    #:erlang.trace_pattern({String, :_, :_}, [ { :_, [], [{:return_trace}] } ], [])
    #:erlang.trace_pattern({SandboxAllowOnlyStringReverse.String, :_, :_}, [ { :_, [], [{:return_trace}] } ], [])
    #:erlang.trace_pattern({:_, :_, :_}, [ { :_, [], [{:return_trace}] } ], [])
    #:erlang.trace(parent, true, [:call, :set_on_spawn, :monotonic_timestamp, {:tracer, tracer}])

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
end
