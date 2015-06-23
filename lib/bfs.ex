defmodule Bfs do
	defmodule RunState do
		defstruct tried: HashSet.new()
	end

	defmodule PathState do
		defstruct steps: [], next: nil
	end

	defmodule PathStep do
		defstruct state: nil, note: nil
	end

	def run(state, next_func) do
		flush
		next(%PathState{}, state, "start", next_func)
		case loop(%RunState{}) do
			{:stop, path, run_state} -> 
				num_states = Set.size(run_state.tried)
				[ %{note: note, state: nil} | steps ] = path.steps
				IO.puts("Stopped after #{num_states} states at path: #{note}")
				for step <- Enum.reverse(steps) do
					:io.format("~-20s ~s~n", [step.note, "#{step.state}"])
				end
																															
		  {:end, run_state} ->
				num_states = Set.size(run_state.tried)
				IO.puts("complete, found #{num_states} states")
				for state <- Set.to_list(run_state.tried) do
					IO.puts("#{state}")
				end
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
		send(self, {:next, path})
		:ok
	end
		
	defp flush() do
		receive do
			_msg -> flush()
			after 0 -> :ok
		end
	end

	defp loop(run_state) do
		receive do
			{:stop, path} ->
				flush
				{:stop, path, run_state}
			
		  {:next, path} -> 
				%PathState{steps: [%PathStep{state: state} | tail], next: next} = path
				# skip state if its nil or if I've already processed it
				if Set.member?(run_state.tried, state) do
					#IO.puts("Skipping #{state}")
				else
					run_state = Map.update!(run_state, :tried, &Set.put(&1, state))
					case next.(path, state) do
						{:stop, note} -> stop(path, note)
						:ok -> :ok
					end
				end
				loop(run_state)
		after 0 -> {:end, run_state}
		end
	end
end
