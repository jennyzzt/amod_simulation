close all;
clear;
clc;

% graph settings
edges_start = [1, 1, 2, 3];
edges_end = [2, 3, 1, 2];
edges_freetime = [15, 10, 15, 6];
edges_capacity = [5, 10, 5, 10];
edges_length = [15, 10, 15, 6];

G = digraph(edges_start, edges_end, edges_length);
G.Edges.freetime = transpose(edges_freetime);
G.Edges.capacity = transpose(edges_capacity);
G.Edges.length = transpose(edges_length);
n_edges = numedges(G);
n_nodes = numnodes(G);

% max price strat - proportional to shortest distance
unit_price = 3;
Emax = zeros(n_nodes, n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        [~, dist] = shortestpath(G, o, d);
        Emax(o, d) = unit_price * dist;
    end
end

% demand settings
D = zeros(n_nodes);
D(1, 2) = 20;
D(1, 3) = 2;
D(2, 1) = 5;
D(2, 3) = 2;
D(3, 1) = 2;
D(3, 2) = 2;

save data_simple.mat G Emax D n_edges n_nodes