defmodule Taskserver do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def deftask(srv, code) do
    GenServer.call(srv, {:deftask, code})
  end

  def starttask(srv, id) do
    GenServer.call(srv, {:starttask, id})
  end

  def get_exec(srv, id) do
    srv |> GenServer.call({:get_exec, id})
  end

  def is_exec_suspended(srv, id) do
    srv |> GenServer.call({:is_exec_suspended, id})
  end

  def enrich(srv, id, result) do
    srv |> GenServer.call({:enrich, id, result})
  end

  def stop(srv) do
    srv |> GenServer.stop()
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:deftask, code}, from, state) do
    id = :erlang.monotonic_time()
    {:reply, {:ok, id}, state |> Map.put_new(id, code)}
  end

  @impl true
  def handle_call({:starttask, task_id}, from, state) do
    exec_id = :erlang.monotonic_time()
    {:reply, {:ok, exec_id}, _eval(state, task_id, exec_id, [])}
  end

  @impl true
  def handle_call({:get_exec, id}, from, state) do
    {:reply, state |> Map.get(id), state}
  end

  @impl true
  def handle_call({:enrich, exec_id, result}, from, state) do
    {task_id, :suspended, transcript} = Map.get(state, exec_id)
    new_transcript = Evaluator.enrich_with_result(transcript, result)
    {:reply, {:ok, exec_id}, _eval(state, task_id, exec_id, new_transcript)}
  end

  defp _eval(state, task_id, exec_id, transcript) do
    code = state |> Map.get(task_id)
    exec_result = code |> Evaluator.eval([], transcript)
    state |> Map.put(exec_id, case exec_result do
      {:value, value, bindings, transcript} -> {task_id, :result, value}
      {:suspension, transcript} -> {task_id, :suspended, transcript}
    end)
  end

  defp _is_exec_suspended(id, state) do
    case state |> Map.get(id) do
      {_, :result, _} -> false
      {_, :suspended, _} -> true
    end
  end

  @impl true
  def handle_call({:is_exec_suspended, id}, from, state) do
    {:reply, _is_exec_suspended(id, state), state}
  end
end
