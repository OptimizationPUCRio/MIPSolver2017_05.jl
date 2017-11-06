# ------------------------------------------------------------------
using JuMP

mutable struct node
  level::Int
  model::JuMP.Model
end

## Checks if solution is binary
function isBinary(model::JuMP.Model)
  isZero = model.colVal .== 0
  isOne  = model.colVal .== 1
  if sum(isZero + isOne) == model.numCols
    return true
  end
  return false
end

## Checks if model is max: if it is, converts to min
function convertSense!(m::JuMP.Model)
  model = deepcopy(m)
  if model.objSense == :Max
    model.objSense = :Min
    model.obj = -model.obj
  else
    model.objSense = :Max
    model.obj = -model.obj
  end
  return model
end

## Receives node and creates two children by setting a variable to 0 and 1 respectively
function branch(currentNode::node, binaryIndices::Vector{Int64})
  # indToSet = indmax(currentNode.model.colUpper - currentNode.model.colLower)
  indToSet = binaryIndices[level+1]

  leftModel = deepcopy(currentNode.model)
  leftModel.colUpper[indToSet] = 0
  leftModel.colLower[indToSet] = 0

  rightModel = deepcopy(currentNode.model)
  rightModel.colUpper[indToSet] = 1
  rightModel.colLower[indToSet] = 1

  leftChild = node(currentNode.level+1, leftModel)
  rightChild = node(currentNode.level+1, rightModel)

  return leftChild, rightChild
end

## Receives a pure binary JuMP model
function branch_and_bound(model::JuMP.Model)

  binaryIndices = find(model.colCat .== :Bin)

  # Check if model is max; if it is, converts to min
  flagConverted = 0
  if model.objSense == :Max
    model = convertSense!(model)
    flagConverted = 1
  end

  # Best lower bound: start as Inf
  bestLB = Inf

  # Relax all variables and create branch and bound tree
  model.colCat[:] = :Cont
  nodes = Vector{node}(1)
  nodes[1] = node(0, model) # root

  iter = 0
  while !isempty(nodes)
    status = solve(nodes[1].model)
    if status == :Infeasible
      # Relaxed problem is infeasible -- don't branch
    elseif isBinary(nodes[1].model) && status == :Optimal
      # Relaxed solution is binary: optimal solution -- don't branch
      if nodes[1].model.objVal < bestLB
        bestLB = nodes[1].model.objVal
        optModel = deepcopy(nodes[1].model)
      end
    else
      # Relaxed solution is not optimal -- branch
      (leftChild, rightChild) = branch(nodes[1])
      nodes = push!(nodes, leftChild)
      nodes = push!(nodes, rightChild)
    end
    nodes = deleteat!(nodes, 1)
    iter+=1
  end

  # Check if model was converted; if it was, convert back to original sense
  if flagConverted == 1
    optModel = convertSense!(optModel)
    status = solve(optModel)
  else
    status = solve(optModel)
  end

  optModel.ext[:status] = status

  return optModel
end
