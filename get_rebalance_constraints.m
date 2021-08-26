function constraints = get_rebalance_constraints(f, graph)
I = incidence(graph);
n_nodes = numnodes(graph);
constraints = [I * f == zeros(n_nodes, 1)];
end