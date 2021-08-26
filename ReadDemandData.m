close all;
clear;
clc;

% open data file
% fid = fopen('./TransportationNetworks/SiouxFalls/SiouxFalls_trips.tntp');
fid = fopen('./TransportationNetworks/Eastern-Massachusetts/EMA_trips.tntp');
limit = Inf;
dem_scale = 0.001;

% skip metadata, empty lines or comments
tline = fgetl(fid);
while isempty(tline) || tline(1) == '<' || tline(1) == '~'
    % get NUMBER OF ZONES macro
    if contains(tline, 'NUMBER OF ZONES')
        n_nodes = str2double(regexp(tline, '\d*', 'Match'));
        n_nodes = min(n_nodes, limit);
    end
    tline = fgetl(fid);
end

% variables to store data
D = zeros(n_nodes);

% read and store data
while ischar(tline)
    if contains(tline, 'Origin')
        origin = str2double(regexp(tline, '\d*', 'Match'));
        if origin > limit
            tline = fgetl(fid);
            continue
        end
        tline = fgetl(fid);
        while ischar(tline) && ~isempty(tline) && tline(1) ~= '~'
            dlines = split(tline, ';');
            for i=1 : length(dlines)
                dline = dlines{i};
                dline = dline(~isspace(dline));
                if ~isempty(dline)
                    data = split(dline, ':');
                    dest = str2double(data{1});
                    if dest > limit
                        continue
                    end
                    demand = str2double(data{2});
                    D(origin, dest) = dem_scale * demand;
                end
            end
            tline = fgetl(fid);
        end
    end
    tline = fgetl(fid);
end

fclose(fid);
save data_dem.mat D