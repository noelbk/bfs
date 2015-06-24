defmodule TryHardN do
	"""
TryHardN problem example for BFS

Given a set of buckets of different sizes, find a sequence of pours
and empties that get a target volume into another bucket.  For
example, given a 3 and a 5 liter bucket, find out how to get 4 liters
into one bucket.
"""
  defmodule Model do defstruct sizes: [], values: [], goals: [] end

	defimpl String.Chars, for: Model do
		def to_string(x), do: inspect(x)
	end
	
	def init(sizes, goals) do
		size_map = Enum.with_index(sizes) |> Enum.into(%{}, fn {size, idx} -> {idx, size} end)
		value_map = Enum.with_index(sizes) |> Enum.into(%{}, fn {_size, idx} -> {idx, 0} end)
		%Model{sizes: size_map, values: value_map, goals: goals}
	end
																							 
	def next(path, model) do
		try do
			for i <- Map.keys(model.sizes) do
				# test for stopping conditions
				model.values[i] < 0  and throw "ERROR! values[#{i}]=#{model.values[i]} < 0"
				model.values[i] > model.sizes[i] and throw "ERROR! values[#{i}]=#{model.values[i]} > sizes[#{i}]==#{model.sizes[i]}"
				for goal <- model.goals do
					model.values[i] == goal and throw "Success! got #{goal} liters in bucket #{i}"
				end
				
				# next steps
				:ok = Bfs.next(path, %{model | values: Map.put(model.values, i, model.sizes[i])}, 
											 "empty #{i}:#{model.values[i]}/#{model.sizes[i]}")
				:ok = Bfs.next(path, %{model | values: Map.put(model.values, 0, 0)}, 
											 "empty #{i}:#{model.values[i]}/#{model.sizes[i]}")
				for j <- Map.keys(model.sizes), j != i do
					n = min(model.values[i], model.sizes[j] - model.values[j])
					:ok = Bfs.next(path, %{model | values: 
																	 model.values
																	 |> Map.update!(i, &(&1 - n))
																	 |> Map.update!(j, &(&1 + n))
																	 }, "pour #{n} from #{i}:#{model.values[i]}/#{model.sizes[i]}" <>
						" to #{j}:#{model.values[j]}/#{model.sizes[j]}")
				end
			end
			:ok
		catch stop -> {:stop, stop}
		end
	end

	def start(sizes \\ [3,5], goals \\ [4], opts \\ []) do
		Bfs.start(init(sizes, goals), &next/2, opts)
	end
end

