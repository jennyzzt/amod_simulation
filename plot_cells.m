function [] = plot_cells(X, Y, objs, varargin)
% plot a line graph for each cell in cell_values
fig = figure;
hold on;
cellfun(@(x, y) plot(x, y, 'o-'), X, Y);
hold off;
% save into results folder
prefix = '';
if ~isempty(varargin)
    prefix = strcat('_', varargin{1});
end
fname = sprintf('./results/progress%s_%s.fig', prefix, char(string(objs)));
saveas(fig, fname);
end