function avgtimes = bpr(flows, graph)
% return the avg time to travel through each edge by the bpr function
avgtimes = graph.Edges.freetime .* ...
    (1 + 0.15 .* (flows.^4) ./ (graph.Edges.capacity.^4));
end

