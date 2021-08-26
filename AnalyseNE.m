close all;
clear;
clc;

% load graph settings from data_net.mat
load data_net.mat
% load demand settings from data_dem.mat
load data_dem.mat

dem_scale = 1000;
D = D*dem_scale;
G.Edges.capacity = G.Edges.capacity*dem_scale;

dem_scale = 1000;

% game settings
unit_Tcost = 30;
unit_Dcost = 1;
objs = {[1], [1,1], [1,1,1], [0], [0,0], [0,0,0]};
marketshare = {[1], [1,1], [1,1,1], [1], [1,1], [1,1,1]};

% files containing results
base_folderdir = './results';
fnames = cellfun(@(obj, ms) sprintf('%s/results_%s_%s.mat', base_folderdir,...
    char(string(obj)), char(string(ms))), objs, marketshare, 'UniformOutput', false);
% extract data from files
data = cellfun(@(f,o,ms) extract_data(f, o, ms, dem_scale, 8), fnames, objs, marketshare);
% process data
data_proc = arrayfun(@(d) process_data(d, G, D, Emax, unit_Tcost, unit_Dcost), data);
% analyse data for customer and society
data_calc = arrayfun(@(d) analyse_data(d), data_proc);

savevars('./results/analyse_initial.mat', '', data, data_calc, data_proc);

%% Second comparison analysis after running AnalyseNE_optflows.m

dem_scale = 1000;

% files containing results
base_folderdir = './results';
fnames = cellfun(@(obj,ms) sprintf('%s/matched_%s_%s.mat', base_folderdir,...
    char(string(obj)), char(string(ms))), objs, marketshare, 'UniformOutput', false);
% extract data from files
datam = cellfun(@(f,o,ms) extract_datam(f, o, ms, dem_scale, 8), fnames, objs, marketshare);
% process data
datam_proc = arrayfun(@(d) process_datam(d, G, unit_Tcost, unit_Dcost), datam);
% analyse data for customer and society
datam_calc = arrayfun(@(d) analyse_datam(d), datam_proc);

savevars('./results/analyse_matched.mat', '', datam, datam_calc, datam_proc);

%% Asymmetric dominance congestion analysis

dom = 2;
normS = cell(length(data_proc), 1);
matS = cell(length(data_proc), 1);
for i=1 : length(data_proc)
    normS{i} = data_proc(i).S{dom};
    matS{i} = datam_proc(i).S;
    for o=1 : n_nodes
        for d=1 : n_nodes
            if isempty(normS{i}{o,d})
                continue
            end
            normS{i}{o,d} = normS{i}{o,d} ./ data_proc(i).Du{dom}(o,d);
            matS{i}{o,d} = matS{i}{o,d} ./ data_proc(i).Du{dom}(o,d);
        end
    end
end
diff = cellfun(@(N,M) sum(cellfun(@(n,m) norm(round(n,3)-round(m,3), 2), N, M),'all'), normS, matS);

%% Plots for better visualisation
G.Edges.Weight = G.Edges.freetime;

tog_network = 'siouxfalls'; % network used - siouxfalls or ema
tog_timeprice = 1; % 0-time, 1-price
tog_norm = true; % true-norm

caxis_scale = [0.2, 0.9]; % to be changed to something suitable
tog_printaxis = 1; % to print colorbar in a separate figure
tog_colorbar = ~tog_printaxis; % to print colorbar in figure itself

h = brewermap([],'Spectral');
% h = brewermap([],'PuOr');
h = flip(h);
% h = parula;
tog_colormap = h; % colormap used in figures

for i=1 : length(data_calc)
    if tog_timeprice == 0
        dataplot = data_calc(i).avgridetime;
        metric_name = 'avgtime';
        if tog_norm
            metric_name = append('norm', metric_name);
            dataplot = dataplot ./ distances(G);
        end
    else
        dataplot = data_calc(i).avgrideprice;
        metric_name = 'avgprice';
        if tog_norm
            metric_name = append('norm', metric_name);
            dataplot = dataplot ./ Emax;
        end
    end
    dataplot(isnan(dataplot)) = 0;
    plot_mesh(dataplot, tog_colorbar, tog_colormap);
    if ~isempty(caxis_scale)
        caxis(caxis_scale);
    end
    ax = gca;
    figname = sprintf('../%s-%s-%s-%s.png', ...
        tog_network, metric_name, ...
        char(string(data_calc(i).game)), char(string(data_calc(i).market)));
    exportgraphics(ax,figname,'Resolution',800);
end

if tog_printaxis
    ax = axes;
    caxis(caxis_scale);
    colorbar;
    ax.Visible = 'off';
    colormap(h);
    set(ax,'FontName','Cambria Math','FontSize',24);
    colorbar(ax,'Position',...
        [0.5 0.147619047619048 0.058095238095238 0.778571428571429]);
    if data_calc(1).game
        obj_name = 'cust';
    else
        obj_name = 'profit';
    end
    axis_name = sprintf('../%s-%s-colorbar-%s.png',...
        tog_network, metric_name, obj_name);
    exportgraphics(ax,axis_name,'Resolution',800);
end

%% Internal Used Functions

function data = extract_data(fname, obj, ms, dem_scale, precision)
% reads the vars stored in fname and returns a struct containing the data
load(fname, 'ne_E', 'ne_S', 'ne_Ssup');
data.game = obj;
data.market = ms;
if length(obj) == 1 || contains(fname, 'matched')
    data.E = {round_cell_val(ne_E,precision)};
    data.S = {cellfun(@(e) dem_scale*round_cell_val(e,precision), ne_S, 'UniformOutput', false)};
    data.Ssup = {dem_scale*round_cell_val(ne_Ssup,precision)};
    return;
