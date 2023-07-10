using Serialization
using CSV
using Tables

function number_for(born, survive)
  out = 0
  for i in 0:9
    if i in survive
      out += (1 << (i + 9))
    end

    if i in born
      out += (1 << i)
    end
  end

  out
end

open("raw.dat") do io
  data = deserialize(io)

  runs = hcat(map((t) -> vcat(t[3]...), data)...)
  rules = hcat(map((t) -> number_for(t[1], t[2]), data)...)

  CSV.write("data.csv", Tables.table(runs))
  CSV.write("targets.csv", Tables.table(rules))
end
