using Base.Test, JuMP, Gurobi

include("../MIPTests.jl/miptests.jl")
include("../src/branch_and_bound.jl")

solver = GurobiSolver(OutputFlag=0)

test1(solveMIP, solver) # 2/2
test2(solveMIP, solver) # 2/2
test3(solveMIP, solver) # 3/3
test3_2(solveMIP, solver) # 1/1
test3_3(solveMIP, solver) # 1/1
testCaminho(solveMIP, solver) # 1/1
testInfeasibleKnapsack(solveMIP, solver) # 1/1
testInfeasibleUC(solveMIP, solver) # 1/1
testSudoku(solveMIP, solver) # 8/8
testSudoku4x4(solveMIP, solver) # 1/1
testUnboundedKnapsack(solveMIP, solver) # 1/1
test_MIP_Minimal_Brito(solveMIP, solver) # 3/3
test_MIP_Pequeno_Brito(solveMIP, solver) # 3/3
test_Minimal_UC(solveMIP, solver) # 3/3
test_P1_Brito(solveMIP, solver) # 3/3
test_PL_Infeasible_Brito(solveMIP, solver) # 1/1
test_PL_Infeasible_Raphael(solveMIP, solver) # 1/1
test_PL_Simples_Brito(solveMIP, solver) # 2/2
test_PL_Simples_Raphael(solveMIP, solver) # 2/2
test_PL_Unbounded_Brito(solveMIP, solver) # 1/1
test_feature_selection_medio(solveMIP, solver) # 2/2
test_feature_selection_pequeno_inviavel(solveMIP, solver) # 1/1
test_feature_selection_pequeno_viavel(solveMIP, solver) # 2/2
teste_PL_andrew_inviavel(solveMIP, solver) # 1/1
teste_PL_andrew_unbounded(solveMIP, solver) # 1/1
teste_PL_andrew_viavel(solveMIP, solver) # 3/3

# Hard tests
test_feature_selection_grande(solveMIP, solver) # 2/2
testRobustCCUC(solveMIP, solver)
