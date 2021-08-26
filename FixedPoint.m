fromprev = false;
threshold = 0.01;

if ~fromprev
    n_iters = 0;
    progress_X = cell(n_ops, 1);
    progress_Y = cell(n_ops, 1);
end

while ~less_than_threshold(progress_Y, threshold) && n_iters < 1000
    for op=1 : n_ops
        Etmp = value(E{op});
        Stmp = cell_to_value(S{op});
        % fix all operators except op
        for i=1 : n_ops
            if i==op
                E{i} = sdpvar(n_nodes, n_nodes, 'full');
                E{i}(1:n_nodes+1:end) = zeros(1, n_nodes);
                Ssup{i} = sdpvar(n_edges, 1, 'full');
                for o=1 : n_nodes
                    for d=1 : n_nodes
                        if D(o,d) == 0
                            continue
                        end
                        S{i}{o,d} = sdpvar(n_edges, 1, 'full');
                    end
                end
            else
                E{i} = value(E{i});
                S{i} = cell_to_value(S{i});
                Ssup{i} = value(Ssup{i});
            end
        end
        
        % dependent variable Du - resulting demand for each operator
        Du = arrayfun(@(i) D.*demandprob(i, E, Emax, marketshare), transpose([1:n_ops]), 'UniformOutput', false);

        Constraints = [];
        addConstraints = cellfun(@get_greaterzero_constraints, Du, 'UniformOutput', false);
        Constraints = [Constraints, addConstraints{:}];
        addConstraints = get_greaterzero_constraints(E{op});
        Constraints = [Constraints, addConstraints];
        addConstraints = cellfun(@get_greaterzero_constraints, S{op}, 'UniformOutput', false);
        Constraints = [Constraints, addConstraints{:}];
        addConstraints = get_greaterzero_constraints(Ssup{op});
        Constraints = [Constraints, addConstraints];
        % path selection satisfies demand
        addConstraints = get_pathselection_constraints(S{op}, Du{op}, G);
        Constraints = [Constraints, addConstraints];

        % dependent variable Fu - flow through each edge for each operator
        Fu = cellfun(@(s, sup) sum([s{:}], 2) + sup, S, Ssup, 'UniformOutput', false);
        % supplement flows with vehicle rebalancing mechanism
        addConstraints = get_rebalance_constraints(Fu{op}, G);
        Constraints = [Constraints, addConstraints];
        % update edge avg travel time
        F_op = Fu{op};
        F_other = sum([Fu{1:op-1}, Fu{op+1:end}], 2);
        T_cost = bpr_cx_cost_op(F_op, F_other, G);
        D_cost = F_op.*G.Edges.length;

        % calculate cost, revenue, total satisfied demand
        Cost = unit_Tcost*sum(T_cost, 'all') + unit_Dcost*sum(D_cost, 'all');
        Revenue = sum(Du{op}.*E{op}, 'all');
        Profit = Revenue - Cost;
        Dutotal = sum(Du{op}, 'all');
        % add necessary constraints based on operator objective
        if objs(op) == 1
            % customer max objective
            Constraints = [Constraints, Cost - Revenue <= loss_limit_unit*marketshare(op)];
        end
        
        % single operator's objective
        if objs(op) == 1
            Objective = -Dutotal;
        else
            Objective = -Profit;
        end
        Options = sdpsettings('solver', 'gurobi', 'verbose', 0);
        Solution = optimize(Constraints, Objective, Options);
        analyse(Solution, Objective);
        
        % calculate progress made on decision variable
        Ediff = value(E{op}) - Etmp;
        Sdiff = cellfun(@(s, stmp) norm(s-stmp, Inf), cell_to_value(S{op}), Stmp);
        n_iters = n_iters + 1;
        progress_Y{op}(end+1) = norm(Ediff, Inf) + norm(Sdiff, Inf);
        progress_X{op}(end+1) = n_iters;
    end
end

plot_cells(progress_X, progress_Y, objs);

% save data to be analysed later
fname = sprintf('./results/results_%s_%s.mat', char(string(objs)), char(string(marketshare)));
savevars(fname, 'ne', E, S, Ssup);