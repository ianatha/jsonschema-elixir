defmodule EvalSandboxTracedTest do
  use ExUnit.Case

  require SandboxAllowOnlyStringReverse
  require EvalSandbox.TracedEvaluator

 test "trace" do
   allowed = """
     s = String.reverse("abc")
   """
   EvalSandbox.TracedEvaluator.eval(allowed, SandboxAllowOnlyStringReverse)
 end

  # test "trace2" do
  #   allowed = """
  #     Enum.map(["hello", "bye"], fn x -> IO.inspect(String.reverse(x)) end)
  #   """
  #   EvalSandbox.TracedEvaluator.eval(allowed, SandboxAllowOnlyStringReverse)
  # end

end
