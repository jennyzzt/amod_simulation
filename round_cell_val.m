function cellval = round_cell_val(x, precision)
% round a cell values to a precision with the same cell shape
if precision == Inf
    cellval = x;
    return;
end
if ~isa(x, 'cell')
    cellval = round(x, precision);
    return;
end
cellval = cellfun(@(v) round_cell_val(v, precision), x, 'UniformOutput', false);
end
