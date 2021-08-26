close all;
clear;
clc;

% load graph settings from data_net.mat
load data_net.mat
% load demand settings from data_dem.mat
load data_dem.mat
% load optimum flow and selection - used for operator estimation
load data_optimum.mat

% game settings
objs = 4; % operators' objectives: 0 - profit max, 1 - customer max, 2 - customer max break even
unit_cost = 1; % unit cost of using one vehicle per time unit

% variable E - pricing strat for each operator
% variable S - flow selection for each o-d pair and each operator
% variable Ssup - supplementary flows for rebalancing for each operator
[E, S, Ssup] = create_vars(n_nodes, n_edges, D);

% dependent variable Ecust - cost of ride to customer
Ecust = v2_deduce_pricestrat(E, S, G.Edges.length, estimated_T);
% dependent variable Du - resulting demand for each operator
Du = D.*demandprob(1, {Ecust}, Emax, [1]);

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
addConstraints = get_splitselection_constraints(S, G);
Constraints = [Constraints, addConstraints];

% dependent variable Fu - flow through each edge for each operator
Sflow = v2_get_demandflows(S, Du);
% [Sflow, addConstraints, vartmp1] = v2_get_demandflows_reform(E, S, G.Edges.length, estimated_T, Emax, D);
% Constraints = [Constraints, addConstraints];
Fu = sum([Sflow{:}], 2) + Ssup;
% supplement flows with vehicle rebalancing mechanism
addConstraints = get_rebalance_constraints(Fu, G);
Constraints = [Constraints, addConstraints];
% update edge avg travel time
T_cost = bpr_cx_cost(Fu, G);

% calculate cost, revenue, total satisfied demand
Cost = unit_cost*sum(T_cost, 'all');
Revenue = sum(Du .* E, 'all');
% [Revenue, addConstraints, vartmp2] = v2_get_revenue_reform(E, S, G.Edges.length, estimated_T, Emax, D);
% Constraints = [Constraints, addConstraints];
Dutotal = sum(Du, 'all');

if objs == 0
    % profit max objective
    Objective = Cost-Revenue;
elseif objs == 1
    % add necessary constraints for customer max objective
    Constraints = [Constraints, Cost - 1.5*Revenue <= 0];
    Objective = -Dutotal;
elseif objs == 2
    % add necessary constraints for customer max break even objective
    Constraints = [Constraints, Cost - Revenue <= 0];
    Objective = -Dutotal;
else
    Objective = [];
end

% feasible point if no given objective
Options = sdpsettings('solver', 'gurobi', 'verbose', 1);
Solution = optimize(Constraints, Objective, Options);
analyse(Solution, Objective);

% save data to be analysed later
fname = sprintf('./results/results_v2_%s.mat', char(string(objs)));
savevars(fname, 'ne', E, S, Ssup);

function [Sflow, constraints, z] = v2_get_demandflows_reform(E, S, dists, estimated_times, Emax, D)
dist_norm = 5; % additional price per distance mile
time_norm = 25; % additional price per unit time hour
n_nodes = length(S);
n_edges = length(estimated_times);
Sflow = cell(n_nodes);
z = cell(n_nodes, n_nodes);
constraints = [];
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d || isempty(S{o,d})
            continue;
        end
        Sflow{o,d} = zeros(n_edges, 1, 'like', sdpvar);
        Sflow{o,d} = S{o,d} .* D(o,d);
        z{o,d} = sdpvar(n_edges, n_edges, 'full');
        for e=1 : n_edges
            for f=1 : n_edges
                constraints = [constraints, z{o,d}(e,f) >= S{o,d}(e)*S{o,d}(f)];
                Sflow{o,d}(e) = Sflow{o,d}(e) - z{o,d}(e,f)*D(o,d)*E(o,d)*(dist_norm.*dists(f) + time_norm.*estimated_times(f))/Emax(o,d);
            end
        end
    end
end
end

function [revenue, constraints, v] = v2_get_revenue_reform(E, S, dists, estimated_times, Emax, D)
dist_norm = 5; % additional price per distance mile
time_norm = 25; % additional price per unit time hour
n_nodes = length(S);
revenue = zeros(n_nodes, n_nodes, 'like', sdpvar);
v = sdpvar(n_nodes, n_nodes, 'full');
constraints = [];
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d || isempty(S{o,d})
            v(o,d) = 0;
            continue;
        end
        constraints = [constraints, v(o,d) >= E(o,d)^2];
        revenue(o,d) = E(o,d)*sum(S{o,d}, 'all')*D(o,d);
        revenue(o,d) = revenue(o,d) - v(o,d)*sum(S{o, d}.*(dist_norm.*dists + time_norm.*estimated_times), 'all')/Emax(o,d);
    end
end
revenue = sum(revenue, 'all');
end
