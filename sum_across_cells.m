function totalC = sum_across_cells(C)
% sum across the values in the cells
n = length(C);
totalC = C{1};
for i=2 : n
    if isempty(C{i})
        continue
    end
    if isempty(totalC)
        totalC = C{i};
        continue
    end
    totalC = totalC + C{i};
end
end