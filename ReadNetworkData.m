close all;
clear;
clc;

% open data file
% fid = fopen('./TransportationNetworks/SiouxFalls/SiouxFalls_net.tntp');
fid = fopen('./TransportationNetworks/Eastern-Massachusetts/EMA_net.tntp');
limit = Inf;
unit_price = 3;
dem_scale = 0.001;
time_scale = 1;

% skip metadata, empty lines or comments
tline = fgetl(fid);
while isempty(strip(tline)) || tline(1) == '<' || tline(1) == '~'
    tline = fgetl(fid);
end

% variables to store data
edges_data = {};

% read and store data
while ischar(tline) && ~isempty(strip(tline)) && tline(1) ~= '~'
    dline = split(tline);
    if size(edges_data) == 0
        edges_data = cell(length(dline), 1);
    end
    for i=1 : length(dline)
        val = str2double(dline{i});
        if ~isnan(val)
            edges_data{i}(end+1) = val;
        end
    end
    tline = fgetl(fid);
end

fclose(fid);

% process data according to limit
edges_data = edges_data(~cellfun('isempty', edges_data));
idx = (edges_data{1} <= limit) & (edges_data{2} <= limit);
edges_data = cellfun(@(d) d(idx), edges_data, 'UniformOutput', false);

% store in graph format
G = digraph(edges_data{1}, edges_data{2}, edges_data{4});
G.Edges.capacity = transpose(edges_data{3}.*dem_scale);
G.Edges.length = transpose(edges_data{4});
G.Edges.freetime = transpose(edges_data{5}.*time_scale);
G.Edges.bpr_b = transpose(edges_data{6});
G.Edges.bpr_pow = transpose(edges_data{7});
n_edges = numedges(G);
n_nodes = numnodes(G);

% max price strat - proportional to shortest distance
Emax = zeros(n_nodes, n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        [~, dist] = shortestpath(G, o, d);
        Emax(o, d) = unit_price * dist;
    end
end

save data_net.mat G n_edges n_nodes Emax
