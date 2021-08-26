close all;
clear;
clc;

% load graph settings from data_net.mat
load data_net.mat
% load demand settings from data_dem.mat
load data_dem.mat

% method of solving: 0 - potential, 1 - fixed point
algo = 1;

% game settings
n_ops = 2;
objs = zeros(n_ops, 1); % operators' objectives: 0 - profit max, 1 - customer max
unit_Tcost = 30; % unit cost of using one vehicle per time unit
unit_Dcost = 1; % unit cost of using one vehicle per distance unit
marketshare = ones(n_ops, 1);
loss_limit_unit = 150/sum(marketshare,'all');

% variable E - pricing strat for each operator
% variable S - flow selection for each o-d pair and each operator
% variable Ssup - supplementary flows for rebalancing for each operator
[E, S, Ssup] = arrayfun(@(~) create_vars(n_nodes, n_edges, D), zeros(n_ops, 1), 'UniformOutput', false);

% dependent variable Du - resulting demand for each operator
Du = arrayfun(@(i) D.*demandprob(i, E, Emax, marketshare), transpose([1:n_ops]), 'UniformOutput', false);

Constraints = [];
addConstraints = cellfun(@get_greaterzero_constraints, Du, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = cellfun(@get_greaterzero_constraints, E, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = cellfun(@get_greaterzero_constraints, [S{:}], 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
addConstraints = cellfun(@get_greaterzero_constraints, Ssup, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];
% path selection satisfies demand
addConstraints = cellfun(@(s, du) get_pathselection_constraints(s, du, G), S, Du, 'UniformOutput', false);
Constraints = [Constraints, addConstraints{:}];

% dependent variable Fu - flow through each edge for each operator
Fu = cellfun(@(s, sup) sum([s{:}], 2) + sup, S, Ssup, 'UniformOutput', false);
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
        Cost = unit_Tcost*sum(Fu{i} .* T, 'all') + unit_Dcost*sum(Fu{i}.*G.Edges.length, 'all');
        Revenue = sum(Du{i} .* E{i}, 'all');
        Constraints = [Constraints, Cost - Revenue <= loss_limit_unit*marketshare(i)];
    end
end

if algo == 0 && all(objs == 1)
    % potential fn objective if both operators are customer max
    partPotentials = cellfun(@(e) sum(marketshare,'all')*sum(D.*e./Emax, 'all')/marketshare(i)/n_ops, ...
        E, 'UniformOutput', false);
    Objective = sum([partPotentials{:}], 'all');
else
    Objective = [];
end

% feasible point if no given objective
Options = sdpsettings('solver', 'gurobi', 'verbose', 1);
Solution = optimize(Constraints, Objective, Options);
analyse(Solution, Objective);

if algo == 0 && all(objs == 1)
    % save data to be analysed later
    fname = sprintf('./results/results_%s_%s.mat', char(string(objs)), char(string(marketshare)));
    savevars(fname, 'ne', E, S, Ssup);
end
