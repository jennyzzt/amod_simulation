function constraints = get_splitselection_constraints(s, graph)
L = incidence(graph);
constraints = [];
n_nodes = length(s);
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d || isempty(s{o,d})
            continue;
        end
        e = zeros(n_nodes, 1, 'like', sdpvar);
        e(o) = -1;
        e(d) = 1;
        constraints = [constraints, L * s{o,d} == e];
    end
end
end