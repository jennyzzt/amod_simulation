close all;
clear;
clc;

% open data file
% fid = fopen('./TransportationNetworks/SiouxFalls/SiouxFalls_node.tntp');
fid = fopen('./TransportationNetworks/Eastern-Massachusetts/EMA_node.tntp');
limit = Inf;

% skip metadata, empty lines or comments
tline = fgetl(fid);
while isempty(strip(tline)) || tline(1) == '<' || tline(1) == '~' || contains(tline, 'Node')
    tline = fgetl(fid);
end

% variables to store data
node_coords = cell(2,1);

% read and store data
while ischar(tline)
    dline = split(tline);
    for i=1 : length(node_coords)
        node_coords{i}(end+1) = str2double(dline{i+1});
    end
    tline = fgetl(fid);
end

fclose(fid);

save data_coord.mat node_coords
