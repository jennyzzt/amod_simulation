function prob = demandprob(op, allpricestrat, maxpricestrat, marketshare)
% returns the probability matrix for demand for each o-d pair for op
n_ops = length(allpricestrat);
n_nodes = length(maxpricestrat);
prob = marketshare(op)/sum(marketshare, 'all');
marketnorm = sum(marketshare, 'all')/marketshare(op)/n_ops;
prob = prob - marketnorm.*allpricestrat{op}./maxpricestrat;
prob(1:n_nodes+1:end) = zeros(1, n_nodes);
for i=1 : n_ops
    if i ~= op
        marketnorm = marketshare(i)/sum(marketshare, 'all');
        addprob = marketnorm.*allpricestrat{i}./maxpricestrat;
        addprob(1:n_nodes+1:end) = zeros(1, n_nodes);
        prob = prob + addprob;
    end
end
end