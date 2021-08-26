function savevars(filename, prefix, varargin)
% save the given data into filename with the prefix added to their names
nvarargin = nargin - length(varargin);
for i=1 : nargin-nvarargin
    var_name = inputname(i+nvarargin);
    if ~isempty(prefix)
        var_name = append(prefix, '_', inputname(i+nvarargin));
    end
    data = varargin{i};
    tmp.(var_name) = cell_to_value(data);
    if exist(filename, 'file')
        save(filename, '-struct', 'tmp', var_name, '-append');
    else
        save(filename, '-struct', 'tmp', var_name);
    end
end
end
