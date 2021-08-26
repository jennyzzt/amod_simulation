close all;
clear;
clc;

% load graph settings from data_net.mat
load data_net.mat
% load demand settings from data_dem.mat
load data_dem.mat

% game settings
objs = 1; % operators' objectives: 0 - profit max, 1 - customer max, 2 - customer max break even
unit_Tcost = 30; % unit cost of using one vehicle per time unit
unit_Dcost = 1; % unit cost of using one vehicle per distance unit
loss_limit = 150;

% variable E - pricing strat for each operator
% variable S - flow selection for each o-d pair and each operator
% variable Ssup - supplementary flows for rebalancing for each operator
[E, S, Ssup] = create_vars(n_nodes, n_edges, D);

% dependent variable Du - resulting demand for each operator
Du = D.*demandprob(1, {E}, Emax, [1]);

Constraints = [];
addConstraints = get_greaterzero_constraints(Du);
Constraints = [Constraints, addConstraints];
addConstraints = get_greaterzero_constraints(E);
Constraints = [Constraints, addConstraints];
addConstraints = cellfun(@get_greaterzero_constraints, S, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = get_greaterzero_constraints(Ssup);
Constraints = [Constraints, addConstraints];
% path selection satisfies demand
addConstraints = get_pathselection_constraints(S, Du, G);
Constraints = [Constraints, addConstraints];

% dependent variable Fu - flow through each edge for each operator
Fu = sum([S{:}], 2) + Ssup;
% supplement flows with vehicle rebalancing mechanism
addConstraints = get_rebalance_constraints(Fu, G);
Constraints = [Constraints, addConstraints];
% update edge avg travel time
T_cost = bpr_cx_cost(Fu, G);
D_cost = Fu.*G.Edges.length;

if objs == 0
    % profit max objective
    Cost = unit_Tcost*sum(T_cost, 'all') + unit_Dcost * sum(D_cost, 'all');
    Revenue = sum(Du .* E, 'all');
    Objective = Cost - Revenue;
elseif objs == 1
    % add necessary constraints for customer max objective
    Cost = unit_Tcost*sum(T_cost, 'all') + unit_Dcost * sum(D_cost, 'all');
    Revenue = sum(Du .* E, 'all');
    Constraints = [Constraints, Cost - Revenue <= loss_limit];
    Objective = - sum(Du, 'all');
elseif objs == 2
    % add necessary constraints for customer max break even objective
    Cost = unit_Tcost*sum(T_cost, 'all') + unit_Dcost * sum(D_cost, 'all');
    Revenue = sum(Du .* E, 'all');
    Constraints = [Constraints, Cost - Revenue <= 0];
    Objective = - sum(Du, 'all');
else
    Objective = [];
end

% feasible point if no given objective
Options = sdpsettings('solver', 'gurobi', 'verbose', 1, 'saveduals', 0);
Solution = optimize(Constraints, Objective, Options);
analyse(Solution, Objective);

% save data to be analysed later
fname = sprintf('./results/results_%s_1.mat', char(string(objs)));
savevars(fname, 'ne', E, S, Ssup);
