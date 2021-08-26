function [partE, partS, partSsup] = create_vars(n_nodes, n_edges, demand)
partE = sdpvar(n_nodes, n_nodes, 'full');
partE(1:n_nodes+1:end) = zeros(1, n_nodes);
% partS = arrayfun(@(~) sdpvar(n_edges, 1, 'full'), zeros(n_nodes), 'UniformOutput', false);
% partS(1:n_nodes+1:end) = mat2cell(repmat(zeros(n_edges, 1, 'like', sdpvar), 1, n_nodes), n_edges, ones(n_nodes, 1));
partSsup = sdpvar(n_edges, 1, 'full');
% corrected for sparse demand
partS = cell(n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        if demand(o,d) == 0
            continue
        end
        partS{o,d} = sdpvar(n_edges, 1, 'full');
    end
end
end