function constraints = get_pathselection_constraints(s, du, graph)
L = incidence(graph);
constraints = [];
n_nodes = length(du);
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d || isempty(s{o,d})
            continue;
        end
        e = zeros(n_nodes, 1, 'like', sdpvar);
        e(o) = -du(o, d);
        e(d) = du(o, d);
        constraints = [constraints, L * s{o,d} == e];
    end
end
end