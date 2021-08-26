function [] = analyse(solution, dispvar)
if ~solution.problem
    disp(value(dispvar));
else
    disp(solution.info);
    % yalmiperror(solution.problem);
end
end

