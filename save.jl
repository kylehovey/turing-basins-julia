
using NNlib
using ImageView
using Gtk
using PlotlyJS
using PlotlyBase
using DataFrames
using PNGFiles
using BenchmarkTools
using IterTools
using Serialization
using ProgressMeter
using Base.Threads
using Distributed

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

  buf = IOBuffer()
  for _ = 1:steps
    PNGFiles.save(buf, universe)
    append!(complexities, UInt16(length(take!(buf))))
    universe = ca_update(universe, [born, live], kernel)
  end

  complexities
end

function column_averages(data)
  num_columns = length(data[1])
  averages = [Float16(mean([row[i] for row in data])) for i in 1:num_columns]
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
    fname = "saved/" * name_prefix * "_step_" * string(step) * ".png"
    PNGFiles.save(fname, universe)
    universe = ca_update(universe, [born, live], kernel)
  end
end

function run_run(born, live, steps::Int64=256, size=100, threshhold=0.5)
  universe = new_universe(size, threshhold)
  kernel = moore_kernel()

  for _ = 1:steps
    universe = ca_update(universe, [born, live], kernel)
  end

  length(universe)
end

function plot_run(born, live, steps, size, dthresh, averages)
  threshholds = 0:dthresh:1
  cs = [avg_complexity_procession_of(born, live, steps, size, threshhold, averages) for threshhold in threshholds]

  # plot = PlotlyJS.plot(surface(z=cs))
  #
  # open("plot.html", "w") do io
  #   PlotlyBase.to_html(io, plot.plot)
  # end
  PlotlyJS.plot(surface(z=cs))
end

function all_rules()
  out = []

  for n in 1:(2^9)
    bits = [parse(Int, b) for b in bitstring(n)[end-8:end]]
    append!(out, [[a for (a, b) in zip(0:8, bits) if b == 1]])
  end

  IterTools.product(out, out)
end

# Original version of experiment with static 50/50 initial conditions
function generate_static_data_for(born, live, steps, size, averages)
  # Data is still "2D" but there is only one row
  [avg_complexity_procession_of(born, live, steps, size, 0.5, averages)]
end

function generate_static_data(steps, size, averages)
  rules = collect(all_rules())
  fname = "./raw.dat"
  out = []

  open(fname, "w") do io
    @showprogress @distributed for (born, live) in rules
      data = generate_static_data_for(born, live, steps, size, averages)

      append!(out, [(born, live, data)])
    end

    serialize(io, out)
  end
end

# Second version of experiment with varied initial conditions
function generate_varied_data_for(born, live, steps, size, dthresh, averages)
  threshholds = 0:dthresh:1
  [avg_complexity_procession_of(born, live, steps, size, threshhold, averages) for threshhold in threshholds]
end

function generate_varied_data(steps, size, dthresh, averages)
  rules = collect(all_rules())
  fname = "./raw.dat"
  out = []

  open(fname, "w") do io
    @showprogress @distributed for (born, live) in rules
      data = generate_varied_data_for(born, live, steps, size, dthresh, averages)

      append!(out, [(born, live, data)])
    end

    serialize(io, out)
  end
end

# current embedding # generate_data(50, 25, 0.2, 5)

# For first data in paper:
# generate_static_data(30, 30, 10)

# For second data in paper:
# generate_varied_data(30, 30, 0.1, 10)

save_run([3], [2, 3], 10, 100)

# gol # plot_run([3], [2, 3], 50, 50, 0.2, 10)
# plot_run([4, 6, 7, 8], [3, 5, 6, 7, 8], 50, 50, 0.1, 10)
# seeds # plot_run([2], [], 256, 100, 0.01)
# anneal # plot_run([4, 6, 7, 8], [3, 5, 6, 7, 8], 100, 100, 0.02, 5)
# surprise # plot_run(5:8, 5:8, 100, 100, 0.05, 5)
# day/night # plot_run([3, 6, 7, 8], [3, 5, 6, 7, 8], 100, 100, 0.05, 5)
# plot_run([3], [2, 3, 8], 256, 100, 0.01, 10)
