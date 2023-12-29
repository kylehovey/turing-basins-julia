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
using UUIDs

#=
Convolutional CA method adapted from
https://rivesunder.github.io/SortaSota/2021/09/27/faster_life_julia.html
=#

# Tile our universe so that it is topologically a torus.
# This is required so that we can use convolution (because otherwise
# we couldn't wrap it around).
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

function moore_kernel()
  kernel = ones(Float16, 3, 3)
  kernel[2, 2] = 0
  kernel
end

# Convolve our Moore kernel over a universe
function nn_convolve(universe, kernel)
  # Convolution library expects a 4-tensor
  w = reshape(kernel, (size(kernel)[1], size(kernel)[2], 1, 1))
  x = reshape(universe, (size(universe)[1], size(universe)[2], 1, 1))

  return conv(x, w, pad=1)[:, :, 1, 1]
end

# Update a universe one time step
function ca_update(universe, rules, kernel)
  moore_grid = nn_convolve(circular_pad(universe), kernel)[2:end-1, 2:end-1]
  new_grid = zeros(size(moore_grid))

  for birth in rules[1]
    new_grid[((moore_grid.==birth).&(universe.!=1))] .= 1
  end

  for survive in rules[2]
    new_grid[((moore_grid.==survive).&(universe.==1))] .= 1
  end

  return new_grid
end

# Generate a new random universe (threshhold is P(life))
function new_universe(size, threshhold=0.5)
  universe = rand(Float16, size, size)
  # TODO: Are these backwards?
  universe[universe.>threshhold] .= 1
  universe[universe.<=threshhold] .= 0
  universe
end

# Generate all possible rules for Life-Like CA
function all_rules()
  out = []

  for n in 1:(2^9)
    bits = [parse(Int, b) for b in bitstring(n)[end-8:end]]
    append!(out, [[a for (a, b) in zip(0:8, bits) if b == 1]])
  end

  IterTools.product(out, out)
end

#=
Name and file system utils
=#

function name_for(born, live)
  "b" * join(born, "") * "s" * join(live, "")
end

function data_dir_for(metadir)
  dirname = "./generated/data/$(metadir)"
  mkpath(dirname)
  dirname
end

function graphics_dir_for(born, live, category)
  dirname = "./generated/graphics/$(category)/$(name_for(born, live))"
  mkpath(dirname)
  dirname
end

#=
Data generation
=#

# Original version of experiment with static 50/50 initial conditions
function generate_static_data(; steps, size, averages, threshhold=0.5)
  rules = collect(all_rules())
  metadir = "steps-$(steps)_size-$(size)_averages-$(averages)_threshhold-$(threshhold)"
  uid = uuid4()
  static_data_dir = data_dir_for("static_initial_condition/$(metadir)/$(uid)")
  fname = "$(static_data_dir)/raw.dat"
  out = []

  open(fname, "w") do io
    @showprogress @distributed for (born, live) in rules
      # Data is still "2D" but there is only one row
      data = [avg_complexity_procession_of(born, live, steps, size, threshhold, averages)]

      append!(out, [(born, live, data)])
    end

    serialize(io, out)
  end
end

# Second version of experiment with varied initial conditions
function generate_varied_data(; steps, size, averages, dthresh)
  rules = collect(all_rules())
  metadir = "steps-$(steps)_size-$(size)_dthresh-$(dthresh)"
  uid = uuid4()
  static_data_dir = data_dir_for("varied_initial_condition/$(metadir)/$(uid)")
  fname = "$(static_data_dir)/raw.dat"
  fname = "./raw.dat"
  out = []

  open(fname, "w") do io
    @showprogress @distributed for (born, live) in rules
      threshholds = 0:dthresh:1
      data = [avg_complexity_procession_of(born, live, steps, size, threshhold, averages) for threshhold in threshholds]

      append!(out, [(born, live, data)])
    end

    serialize(io, out)
  end
end

#=
Graphics generation
=#

