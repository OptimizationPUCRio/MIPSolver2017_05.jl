# ------------------------------------------------------------------
using JuMP

mutable struct root
  model::JuMP.Model
  leftChild::node
  rightChild::node
end

mutable struct node
  level::Int
  model::JuMP.Model
  father::node
  leftChild::node
  rightChild::node
end

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
  nodeSet = Set{node}

  # Nó raiz
  JuMP.setcategory()
  root = root(model, model)

  # Branch

end

## Recebe o modelo JuMP de um problema binário puro.
function branch(model::JuMP.Model)

  return false
end
