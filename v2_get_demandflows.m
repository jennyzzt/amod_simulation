function flow = v2_get_demandflows(split, demand)
% return the resulting flows used to satisfy the demand 
% using the split selection
n_nodes = length(split);
flow = cell(n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        if isempty(split{o,d})
            continue
        end
        flow{o,d} = split{o,d}.*demand(o,d);
    end
end
end