# Generate vector of complexity over time for a given rule
function complexity_procession_of(born, live, steps::Int64=256, size::Int64=100, threshhold=0.5)
  universe = new_universe(size, threshhold)
  kernel = moore_kernel()

  complexities = []

  # Create a buffer so that we can call PNGFiles.save without creating an inode
  buf = IOBuffer()
  for _ = 1:steps
    # No file created, only in memory buffer
    PNGFiles.save(buf, universe)

    # Length of `take!(buf)` is size in bytes
    append!(complexities, UInt16(length(take!(buf))))
    universe = ca_update(universe, [born, live], kernel)
  end

  complexities
end

# Run multiple universes and average out the complexity processions
function avg_complexity_procession_of(born, live, steps::Int64=256, size::Int64=100, threshhold=0.5, runs=10)
  cs = [complexity_procession_of(born, live, steps, size, threshhold) for _ in 1:runs]
  [Float16(mean([row[i] for row in cs])) for i in 1:steps]
end

# Save an example run of a given rule as individual PNG files
function save_run(born, live, steps::Int64=256, size=100, threshhold=0.5)
  universe = new_universe(size, threshhold)
  kernel = moore_kernel()
  metadir = "steps-$(steps)_size-$(size)_threshhold-$(threshhold)"
  graphics_dir = graphics_dir_for(born, live, "runs/$(metadir)")
  uid = uuid4()

  for step = 1:steps
    fname = "$(graphics_dir)/$(uid)_step_$(step).png"
    PNGFiles.save(fname, universe)
    universe = ca_update(universe, [born, live], kernel)
  end
end

# Generate a surface plot of complexity over time for various initial conditions
function plot_run(born, live, steps, size, dthresh, averages; save_png=false)
  threshholds = 0:dthresh:1
  y_values = [i for i in 1:length(threshholds)]
  cs = [avg_complexity_procession_of(born, live, steps, size, threshhold, averages) for threshhold in threshholds]
  metadir = "steps-$(steps)_size-$(size)_dthresh-$(dthresh)_averages-$(averages)"
  surface_plot_dir = graphics_dir_for(born, live, "surface_plots/$(metadir)")
  uid = uuid4()

  y_axis_scale = map(y -> "$(round(100 * (1 - (y - 1) / (length(threshholds) - 1)), digits=2))%", y_values)
  name = name_for(born, live)
  zoom = 2
  margin = 40

  layout = Layout(
    title="Entropy Progression - $(name)",
    showlegend=false,
    scene=attr(
      xaxis_title="Time Step",
      yaxis_title="Initial Probability of Life",
      zaxis_title="Bytes",
      yaxis=attr(
        tickvals=y_values,
        ticktext=y_axis_scale
      ),
      # Adjust the camera's eye position
      camera=attr(
        eye=attr(x=zoom, y=zoom, z=zoom)
      ),
    ),
    margin=attr(l=margin, r=margin, b=margin, t=margin),
    autosize=true,
    width=1000,
    height=1000
  )

  plot = PlotlyJS.plot(surface(z=cs, x=1:steps, y=y_values), layout)

  if save_png
    png_filename = "$(surface_plot_dir)/$(uid)_entropy_plot.png"
    PlotlyJS.savefig(plot, png_filename)
    println("Plot saved as '$png_filename'.")
  end

  if !save_png
    return plot
  end
end

# For first data in paper:
# generate_static_data(steps=60, size=40, averages=20)

# For second data in paper:
generate_varied_data(steps=60, size=40, averages=20, dthresh=0.2)

# save_run([3], [2, 3], 10, 70)

# plot_run([3], [2, 3], 50, 100, 0.2, 20, save_png=true)

# gol
# plot_run([3], [2, 3], 50, 100, 0.2, 20, save_png=true)
# seeds # plot_run([2], [], 256, 100, 0.01)
# anneal
# plot_run([4, 6, 7, 8], [3, 5, 6, 7, 8], 100, 100, 0.01, 5)
# surprise
# plot_run(5:8, 5:8, 100, 25, 0.1, 20)
# day/night
# plot_run([3, 6, 7, 8], [3, 5, 6, 7, 8], 100, 100, 0.05, 5)
# unknown
# plot_run([3], [2, 3, 8], 50, 25, 0.2, 10)
