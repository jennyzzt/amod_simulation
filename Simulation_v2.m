close all;
clear;
clc;

% load graph settings from data_net.mat
load data_net.mat
% load demand settings from data_dem.mat
load data_dem.mat
% load optimum flow and selection - used for operator estimation
load data_optimum.mat

% method of solving: 0 - potential, 1 - fixed point
algo = 1;

% game settings
n_ops = 2;
objs = zeros(n_ops, 1); % operators' objectives: 0 - profit max, 1 - customer max
unit_cost = 1; % unit cost of using one vehicle per time unit

% variable E - pricing strat for each operator
% variable S - split path selection for each operator
% variable Fsup - supplementary flows for rebalancing for each operator
[E, S, Ssup] = arrayfun(@(~) create_vars(n_nodes, n_edges, D), zeros(n_ops, 1), 'UniformOutput', false);

% dependent variable Ecust - cost of ride to customer
Ecust = cellfun(@(e, s) v2_deduce_pricestrat(e, s, G.Edges.length, estimated_T), E, S, 'UniformOutput', false);
% dependent variable Du - resulting demand for each operator
Du = arrayfun(@(i) D.*demandprob(i, Ecust, Emax), transpose([1:n_ops]), 'UniformOutput', false);

Constraints = [];
addConstraints = cellfun(@get_greaterzero_constraints, E, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = cellfun(@get_greaterzero_constraints, [S{:}], 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = cellfun(@get_greaterzero_constraints, Ssup, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = cellfun(@get_greaterzero_constraints, Du, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
% path selection satisfies demand
addConstraints = cellfun(@(s) get_splitselection_constraints(s, G), S, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];

% dependent variable Fu - flow through each edge for each operator
Sflow = cellfun(@(s, d) v2_get_demandflows(s, d), S, Du, 'UniformOutput', false);
Fu = cellfun(@(s, sup) sum([s{:}], 2) + sup, Sflow, Ssup, 'UniformOutput', false);
% supplement flows with vehicle rebalancing mechanism
addConstraints = cellfun(@(fu) get_rebalance_constraints(fu, G), Fu, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
% update edge avg travel time
F = sum([Fu{:}], 2);
T = bpr_cx(F, G);

% add necessary constraints based on operator objective
for i=1 : n_ops
    if objs(i) == 1
        % customer max objective
        Cost = unit_cost*sum((Fu{i} + Ssup{i}) .* T, 'all');
        Revenue = sum(Du{i} .* E{i}, 'all');
        Constraints = [Constraints, Cost <= 1.5 .* Revenue];
    end
end

if algo == 0 && all(objs == 1)
    % potential fn objective if both operators are customer max
    % note that it is the same as max sum of all Du
    % partPotentials = cellfun(@(e) sum(D.*e./Emax, 'all'), E, 'UniformOutput', false);
    % Objective = sum([partPotentials{:}], 'all');
    Objective = - sum([Du{:}], 'all');
else
    Objective = [];
end

% feasible point if no given objective
Options = sdpsettings('solver', 'gurobi', 'verbose', 1);
Solution = optimize(Constraints, Objective, Options);
analyse(Solution, Objective);

if algo == 0 && all(objs == 1)
    % save data to be analysed later
    fname = sprintf('./results/results_v2_%s.mat', char(string(objs)));
    savevars(fname, 'ne', E, S, Ssup);
end
