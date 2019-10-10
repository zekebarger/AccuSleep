function [labels] = enforceMinDuration(labels, limits, enforceInOrder, setUndef)
% enforceMinDuration Remove sleep stage bouts that are shorter than a threshold
% Zeke Barger 100119

%   This function replaces bouts of each sleep stage that are shorter than 
%   some limit with the surrounding stage, assuming the left and right
%   stages are the same. 

%   Arguments: 
%   labels - the vector of sleep stage labels (1=REM, 2=wake, 3=NREM)
%   limits - minimum # of epochs per bout of each brain state: [REM, wake, NREM]
%   enforceInOrder - the order in which the limits should be enforced. 
%       For example, to enforce wake, then REM, then NREM, use [2 1 3];
%       In most cases, the effect on the output will be minimal.
%   setUndef - 1=yes,0=no, set short periods to undefined state (4)
%
%   Output:
%   labels - an updated vector of sleep stage labels


% Check the inputs
if length(limits) ~= 3
    error('2nd argument must be a vector of length 3');
end
if max(limits) > length(labels)-2
    error('limit cannot be larger than length(state)-2');
end
if ~isequal(sort(enforceInOrder), 1:3)
    error('3rd argument must be a permutation of 1:3')
end
if ~(isfloat(labels) && (isfloat(limits) && isfloat(enforceInOrder)))
    error('all inputs should be numeric arrays. No need to get fancy')
end
if length(labels)<3
    disp('Input was too short to bother changing')
    return
end


% make state a row if it's not already, but keep track of the original shape
if ~isrow(labels)
    labels = labels';
    wascol=1;
else
    wascol=0;
end

for i = enforceInOrder % for each brain state i
    for j = setxor(i,1:3) % find short periods surrounded by some other brain state j
        for k = 1:(limits(i)-1) % for each length k below the limit
            % find indices where sequences start
            idx = strfind(labels,[j, repmat(i,1,k), j]);
            if ~isempty(idx)
                % replace with surrounding state j
                if setUndef
                    labels(idx+(1:k)') = 4;
                else
                    labels(idx+(1:k)') = j;
                end
            end
        end
    end
end

if wascol
    labels = labels';
end