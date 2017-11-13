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

  tic()

  # Check if model is max; if it is, converts to min
  flagConverted = 0
  if m.objSense == :Max
    convertSense!(m)
    flagConverted = 1
  end

  # Best bounds: start as Inf
  bestBound = -Inf
  bestVal = Inf
  bestLevelBound = -Inf

  # Create vector of indices of the binary variables
  binaryIndices = find(m.colCat .== :Bin)

  # Relax all variables; solve relaxed problem
  m.colCat[:] = :Cont
  status = solve(m)
  if status == :Optimal && isBinary(m, binaryIndices)
    # Solution of the relaxed problem is binary: optimal solution
    nodes = Vector{node}(0)
    bestBound = m.objVal
    bestVal = m.objVal
  else
    # Create branch and bound tree
    nodes = Vector{node}(1)
    nodes[1] = node(0, m) # root
    lastNodeLevel = 0
  end
  iter = 0

  tol = 1e-6
  while !isempty(nodes)
    if iter == 0
      iter = 1
      continue
    end
    if abs(bestVal - bestBound) < tol
      break
    end
    status = solve(nodes[1].model)
    if status != :Optimal
      # Relaxed problem is infeasible or unbounded -- don't branch
    elseif isBinary(nodes[1].model, binaryIndices)
      # Relaxed solution is binary: optimal solution -- don't branch
      if nodes[1].model.objVal < bestVal
        bestVal = nodes[1].model.objVal
        m.colVal = copy(nodes[1].model.colVal)
      end
      if nodes[1].level != lastNodeLevel
        # Entered new level -- create new best level bound
        bestLevelBound = nodes[1].model.objVal
      elseif nodes[1].model.objVal > bestLevelBound
        # Same level, better bound -- update current best level bound
        bestLevelBound = nodes[1].model.objVal
      end
    else
      # Optimal but not binary -- branch
      if nodes[1].model.objVal > bestBound
        bestBound = nodes[1].model.objVal
      end
      (leftChild, rightChild) = branch(nodes[1], binaryIndices)
      push!(nodes, leftChild)
      push!(nodes, rightChild)
    end
    lastNodeLevel = nodes[1].level
    deleteat!(nodes, 1)
    iter+=1
  end

  if flagConverted == 1
    convertSense!(m)
    m.objVal = -bestVal
    m.objBound = -bestBound
  else
    m.objVal = bestVal
    m.objBound = bestBound
  end

  m.ext[:status] = status
  m.ext[:nodes] = iter
  t = toc()
  m.ext[:time] = t

  return m.ext[:status]
end
