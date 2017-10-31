# ------------------------------------------------------------------
using JuMP

mutable struct node
  level::Int
  model::JuMP.Model
end

## Recebe o modelo JuMP de um problema binário puro.
function branch_and_bound(model::JuMP.Model)

  status = solve(model, relaxation=true)
  if status != :Optimal
    println("Erro no problema: relaxação não convergiu.")
    return false
  end

  isZero = model.colVal .== 0
  isOne  = model.colVal .== 1
  if sum(isZero + isOne) == model.numCols
    # Solução relaxada é binária
    return model
  end

  opt = false
  nvars = model.numCols

  # Nó raiz
  JuMP.setcategory()
  root = root(model, model)

  # Branch

end

function branch(model::JuMP.Model)

  return false
end
