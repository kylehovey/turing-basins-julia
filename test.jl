using NNlib
using ImageView
using Gtk
using PyPlot
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

function save_run(born::Array{Int8}, live::Array{Int8}, steps::Int64=256, size=100, save_file=false)
  universe = rand(Float16, size, size)
  universe[universe.>0.5] .= 1
  universe[universe.<=0.5] .= 0
  name_prefix = "b" * join(born, "") * "s" * join(live, "")
  kernel = ones(Float16, 3, 3)
  kernel[2, 2] = 0

  complexities = []

  if save_file
    for step = 1:steps
      fname = name_prefix * "_step_" * string(step) * ".png"
      PNGFiles.save(fname, universe)
      universe = ca_update(universe, [born, live], kernel)
    end
  else
    for _ = 1:steps
      buf = IOBuffer()
      PNGFiles.save(buf, universe)
      append!(complexities, length(take!(buf)))
      universe = ca_update(universe, [born, live], kernel)
    end
  end

  complexities
end
