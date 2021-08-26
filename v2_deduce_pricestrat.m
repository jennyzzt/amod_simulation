function partE = v2_deduce_pricestrat(pricemult, selection, dists, estimated_times)
dist_norm = 5; % additional price per distance mile
time_norm = 25; % additional price per unit time hour
n_nodes = length(selection);
partE = zeros(n_nodes, n_nodes, 'like', sdpvar);
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d || isempty(selection{o,d})
            continue;
        end
        partE(o, d) = pricemult(o,d) * sum(selection{o, d}.*(dist_norm.*dists + time_norm.*estimated_times), 'all');
    end
end
end