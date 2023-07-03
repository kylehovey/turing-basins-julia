using NNlib
using ImageView
using Gtk
using PyPlot
pygui(false)

# universe constructor

mutable struct Universe
  born::Array{Int8}
  live::Array{Int8}
  grid::Array{Float32,2}
end

# default constructor for CA universe

Universe() = Universe([3], [2, 3], zeros(64, 64))

function circular_pad(grid)


  padded = zeros(Float32, size(grid)[1] + 2, size(grid)[2] + 2)

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

  grid2 = grid

  w = reshape(kernel, (size(kernel)[1], size(kernel)[2], 1, 1))
  x = reshape(grid, (size(grid)[1], size(grid)[2], 1, 1))

  return conv(x, w, pad=1)[:, :, 1, 1]
end

function ca_update(grid, rules)

  # Moore neighborhood kernel
  kernel = ones(Float32, 3, 3)
  kernel[2, 2] = 0

  moore_grid = nn_convolve(circular_pad(grid), kernel)[2:end-1, 2:end-1]

  new_grid = zeros(size(moore_grid))

  #my_fn(a,b) = a + b
  #born = reduce(my_fn, [elem .== moore_grid for elem in rules[1]])
  #live = reduce(my_fn, [elem .== moore_grid for elem in rules[2]])


  for birth in rules[1]
    #new_grid[(round.(moore_grid .- birth) .== 0.0) .& (grid .!= 1)] .= 1
    new_grid[((moore_grid.==birth).&(grid.!=1))] .= 1
  end

  for survive in rules[2]
    #new_grid[(round.(moore_grid .- survive) .== 0.0) .& (grid .== 1)] .= 1
    new_grid[((moore_grid.==survive).&(grid.==1))] .= 1
  end

  return new_grid
end


function ca_steps(universe::Universe, steps::Int64)

  for ii = 1:steps
    universe.grid = ca_update(universe.grid, [universe.born, universe.live])
  end

end


