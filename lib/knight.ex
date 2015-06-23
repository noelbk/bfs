defmodule KnightsTour do
	defmodule Model do
		defstruct count: 0, visited: nil, pos: nil, rows: nil, cols: nil
	end

	defimpl String.Chars, for: Model do
		def to_string(x), do: inspect(x)
	end
	
	def init(rows, cols) do
		%Model{rows: rows, cols: cols, visited: :array.new(rows*cols, default: false, fixed: true)}
	end

	defp visit_count(model) do
		model.count
	end

	defp visit(model, {i,j} = pos) do
 		idx = (i-1) * model.cols + (j-1)
		%{model |
			visited: :array.set(idx, true, model.visited),
			count: model.count + 1,
			pos: pos}
	end

	defp visited?(model, {i,j} = pos) do
 		idx = (i-1) * model.cols + (j-1)
		:array.get(idx, model.visited)
	end
																							 
	def next(path, model) do
		cond do
			visit_count(model) == model.rows * model.cols ->
				{:stop, "got it"}

			model.pos == nil ->
				for i <- 1..round(model.rows/2),
				j <- 1..round(model.cols/2) do
					pos = {i, j}
					:ok = Bfs.next(path, visit(model, pos), "start at #{i},#{j}")
				end
				:ok
				
		  {i0,j0} = model.pos ->
				for transpose <- [true, false], di <- [-2, 2], dj <- [-1, 1] do
					if transpose do
						{di, dj} = {dj, di}
					end
					pos = {i, j} = {i0+di, j0+dj}
					if i>0 and i<=model.rows and j>0 and j<=model.cols and not visited?(model, pos) do
						# debug
						#IO.puts("move delta=#{di},#{dj} from #{i0},#{j0} to #{i},#{j} seen #{visit_count(model)}")
						
						:ok = Bfs.next(path, visit(model, pos), "move to #{i},#{j}")
					end
  			end
				:ok
		end
	end

	def run(rows \\ 4, cols \\ 5) do
		if cols == nil do
			cols = rows
		end
		Bfs.run(init(rows, cols), &next/2)
	end
end
