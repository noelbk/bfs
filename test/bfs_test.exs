defmodule BfsTest do
  use ExUnit.Case

  test "spawn workers" do
    run_state = %Bfs.RunState{}
		run_state = Bfs.spawn_workers(run_state)
		[worker | _ ] = run_state.workers
		next = fn(_path, _state) -> 
			{:stop, "done"}
		end
		path = %Bfs.PathState{}
		state = 0
		send(worker, {:work, self, worker, next, path, state})

  end
end
