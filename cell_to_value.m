function cellval = cell_to_value(x)
% convert a cell of sdpvars to its values with the same cell shape
if ~isa(x, 'cell')
    cellval = value(x);
    return;
end
cellval = cellfun(@(v) cell_to_value(v), x, 'UniformOutput', false);
end
