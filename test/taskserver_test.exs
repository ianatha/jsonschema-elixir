defmodule TaskserverTest do
  use ExUnit.Case

  import Taskserver

  test "simple exec" do
    code = """
      x = 1 + 3
      x
    """

    {:ok, taskserver} = start_link([])
    {:ok, task_id} = deftask(taskserver, code)
    {:ok, exec_id} = starttask(taskserver, task_id)
    assert {task_id, :result, 4} == get_exec(taskserver, exec_id)
    stop(taskserver)
  end

  test "suspended exec" do
    code = """
      x = 1
      y = EvaluatorTest.suspending_function()
      z = EvaluatorTest.suspending_function()
      x + y + z
    """

    {:ok, taskserver} = start_link([])
    {:ok, task_id} = deftask(taskserver, code)
    {:ok, exec_id} = starttask(taskserver, task_id)

    assert is_exec_suspended(taskserver, exec_id)

    enrich(taskserver, exec_id, 2)
    assert is_exec_suspended(taskserver, exec_id)

    enrich(taskserver, exec_id, 3)
    assert not is_exec_suspended(taskserver, exec_id)

    assert {task_id, :result, 6} == get_exec(taskserver, exec_id)

    stop(taskserver)
  end

  test "two suspended execs with the same task" do
    code = """
      x = 1
      y = EvaluatorTest.suspending_function()
      z = EvaluatorTest.suspending_function()
      x + y + z
    """

    {:ok, taskserver} = start_link([])
    {:ok, task_id} = deftask(taskserver, code)
    {:ok, exec_id_1} = starttask(taskserver, task_id)
    {:ok, exec_id_2} = starttask(taskserver, task_id)

    enrich(taskserver, exec_id_1, 1)
    enrich(taskserver, exec_id_2, 2)

    enrich(taskserver, exec_id_1, 1)
    enrich(taskserver, exec_id_2, 3)

    assert {task_id, :result, 3} == get_exec(taskserver, exec_id_1)
    assert {task_id, :result, 6} == get_exec(taskserver, exec_id_2)

    stop(taskserver)
  end

  test "two suspended execs with two tasks" do
    code_1 = """
      x = 1
      y = EvaluatorTest.suspending_function()
      z = EvaluatorTest.suspending_function()
      x + y + z
    """

    code_2 = """
      x = 2
      y = EvaluatorTest.suspending_function()
      z = EvaluatorTest.suspending_function()
      x * y * z
    """

    {:ok, taskserver} = start_link([])
    {:ok, task_id_1} = deftask(taskserver, code_1)
    {:ok, task_id_2} = deftask(taskserver, code_2)
    {:ok, exec_id_1} = starttask(taskserver, task_id_1)
    {:ok, exec_id_2} = starttask(taskserver, task_id_2)

    enrich(taskserver, exec_id_1, 2)
    enrich(taskserver, exec_id_2, 2)

    enrich(taskserver, exec_id_1, 3)
    enrich(taskserver, exec_id_2, 4)

    assert {task_id_1, :result, 6} == get_exec(taskserver, exec_id_1)
    assert {task_id_2, :result, 16} == get_exec(taskserver, exec_id_2)

    stop(taskserver)
  end



end
