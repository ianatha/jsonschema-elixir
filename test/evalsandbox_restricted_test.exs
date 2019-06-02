defmodule EvalSandboxRestrictedTest do
  use ExUnit.Case

  require SandboxAllowOnlyStringReverse
  require EvalSandbox.RestrictedEvaluator

 test "allowed works" do
   allowed = """
     s = String.reverse("abc")
   """
   assert(EvalSandbox.RestrictedEvaluator.evaluate_restricted(allowed, SandboxAllowOnlyStringReverse) == "cba")
 end

 test "disallowed raises exception" do
   assert_raise UndefinedFunctionError, fn ->
     disallowed = """
       s = String.split("a bc", " ")
     """
     EvalSandbox.RestrictedEvaluator.evaluate_restricted(disallowed, SandboxAllowOnlyStringReverse)
   end
 end

 test "disallowed erlang-style exception" do
   assert_raise CompileError, fn ->
     disallowed = """
       s = :string.split("a bc", " ")
     """
     EvalSandbox.RestrictedEvaluator.evaluate_restricted(disallowed, SandboxAllowOnlyStringReverse)
   end
 end

 test "disallowed call in interpolated string" do
   assert_raise CompileError, fn ->
     disallowed = """
       s = "Hello \#{System.monotonic_time()}"
     """
     EvalSandbox.RestrictedEvaluator.evaluate_restricted(disallowed, SandboxAllowOnlyStringReverse)
   end
 end

 # test "allowed call in interpolated string" do
 # allowed = """
 #     s = "Hello \#{String.reverse(\"abc\")}"
 #   """
 #   assert(EvalSandbox.RestrictedEvaluator.evaluate_restricted(allowed, SandboxAllowOnlyStringReverse) == "Hello cba")
 # end
end
