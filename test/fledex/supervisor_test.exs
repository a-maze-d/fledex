defmodule Fledex.SupervisorTest do
  use ExUnit.Case

  alias Fledex.Animation.Manager
  alias Fledex.Supervisor

  test "start in supervisor" do
    Supervisor.start_link([])
    assert Process.whereis(Manager) != nil

    Supervisor.stop(:normal)
    assert Process.whereis(Manager) == nil
  end

  test "start through Fledex DSL" do

  end
end
