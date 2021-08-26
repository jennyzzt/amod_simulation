function cost = bpr_cx_cost(flows, graph)
% convex version of bpr.m function
% return the avg time cost to travel through each edge by the bpr function
cost = graph.Edges.freetime .* flows;
cost = cost + graph.Edges.freetime .* 0.15 .* cpower(flows, 5) ./ (graph.Edges.capacity.^4);
end
