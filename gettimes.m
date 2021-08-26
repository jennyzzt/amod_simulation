function times = gettimes(graph, graph_times, od_paths)
% get all estimated times of the given paths in graph
n_nodes = numnodes(graph);
times = cell(n_nodes, n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d
            times{o, d} = [];
            continue;
        end
        paths = od_paths{o, d};
        n_paths = length(paths);
        times{o, d} = zeros(1, n_paths, 'like', sdpvar);
        for i=1 : n_paths
            times{o, d}(i) = gettime(graph, graph_times, paths{i});
        end
    end
end
end

function time = gettime(graph, graph_times, path)
indices = findedge(graph, path(1:end-1), path(2:end));
time = sum(graph_times(indices), 'all');
end