function avgtimes = bpr_cx(flows, graph)
% return the avg time to travel through each edge by the bpr function
avgtimes = graph.Edges.freetime .* ...
    (1 + 0.15 .* cpower(flows./graph.Edges.capacity,4));
end

