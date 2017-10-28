# ------------------------------------------------------------------
using JuMP, Gurobi

## Recebe o modelo JuMP de um problema binário puro.
function branch(model::JuMP.Model)

  status = solve(model, relaxation=true)
  isZero = model.colVal .== 0
  isOne  = model.colVal .== 1
  if sum(isZero + isOne) == model.numCols
    # Solução relaxada é binária
    opt = true
    return true
  end

  return false
end

mutable struct node
  level::Int
  model::JuMP.Model
end
