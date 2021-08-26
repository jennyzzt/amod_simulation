function [indegs, outdegs] = getdegrees(flows, graph)
% return the in-degree and out-degree of each node corresponding to
% a set of flows
indegs = zeros(numnodes(graph), 1, 'like', sdpvar);
outdegs = zeros(numnodes(graph), 1, 'like', sdpvar);
for i=1 : numedges(graph)
    flow = flows(i);
    outnode = graph.Edges.EndNodes(i, 1);
    innode = graph.Edges.EndNodes(i, 2);
    outdegs(outnode) = outdegs(outnode) + flow;
    indegs(innode) = indegs(innode) + flow;
end
end