function od_paths = getpaths(graph)
% get all paths in this graph
n_nodes = numnodes(graph);
od_paths = cell(n_nodes, n_nodes);
for o = 1 : n_nodes
    for d = 1 : n_nodes
        if o == d
            continue
        end
        paths = {};
        stack = {[o]};
        while ~isempty(stack)
            path = stack{1};
            curr = path(end);
            stack = stack(2:end);
            succs = successors(graph, curr);

            [paths_adds, stack_adds] = arrayfun(@(s) checknext(s, path, d), succs, 'UniformOutput', false);
            paths = [paths; paths_adds(~cellfun('isempty', paths_adds))];
            stack = [stack; stack_adds(~cellfun('isempty', stack_adds))];
        end
        od_paths{o, d} = paths;
    end
end
end

function [paths_addition, stack_addition] = checknext(adj, path, dest)
paths_addition = [];
stack_addition = [];
if ismember(adj, path)
    return;
end
next_path = horzcat(path, adj);
if adj == dest
    paths_addition = [next_path];
else
    stack_addition = [next_path];
end
end