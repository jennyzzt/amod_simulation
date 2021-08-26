close all;
clear;
clc;

% load graph and demand settings from data_simple.mat
load data_simple.mat

% game settings
n_ops = 2;
objs = zeros(1, n_ops); % operators' objectives: 0 - profit max, 1 - customer max

% variable - pricing strat for each operator
syms E [n_nodes, n_nodes, n_ops];
% dependent variable - resulting demand for each operator
Du = splitdemand(D, E, Emax);

% variable - flow selection for each operator
syms S [n_edges, n_nodes, n_nodes, n_ops];

% supplement flows with vehicle rebalancing mechanism
syms Ssup [n_edges, n_ops];
tmp = sum(S, [2, 3, 4]);
Fu = reshape(sum(S, [2, 3]), [], 2) + Ssup;
F = sum(Fu, 2);

% update edge avg travel time
T = bpr(F, G);

% calculate cost, revenue, total satisfied demand
Cost = sym(zeros(n_ops, 1));
Revenue = sym(zeros(n_ops, 1));
Profit = sym(zeros(n_ops, 1));
Dutotal = sym(zeros(n_ops, 1));
for i=1 : n_ops
    Cost(i) = sum(Fu(:,i) .* T, 'all');
    Revenue(i) = sum(Du(:, :, i) .* E(:, :, i), 'all');
    Profit(i) = Revenue(i) - Cost(i);
    Dutotal(i) = sum(Du(:, :, i), 'all');
end

% all variables
X_all = [reshape(E, 1, []) ...
         reshape(S, 1, []) ...
         reshape(Ssup, 1, [])];
size_horizon = length(X_all);

% variables' constraints
Set.Aineq = -eye(size_horizon);
Set.bineq = zeros(size_horizon, 1);
Set.Aeq = [];
Set.beq = [];
Set.lb = zeros(size_horizon, 1);
Set.ub = [];
% assumeAlso(E >= 0)
% assumeAlso(S >= 0)
% assumeAlso(Fsup >= 0)
for i=1 : n_ops
    for o=1 : n_nodes
        for d=1 : n_nodes
            % flow selection satisfies demand
            [indegs, outdegs] = getdegrees(S(:, o, d, i), G);
            diffdegs = indegs - outdegs;
            for j=1 : n_nodes
                tmp = diffdegs(j);
                if j==o
                    tmp = tmp + Du(o, d, i);
                elseif j==d
                    tmp = tmp - Du(o, d, i);
                end
                [c, t] = coeffs(tmp);
                Aeq = zeros(1, size_horizon);
                for k=1 : length(t)
                    Aeq(X_all == t(k)) = c(k);
                end
                Set.Aeq = vertcat(Set.Aeq, Aeq);
                Set.beq(end+1, 1) = 0;
            end
            % pricing strategies for same o-d should be zero
            if o==d
                Aeq = zeros(1, size_horizon);
                k = X_all == E(o, d, i);
                Aeq(k) = 1;
                Set.Aeq = vertcat(Set.Aeq, Aeq);
                Set.beq(end+1, 1) = 0;
            end
        end
    end
    % vehicle rebalancing constraint
    [indegs, outdegs] = getdegrees(Fu(:, i), G);
    % assumeAlso(indegs - outdegs == 0)
    diffdegs = indegs - outdegs;
    for j=1 : n_nodes
        [c, t] = coeffs(diffdegs(j));
        Aeq = zeros(1, size_horizon);
        for k=1 : length(t)
            Aeq(X_all == t(k)) = c(k);
        end
        Set.Aeq = vertcat(Set.Aeq, Aeq);
        Set.beq(end+1, 1) = 0;
    end
end

% calculate game map
F_gm_all = cell(n_ops, 1);
f_gm_all = cell(n_ops, 1);
for i=1 : n_ops
    X = [reshape(E(:, :, i), 1, []) ...
         reshape(S(:, :, :, i), 1, []) ...
         reshape(Ssup(:, i), 1, [])];
    if objs(i) == 0
        cost_fn = -Profit(i);
    elseif objs(i) == 1
        cost_fn = -Dutotal(i);
    end
    J = jacobian(cost_fn, X);
    [F_gm_op, f_gm_op] = get_gamemap_op(J, X_all);
    F_gm_all{i} = F_gm_op;
    f_gm_all{i} = f_gm_op;
end
% stack together for game map
F_gm = vertcat(F_gm_all{:});
f_gm = vertcat(f_gm_all{:});

upper_bound_avg = 1/n_ops; % coupling constr: upper bound mean
Acoup = repmat(eye(size_horizon), 1, n_ops);
bcoup = n_ops * upper_bound_avg * ones(size_horizon, 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = zeros(size_horizon, 1);
step_size = 0.1; % TODO: need to determine this

for i=1 : 1000
    x_next = proj(x - step_size*F_gm*x, Set);
    x = x_next;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function check_pos_def(M)
[~,p] = chol(M); % p = 0 if M pos. def., p > 0 otherwise
definiteness_string = 'Matrix is positive definite';
if (p > 0)
    definiteness_string = 'Matrix is not positive definite';
end
disp(definiteness_string);
end

function resdemand = splitdemand(demand, allpricestrat, maxpricestrat)
% returns the resulting demand for each op
shape = size(allpricestrat);
n_ops = shape(end);
for op=1 : n_ops
    prob = 1/n_ops;
    prob = prob - allpricestrat(:,:,op)./maxpricestrat;
    for i=1 : n_ops
        if i ~= op
            prob = prob + allpricestrat(:,:,i)./(n_ops.*maxpricestrat);
        end
    end
    resdemand(:,:,op) = demand .* prob;
end
end

function [indegs, outdegs] = getdegrees(flows, graph)
% return the in-degree and out-degree of each node corresponding to
% a set of flows
indegs = sym(zeros(numnodes(graph), 1));
outdegs = sym(zeros(numnodes(graph), 1));
for i=1 : numedges(graph)
    flow = flows(i);
    outnode = graph.Edges.EndNodes(i, 1);
    innode = graph.Edges.EndNodes(i, 2);
    outdegs(outnode) = outdegs(outnode) + flow;
    indegs(innode) = indegs(innode) + flow;
end
end

function [F, f] = get_gamemap_op(J, X)
% get game map of one operator - Jacobian(Cost_i, X_i) = F.X_i + f
n_vars = length(X);
n_terms = length(J);
F = zeros(n_terms, n_vars);
f = zeros(n_terms, 1);
for i=1 : n_terms
    for j=1 : n_vars
        [c, t] = coeffs(J(i), X(j));
        if ~isempty(t) && t(1) ~= 1
            F(i, j) = F(i, j) + c(1);
        end
    end
    [c, t] = coeffs(J(i));
    if ~isempty(t) && t(end) == 1
        f(i) = f(i) + c(end);
    end
end
end

function x_new = proj(x, Set)
% projection of x on the set described by Set  
% opt = optimoptions('quadprog','Display','off');
H = 2*eye(length(x));
f = -2*x;
x_new = quadprog(H,f,Set.Aineq,Set.bineq,Set.Aeq,Set.beq,Set.lb,Set.ub,x);
end