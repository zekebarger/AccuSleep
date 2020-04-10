function [labels] = enforceMinDuration(labels, limits, enforceInOrder, setUndef)
% enforceMinDuration Remove sleep stage bouts that are shorter than a threshold
% Zeke Barger 040920

%   This function replaces bouts of each sleep stage that are shorter than
%   some limit with the surrounding stage, assuming the left and right
%   stages are the same.

%   Arguments:
%   labels - the vector of sleep stage labels (1=REM, 2=wake, 3=NREM)
%   limits - minimum # of epochs per bout of each brain state: [REM, wake, NREM]
%   enforceInOrder - DEPRECATED. Now unused.
%       PREVIOUSLY: the order in which the limits should be enforced.
%       For example, to enforce wake, then REM, then NREM, use [2 1 3];
%       In most cases, the effect on the output will be minimal.
%   setUndef - DEPRECATED. Now unused.
%       PREVIOUSLY: 1=yes,0=no, set short periods to undefined state (4)
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
% if ~isequal(sort(enforceInOrder), 1:3)
%     error('3rd argument must be a permutation of 1:3')
% end
% if ~(isfloat(labels) && (isfloat(limits) && isfloat(enforceInOrder)))
%     error('all inputs should be numeric arrays. No need to get fancy')
% end
if length(labels) < 3
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

% see if we've done our job
% finished = 0;

% fix shortest bouts first, then longer ones
while 1
    labelsStr = erase(num2str(labels),' '); % convert to a string for regex search
    % There is probably a regex that can find all ab+a patterns without consuming
    % the a's but I haven't found it :(
    
    % find all bouts that need to be merged
    % put them in a table with  col 1: length, col 2: start index,
    % col 3: end index, col 4: state, col 5: surrounding state
    bouts = [];
    
    for i = 1:3 % for each brain state
        for j = setxor(i,1:3) % for each possible surrounding state
            % get start and end indices of each bout
            [startIndex,endIndex] = regexp(labelsStr,['(?<=',num2str(j),')',...
                num2str(i),'{1,',num2str(limits(i)-1),'}(?=',num2str(j),')']);
            % if some bouts were found
            if ~isempty(startIndex)
                bouts = [bouts; [(endIndex-startIndex+1)',...
                    startIndex',endIndex',ones(length(startIndex),1)*i, ones(length(startIndex),1)*j]];
            end
        end
    end
    
    % if no more bouts need to be merged, break out of the loop
    if isempty(bouts)
        break
    end
    
    % sort the bouts by length, then by position
    ordered_bouts = sortrows(bouts);
    
    % only deal with the shortest bouts, for now
    ordered_bouts(ordered_bouts(:,1) > ordered_bouts(1,1), :)=[];
    
    % Work through the list. If several bouts of the same length are
    % adjacent, either eliminate them all or create a transition halfway
    % through if there are an even or odd number of short bouts,
    % respectively.
    while ~isempty(ordered_bouts)
        % get row index of latest adjacent bout (of same length)
        end_row = find_last_adjacent_bout(ordered_bouts, 1);
        % if it's an even number
        if mod(end_row,2) == 0
            % create a transition halfway through
            labels(ordered_bouts(1,2):ordered_bouts(end_row/2, 3)) = ordered_bouts(1,5);
            labels(ordered_bouts(end_row/2 + 1,2):ordered_bouts(end_row, 3)) = ordered_bouts(end_row,5);
            
        else % odd number
            % eliminate them all
            labels(ordered_bouts(1,2):ordered_bouts(end_row, 3)) = ordered_bouts(1,5);
        end
        
        % delete the fixed bouts from the list
        ordered_bouts(1:end_row,:) = [];
    end  
end

% change shape back to how it started
if wascol
    labels = labels';
end
end

% get row index of latest adjacent bout (of same length) recursively
function end_row = find_last_adjacent_bout(ordered_bouts,start_row)
% if we're at the end of the bout list, stop
if start_row == size(ordered_bouts,1)
    end_row = start_row;
    return
end
% if there is an adjacent bout
if ordered_bouts(start_row, 3) == ordered_bouts(start_row + 1, 2) + 1
    % look for more adjacent bouts using that one as a starting point
    end_row = find_last_adjacent_bout(ordered_bouts, start_row + 1);
else % no adjacent bout
    end_row = start_row;
end
end
