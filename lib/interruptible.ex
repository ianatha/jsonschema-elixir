defmodule Interruptible do
  defmacro defasync(name, do: block) do
    x = Macro.escape(block)
    caller = Macro.escape(__CALLER__)

    quote do
      def unquote(name) do
        # IO.inspect({:async, unquote(x), unquote(caller)})
        unquote(instrument(block))
      end
    end
  end

  defguard is_literal(x)
           when is_atom(x) or is_binary(x) or is_bitstring(x) or is_boolean(x) or is_number(x) or
                  is_list(x)

  defp x(c) when is_literal(c), do: c
  defp x({_1, _2} = c), do: c
  defp x({_varname, _meta, nil} = c), do: c

  defp x({fnname, _meta, args} = c) when is_atom(fnname) and is_list(args) do
    if not Macro.special_form?(fnname, length(args)) do
      quote do
        # IO.inspect({:call, unquote(fnname)})
        unquote(c)
      end
    else
      c
    end
  end

  defp x({{:., _fnmeta, fnpath}, _meta, args} = c) when is_list(fnpath) and is_list(args) do
    quote do: EvalSandbox.Traced2Evaluator.random_func(unquote(c))
    # Macro.special_form?(name, arity)
  end

  defp instrument(code, acc) do
    {x(code), acc}
  end

  defp instrument(code) do
    Macro.postwalk(code, 0, &instrument/2)
  end

end
