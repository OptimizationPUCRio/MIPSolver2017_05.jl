# ------------------------------------------------------------------

mutable struct node
  level::Int
  model::JuMP.Model
end

## Checks if solution is binary
function isBinary(model::JuMP.Model, binaryIndices::Vector{Int64})
  isZero = model.colVal[binaryIndices] .== 0
  isOne  = model.colVal[binaryIndices] .== 1
  if sum(isZero + isOne) == length(binaryIndices)
    return true
  end
  return false
end

## Checks if model is max: if it is, converts to min
function convertSense!(m::JuMP.Model)
  if m.objSense == :Max
    m.objSense = :Min
    m.obj = -m.obj
  else
    m.objSense = :Max
    m.obj = -m.obj
  end
end

## Receives node and creates two children by setting a variable to 0 and 1 respectively
function branch(currentNode::node, binaryIndices::Vector{Int64})

  isNotZero = currentNode.model.colVal[binaryIndices] .!= 0
  isNotOne  = currentNode.model.colVal[binaryIndices] .!= 1
  firstFrac = find(isNotZero .& isNotOne)[1]
  indToSet = binaryIndices[firstFrac]

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

## Receives a pure binary or mixed binary linear JuMP model
function solveMIP(m::JuMP.Model)

  # Check if model is max; if it is, converts to min
  flagConverted = 0
  if m.objSense == :Max
    convertSense!(m)
    flagConverted = 1
  end

  # Best lower bound: start as Inf
  bestLB = Inf

  # Create vector of indices of the binary variables
  binaryIndices = find(m.colCat .== :Bin)

  # Relax all variables and create branch and bound tree
  m.colCat[:] = :Cont
  nodes = Vector{node}(1)
  nodes[1] = node(0, m) # root

  iter = 0
  flagOpt = 0
  status = 0
  while !isempty(nodes)
    status = solve(nodes[1].model)
    if status != :Optimal
      # Relaxed problem is infeasible or unbounded -- don't branch
    elseif isBinary(nodes[1].model, binaryIndices)
      # Relaxed solution is binary: optimal solution -- don't branch
      if nodes[1].model.objVal < bestLB
        flagOpt = 1
        bestLB = nodes[1].model.objVal
        opt = deepcopy(nodes[1].model)
        m.colVal = opt.colVal
      end
    else
      # Relaxed solution is not optimal -- branch
      (leftChild, rightChild) = branch(nodes[1], binaryIndices)
      push!(nodes, leftChild)
      push!(nodes, rightChild)
    end
    deleteat!(nodes, 1)
    iter+=1
  end

  if flagConverted == 1
    convertSense!(m)
    m.objVal = -bestLB
  else
    m.objVal = bestLB
  end

  if flagOpt == 0
    m.ext[:status] = status
  else
    m.ext[:status] = :Optimal
  end

  println("Número de iterações: $iter")

  return m.ext[:status]
end
