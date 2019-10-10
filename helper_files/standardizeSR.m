function x = standardizeSR(x, oldSR, newSR)
% standardizeSR  Take a signal and change its sampling rate w/o warnings
% Zeke Barger 100119
%
%   Arguments: (note that these are data, not paths to files)
%   x - a 1-D matrix of data
%   oldSR - the original sampling rate of x
%   newSR - the desired sampling rate for x
%
%   Output:
%   x - the data, either down- or up-sampled

warning('off','MATLAB:colon:nonIntegerIndex');
x = x(1:(oldSR/newSR):end);
warning('on','MATLAB:colon:nonIntegerIndex');