end
data.E = round_cell_val(ne_E,precision);
data.S = cellfun(@(e) cellfun(@(s) dem_scale*round_cell_val(s,precision), e, 'UniformOutput', false), ne_S, 'UniformOutput', false);
data.Ssup = cellfun(@(e) dem_scale*round_cell_val(e,precision), ne_Ssup, 'UniformOutput', false);
end

function data_proc = process_data(data, G, D, Emax, unit_Tcost, unit_Dcost)
n_ops = length(data.E);
data_proc = data;
if n_ops == 1
    data_proc.Du = cellfun(@(e) D.*demandprob(1, {e}, Emax, [1]), data.E, 'UniformOutput', false);
else
    data_proc.Du = arrayfun(@(i) D.*demandprob(i, data.E, Emax, data.market), transpose([1:n_ops]), 'UniformOutput', false);
end
data_proc.Fu = cellfun(@(s, sup) sum([s{:}], 2) + sup, data.S, data.Ssup, 'UniformOutput', false);
data_proc.F = sum([data_proc.Fu{:}], 2);
data_proc.T = bpr(data_proc.F, G);
data_proc.Tcost = cellfun(@(fu) unit_Tcost*sum(fu.*data_proc.T, 'all'), data_proc.Fu);
data_proc.Dcost = cellfun(@(fu) unit_Dcost*sum(fu.*G.Edges.length, 'all'), data_proc.Fu);
data_proc.Cost = data_proc.Tcost + data_proc.Dcost;
data_proc.Revenue = cellfun(@(du, e) sum(du .* e, 'all'), data_proc.Du, data_proc.E);
data_proc.Profit = data_proc.Revenue - data_proc.Cost;
data_proc.Dutotal = cellfun(@(du) sum(du, 'all'), data_proc.Du);
end

function data_calc = analyse_data(data_proc)
data_calc.game = data_proc.game;
data_calc.market = data_proc.market;
data_calc.avgridetime = calc_avgridetime(data_proc.S, data_proc.T, data_proc.Du);
data_calc.avgrideprice = calc_avgrideprice(data_proc.E, data_proc.Du);
data_calc.FT = sum(data_proc.F.*data_proc.T, 'all');
end

function datam = extract_datam(fname, obj, ms, dem_scale, precision)
% reads the vars stored in fname and returns a struct containing the data
load(fname, 'ne_Dt', 'ne_S', 'ne_Ssup');
datam.game = obj;
datam.market = ms;
datam.Dt = dem_scale.*ne_Dt;
datam.S = cellfun(@(e) dem_scale*round_cell_val(e,precision), ne_S, 'UniformOutput', false);
datam.Ssup = dem_scale*round_cell_val(ne_Ssup,precision);
end

function datam_proc = process_datam(datam, G, unit_Tcost, unit_Dcost)
datam_proc = datam;
datam_proc.Fu = sum([datam.S{:}], 2) + datam.Ssup;
datam_proc.T = bpr(datam_proc.Fu, G);
datam_proc.Tcost = unit_Tcost*sum(datam_proc.Fu.*datam_proc.T, 'all');
datam_proc.Dcost = unit_Dcost*sum(datam_proc.Fu.*G.Edges.length, 'all');
datam_proc.Cost = datam_proc.Tcost + datam_proc.Dcost;
datam_proc.Dutotal = sum(datam.Dt, 'all');
end

function datam_calc = analyse_datam(datam_proc)
datam_calc.game = datam_proc.game;
datam_calc.market = datam_proc.market;
datam_calc.avgridetime = calc_avgridetime({datam_proc.S}, datam_proc.T, {datam_proc.Dt});
datam_calc.FT = sum(datam_proc.Fu.*datam_proc.T, 'all');
end

function avgridetime = calc_avgridetime(S, T, Du)
n_ops = length(S);
ridetime = cellfun(@(Si, Di) cellfun(@(s) calc_pathtime(s, T), Si), S, Du, 'UniformOutput', false);
totalridetime = ridetime{1};
for i=2 : n_ops
    totalridetime = totalridetime + ridetime{i};
end
totalDu = sum_across_cells(Du);
avgridetime = totalridetime ./ totalDu;
n = length(avgridetime);
avgridetime(1:n+1:end) = zeros(1, n);
end

function time = calc_pathtime(s, T)
if isempty(s)
    time = 0;
else
    time = sum(s.*T, 'all');
end
end

function avgrideprice = calc_avgrideprice(E, Du)
n_ops = length(E);
ridepaid = cellfun(@(e, du) e.*du, E, Du, 'UniformOutput', false);
totalridepaid = ridepaid{1};
for i=2 : n_ops
    totalridepaid = totalridepaid + ridepaid{i};
end
totalDu = sum_across_cells(Du);
avgrideprice = totalridepaid ./ totalDu;
n = length(avgrideprice);
avgrideprice(1:n+1:end) = zeros(1, n);
end

function s = plot_mesh_together(data)
Z = data{1};
Z = extend_nan(Z);
for i=1 : length(data)
    tmp = data{i};
    tmp = extend_nan(tmp);
    Z = [Z tmp];
end
s = plot_mesh(Z);
end

function A = extend_nan(A)
% append nan to the last column and row
A(:, end+1) = nan(size(A, 1), 1);
A(end+1, :) = nan(1, size(A, 2));
end

function s = plot_mesh(Z, tog_colorbar, tog_colormap)
figure;
hold on;
Z(:, end+1) = Z(:, end);
Z(end+1, :) = Z(end, :);
s = pcolor(Z);
colormap(tog_colormap);
axis equal;
if tog_colorbar
    colorbar;
end
set(gca,'Visible','off');
hold off;
end