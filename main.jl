using PNGFiles
using BenchmarkTools

function generate_canvas(size=256)
  # zeros(UInt8, (size, size))
  rand(UInt8, size, size)
end

canvas = generate_canvas()

function main()
  res = PNGFiles.save("output.png", canvas, compression_level=9, compression_strategy=0)
  @timev res
end
