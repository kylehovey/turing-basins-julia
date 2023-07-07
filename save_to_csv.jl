using Serialization
using Plots
using CSV
using Tables

open("initial_redux.dat") do io
  data = deserialize(io)

  runs = hcat(map((t) -> vcat(t[3]...), data)...)
  rules = hcat(map((t) -> (t[1], t[2]), data)...)

  CSV.write("initial_redux_data.csv", Tables.table(runs))
  CSV.write("initual_redux_rules.csv", Tables.table(rules))
end
