defmodule EvalSandboxTest do
  use ExUnit.Case

  require TestEvalSandbox
  require EvalSandbox.TracedEvaluator

#  test "trace" do
#    allowed = """
#      s = String.reverse("abc")
#      IO.puts(s)
#      s
#    """
#    EvalSandbox.TracedEvaluator.eval(allowed, TestEvalSandbox)
#  end

  # test "trace2" do
  #   allowed = """
  #     Enum.map(["hello", "bye"], fn x -> IO.inspect(String.reverse(x)) end)
  #   """
  #   EvalSandbox.TracedEvaluator.eval(allowed, TestEvalSandbox)
  # end

end
