close all;
clear;
clc;

% load graph settings from data_net.mat
load data_net.mat
% load demand settings from data_dem.mat
load data_dem.mat

% path selection by flows
S = cell(n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        if D(o,d) == 0
            continue
        end
        S{o,d} = sdpvar(n_edges, 1, 'full');
    end
end
F = sum([S{:}], 2);
% edge avg travel time
T = bpr_cx_cost(F, G);
% total time used to satisfy demand
Ttotal = sum(T, 'all');

Constraints = [];
% path selection satisfies demand
addConstraints = cellfun(@get_greaterzero_constraints, S, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = get_pathselection_constraints(S, D, G);
Constraints = [Constraints, addConstraints];

% solve for optimum set of flows and selection
Objective = Ttotal;
Options = sdpsettings('solver', 'gurobi', 'verbose', 1);
Solution = optimize(Constraints, Objective, Options);
analyse(Solution, Objective);

% save data to be used later
savevars('data_optimum.mat', 'estimated', S, F, T);
