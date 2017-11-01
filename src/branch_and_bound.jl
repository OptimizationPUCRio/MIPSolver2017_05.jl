# ------------------------------------------------------------------
using JuMP

mutable struct node
  level::Int
  model::JuMP.Model
end

## Receives a pure binary JuMP model
function branch_and_bound(model::JuMP.Model)

  model.colCat[:] = :Cont
  nodes = Vector{node}(1)
  nodes[1] = node(0, model) # root

  while !isempty(nodes) || currentNode.level <= log2(nvars)+1
    solve(nodes[1].model)
    if isBinary(nodes[1].model)

    else
      (leftChild, rightChild) = branch(nodes[1])
      nodes = deleteat!(nodes, 1)
      nodes = push!(nodes, leftChild)
      nodes = push!(nodes, rightChild)
    end
  end

  return false
end

## Receives node and creates two children by setting a variable to 0 and 1 respectively
function branch(currentNode::node)
  indToSet = indmax(currentNode.model.colUpper - currentNode.model.colLower)

  leftModel = copy(currentNode.model)
  leftModel.colUpper[indToSet] = 0
  leftModel.colLower[indToSet] = 0

  rightModel = copy(currentNode.model)
  rightModel.colUpper[indToSet] = 1
  rightModel.colLower[indToSet] = 1

  leftChild = node(currentNode.level+1, leftModel)
  rightChild = node(currentNode.level+1, rightModel)

  return leftChild, rightChild
end

function isBinary(model::JuMP.Model)
  isZero = model.colVal .== 0
  isOne  = model.colVal .== 1
  if sum(isZero + isOne) == model.numCols
    # Relaxed solution is binary: optimal solution
    return true
  end
  return false
end
