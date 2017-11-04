using Base.Test

include("miptests.jl")
include("branch_and_bound.jl")

test1(solveMIP)
test2(solveMIP)
test3(solveMIP)
testSudoku(solveMIP)
