close all;
clear;
clc;

% load graph settings from data_net.mat
load data_net.mat
% load demand settings from data_dem.mat
load data_dem.mat

% load given demand to match
load ./results/analyse_initial.mat
tobeanalysed = ones(length(data_proc), 1);
dem_scale = 0.001;

for i=1 : length(tobeanalysed)
    if ~tobeanalysed(i)
        continue
    end
    Dt = sum_across_cells(data_proc(i).Du)*dem_scale;
%     Dt = data_proc(i).Du{2}*dem_scale;

    % variable S - flow selection for each o-d pair and each operator
    % variable Ssup - supplementary flows for rebalancing for each operator
    [~, S, Ssup] = create_vars(n_nodes, n_edges, Dt);

    Constraints = [];
    addConstraints = cellfun(@get_greaterzero_constraints, S, 'UniformOutput', false);
    Constraints = [Constraints, addConstraints{:}];
    addConstraints = get_greaterzero_constraints(Ssup);
    Constraints = [Constraints, addConstraints];
    % path selection satisfies demand
    addConstraints = get_pathselection_constraints(S, Dt, G);
    Constraints = [Constraints, addConstraints];

    % dependent variable Fu - flow through each edge for each operator
    Fu = sum([S{:}], 2) + Ssup;
    % supplement flows with vehicle rebalancing mechanism
    addConstraints = get_rebalance_constraints(Fu, G);
    Constraints = [Constraints, addConstraints];
    % update edge avg travel time
%     F = Fu + data_proc(i).Fu{1}*dem_scale;
    T_cost = bpr_cx_cost(Fu, G);

    % solve for minimum congestion
    Objective = sum(T_cost, 'all');
    Options = sdpsettings('solver', 'gurobi', 'verbose', 1);
    Solution = optimize(Constraints, Objective, Options);
    analyse(Solution, Objective);

    % save data to be analysed later
    fname = sprintf('./results/matched_%s_%s.mat', ...
        char(string(data_proc(i).game)), char(string(data_proc(i).market)));
    savevars(fname, 'ne', Dt, S, Ssup);
end
