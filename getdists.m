function dists = getdists(graph, od_paths)
% get all distances of the given paths in graph
n_nodes = numnodes(graph);
dists = cell(n_nodes, n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d
            dists{o, d} = [];
            continue;
        end
        paths = od_paths{o, d};
        n_paths = length(paths);
        dists{o, d} = zeros(1, n_paths);
        for i=1 : n_paths
            dists{o, d}(i) = getdist(graph, paths{i});
        end
    end
end
end

function dist = getdist(graph, path)
indices = findedge(graph, path(1:end-1), path(2:end));
dist = sum(graph.Edges.length(indices), 'all');
end