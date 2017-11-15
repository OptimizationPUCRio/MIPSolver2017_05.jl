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

## Updates best bound and level bound
function updateBound(currentNode::node, lastNodeLevel::Int, levelBound::Float64, bestBound::Float64)

  if currentNode.level != lastNodeLevel
    # Entered new level -- create new level bound
    bestBound = levelBound
    levelBound = currentNode.model.objVal
  elseif currentNode.model.objVal < levelBound
    # Same level, worse bound -- update current level bound
    levelBound = currentNode.model.objVal
  end

  return levelBound, bestBound
end

## Receives a mixed binary linear JuMP model
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
  levelBound = -Inf

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

  flagOpt = 0
  tol = 1e-5
  while !isempty(nodes) && abs(bestVal - bestBound) > tol
    if iter == 0
      iter = 1
      continue
    end
    status = solve(nodes[1].model)
    if status == :Optimal
      levelBound, bestBound = updateBound(nodes[1], lastNodeLevel, levelBound, bestBound)
      if isBinary(nodes[1].model, binaryIndices)
        # Relaxed solution is binary: optimal solution -- don't branch
        if nodes[1].model.objVal < bestVal
          bestVal = nodes[1].model.objVal
          m.colVal = copy(nodes[1].model.colVal)
          flagOpt = 1
        end
      elseif nodes[1].model.objVal <= bestVal
        # Relaxed solution is not binary and should not be pruned by limit -- branch
        (leftChild, rightChild) = branch(nodes[1], binaryIndices)
        push!(nodes, leftChild)
        push!(nodes, rightChild)
      end
    end
    lastNodeLevel = nodes[1].level
    deleteat!(nodes, 1)
    iter+=1

    println("UB: $bestVal")
    println("LB: $bestBound")
  end

  if flagConverted == 1
    convertSense!(m)
    m.objVal = -bestVal
    m.objBound = -bestBound
  else
    m.objVal = bestVal
    m.objBound = bestBound
  end

  # Return binary variables to original state
  m.colCat[binaryIndices] = :Bin

  # Outputs
  m.ext[:status] = status
  if flagOpt == 1
    m.ext[:status] = :Optimal
  end
  m.ext[:nodes] = iter
  t = toc()
  m.ext[:time] = t

  return m.ext[:status]
end
