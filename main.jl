using NNlib
using ImageView
using Gtk
using Plots
using PNGFiles
using BenchmarkTools

# Adapted from https://rivesunder.github.io/SortaSota/2021/09/27/faster_life_julia.html

function circular_pad(grid)
  padded = zeros(Float16, size(grid)[1] + 2, size(grid)[2] + 2)

  padded[2:end-1, 2:end-1] = grid

  padded[1, 2:end-1] = grid[end, :]
  padded[end, 2:end-1] = grid[1, :]
  padded[2:end-1, end] = grid[:, 1]
  padded[2:end-1, 1] = grid[:, end]
  padded[1, 1] = grid[end, end]
  padded[end, 1] = grid[1, end]
  padded[1, end] = grid[end, 1]
  padded[end, end] = grid[1, 1]


  return padded
end

function nn_convolve(grid, kernel)
  w = reshape(kernel, (size(kernel)[1], size(kernel)[2], 1, 1))
  x = reshape(grid, (size(grid)[1], size(grid)[2], 1, 1))

  return conv(x, w, pad=1)[:, :, 1, 1]
end

function ca_update(grid, rules, kernel)
  moore_grid = nn_convolve(circular_pad(grid), kernel)[2:end-1, 2:end-1]
  new_grid = zeros(size(moore_grid))

  for birth in rules[1]
    new_grid[((moore_grid.==birth).&(grid.!=1))] .= 1
  end

  for survive in rules[2]
    new_grid[((moore_grid.==survive).&(grid.==1))] .= 1
  end

  return new_grid
end

function new_universe(size, threshhold=0.5)
  universe = rand(Float16, size, size)
  universe[universe.>threshhold] .= 1
  universe[universe.<=threshhold] .= 0
  universe
end

function moore_kernel()
  kernel = ones(Float16, 3, 3)
  kernel[2, 2] = 0
  kernel
end

function complexity_procession_of(born, live, steps::Int64=256, size::Int64=100, threshhold=0.5)
  universe = new_universe(size, threshhold)
  kernel = moore_kernel()

  complexities = []

  for _ = 1:steps
    buf = IOBuffer()
    PNGFiles.save(buf, universe)
    append!(complexities, length(take!(buf)))
    universe = ca_update(universe, [born, live], kernel)
  end

  complexities
end

function column_averages(data)
  num_columns = length(data[1])
  averages = [mean([row[i] for row in data]) for i in 1:num_columns]
  return averages
end

function avg_complexity_procession_of(born, live, steps::Int64=256, size::Int64=100, threshhold=0.5, runs=10)
  cs = [complexity_procession_of(born, live, steps, size, threshhold) for _ in 1:runs]
  column_averages(cs)
end

function save_run(born, live, steps::Int64=256, size=100, threshhold=0.5)
  universe = new_universe(size, threshhold)
  name_prefix = "b" * join(born, "") * "s" * join(live, "")
  kernel = moore_kernel()

  for step = 1:steps
    fname = name_prefix * "_step_" * string(step) * ".png"
    PNGFiles.save(fname, universe)
    universe = ca_update(universe, [born, live], kernel)
  end
end

function plot_run(born, live, steps, size)
  threshholds = 0:0.1:1
  cs = [avg_complexity_procession_of(born, live, steps, size, threshhold) for threshhold in threshholds]

  plot(cs)
end

plot_run([0, 1, 2, 3, 6, 8], [1, 2, 3, 6], 100, 256)
