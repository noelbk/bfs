defmodule Bfs do

	@moduledoc """

Breadth-first search for exploring all possible states of a system.
It takes an initial state and a next function.  The next function
generates all possible next moves from a state.  The next states are
fed back to BFS which farms them out to a pool of workers.

		bfs = Bfs.start(initial_state, next_func, opts)
		Bfs.status(bfs)
		Bfs.stop(bfs)

See examples `knight.ex` and `tryhard2.ex`

		iex -S mix
		pid = KnightsTour.start(5, 5)
		(wait 80 seconds or so)
		got it
		start
		start at 1,1
		move to 3,2
		...

  """

	defmodule PathState do
		defstruct [
			pid: nil, 
			steps: [], 
			next: nil
		]
	end

	defmodule PathStep do
		defstruct state: nil, note: nil
	end

	defmodule RunState do
		defstruct [
			tried: HashSet.new(), 
			workers: [], 
			work_count: 0, 
			skip_count: 0, 
			state_count: 0,
			last_state: nil,
		]
	end
	
  @doc """
  start a bfs search, returns pid of bfs process.

  `initial_state` can be anything, it is passed to next_func

	`next_func` generates all possible next states from state and calls
	`Bfs.next`(path, state, msg, next_func) or returns {:stop, note}

  `opts`:
  - sync: boolean - run synchronously.  default: false
  - workers: int  - start N workers.  default: cores * 1.5
    
  See also `status`, `stop`
  """
	def start(initial_state, next_func, opts \\ []) do
		if opts[:sync] do
			run(initial_state, next_func, opts)
		else
			spawn_link(__MODULE__, :run, [initial_state, next_func, opts])
		end
	end

  @doc "get status of a running bfs search"
	def status(bfs) do
		send(bfs, {:status, self})
		receive do
			{:status, status} -> status
		end
	end

  @doc "stop a running bfs search"
	def stop(bfs) do
		send(bfs, :stop)
	end

	def run(initial_state, next_func, opts) do
		flush
		run_state = %RunState{}
		run_state = spawn_workers(run_state, opts[:workers])
		path = %PathState{pid: self}
		t0 = :os.timestamp
		next(path, initial_state, "start", next_func)
		case loop(run_state) do
			{:stop, path, run_state} -> 
				dt = :timer.now_diff(:os.timestamp, t0) / 1.0e6
				num_states = Set.size(run_state.tried)
				[ %{note: note, state: nil} | steps ] = path.steps
				IO.puts("Stopped after #{num_states} states after #{dt} secs")
				IO.puts(note)
				for step <- Enum.reverse(steps) do
					IO.puts(step.note)
				end
																															
		  {:end, run_state} ->
				dt = :timer.now_diff(:os.timestamp, t0) / 1.0e6
				num_states = Set.size(run_state.tried)
				IO.puts("complete, found #{num_states} states after #{dt} secs")
		end
		for worker <- run_state.workers do
			Process.unlink(worker)
			Process.exit(worker, :kill)
		end
		
		:ok
	end

	def stop(path, note) do
		path = %{path | steps: [%PathStep{state: nil, note: note} | path.steps]}
		send(self, {:stop, path})
	end
	
	def next(path, state, note \\ "", next_func \\ nil) do
		path = Map.update!(path, :steps, &([%PathStep{state: state, note: note} | &1]))
		if next_func do
			path = Map.put(path, :next, next_func)
		end
		send(path.pid, {:next, path})
		:ok
	end
		
	defp flush() do
		receive do
			_msg -> flush()
			after 0 -> :ok
		end
	end

	def spawn_workers(run_state) do
		spawn_workers(run_state, round(:erlang.system_info(:logical_processors_available)*1.5))
	end

	def spawn_workers(run_state, nil) do
		spawn_workers(run_state)
	end

	def spawn_workers(run_state, n) do
		spawn_workers(run_state, n, [])
	end

	defp spawn_workers(run_state, 0, workers) do
		Map.put(run_state, :workers, workers)
	end
			
	defp spawn_workers(run_state, n, workers) do
		worker = spawn_link(&worker/0)
		spawn_workers(run_state, n-1, [worker | workers]) 
	end

	defp worker() do
		receive do
		  {:work, reply_pid, work_id, next, path, state} -> 
				reply = case next.(path, state) do
									{:stop, note} -> {:stop, path, note}
									msg -> msg
								end
				send(reply_pid, {:work_done, work_id, reply})
				loop(worker)
			
			# blow up on unexpected messages
			msg -> raise(ArgumentError, message: "unexpected message in worer #{inspect msg}")
		end
	end

	defp loop(run_state) do
		receive do
			{:status, pid} ->
				send(pid, {:status, run_state})
				loop(run_state)

			{:stop, path} ->
				flush
				{:stop, path, run_state}

		  {:work_done, _work_id, result} -> 
				run_state = Map.update!(run_state, :work_count, &(&1 - 1))
				case result do
					{:stop, path, note} -> stop(path, note)
					:ok -> :ok
				end
				loop(run_state)
			
		  {:next, path} -> 
				%PathState{steps: [%PathStep{state: state} | _tail], next: next} = path
				# skip state if its nil or if I've already processed it
				if Set.member?(run_state.tried, state) do
					#IO.puts("Skipping #{state}")
					run_state = Map.update!(run_state, :skip_count, &(&1 + 1))
				else
					# remember I already processed this state
					run_state = Map.update!(run_state, :tried, &Set.put(&1, state))
					run_state = Map.put(run_state, :last_state, state)
					run_state = Map.update!(run_state, :state_count, &(&1 + 1))

					# pick a worker to run it
					[worker | rest] = run_state.workers
					run_state = Map.put(run_state, :workers, rest ++ [worker])
					run_state = Map.update!(run_state, :work_count, &(&1 + 1))
					send(worker, {:work, self, worker, next, path, state})
				end
				loop(run_state)

		after run_state.work_count > 0 && :infinity || 0 -> 
				# stop when there are no new messages and all workers have completed
				{:end, run_state}
		end
	end
end
