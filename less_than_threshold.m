function check = less_than_threshold(progress, threshold)
% check if the last value of each cell in progress is less than given
% threshold
check = ~isempty(progress{1});
if check
    for i=1 : length(progress)
        check = progress{i}(end) < threshold;
        if ~check
            break
        end
    end
end
end

