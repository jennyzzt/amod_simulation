function Emax = calc_maxprice(P_dist)
% calculate the max price strategy for each o-d pair
% max price is proportional to the shortest distance between o-d pair
unit_price = 3; % scaling constant
n_nodes = length(P_dist);
Emax = zeros(n_nodes, n_nodes);
for o=1 : n_nodes
    for d=1 : n_nodes
        if o==d
            continue;
        end
        Emax(o, d) = unit_price * min(P_dist{o, d});
    end
end
end