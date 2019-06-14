defmodule Taskserver do
  use GenServer

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @spec work(any) :: any
  def work(srv) do
    # GenServer.call(srv, :work, [])
    # GenServer.cast(server, request)
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    # Do the desired work here
    IO.puts("I'm doing work")
    IO.puts("I'm doing work")
    IO.puts("I'm doing work")
    IO.puts("I'm doing work")

    # Reschedule once more
    schedule_work()

    {:noreply, state}
  end

  @impl true
  def handle_cast(request, state) do

  end

  defp schedule_work do
    # In 2 hours
    Process.send_after(self(), :work, 2 * 60 * 60 * 1000)
  end
end
