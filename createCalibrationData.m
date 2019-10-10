function [calibrationData] = createCalibrationData(EEG, EMG, labels, SR, epochLen)
% CREATECALIBRATIONDATA  Calculate parameters for mixture z-scoring
% Zeke Barger 100119
%
%   Arguments: (note that these are data, not paths to files)
%   EEG - a 1-D matrix of EEG data
%   EMG - a 1-D matrix of EMG data
%   labels - 1-D matrix of sleep stage labels. 1=REM, 2=wake, 3=NREM, other
%       labels will be ignored
%   SR - the EEG/EMG sampling rate, in Hz
%   epochLen - length of each epoch, in seconds
%
%   Background:
%   Before classifying EEG/EMG data from a given subject recorded on a given
%   recording setup, it is necessary to scale the features of the data so
%   that they resemble the classifier's training data. See the accompanying
%   paper for details.
%
%   Output:
%   calibrationData - a set of parameters for mixture z-scoring. These are
%   required by AccuSleep_GUI or AccuSleep_classify when classifying sleep
%   stages automatically.

% set the fixed mixture weights
weights = [.1 .35 .55]; % rem, wake, nrem

% create the spectrogram
[s, t, f] = createSpectrogram(EEG, SR, epochLen);
% check if labels has the correct length
if length(t) ~= length(labels)
    calibrationData = [];
    disp('Labels are not the proper length for this recording');
    return
end
% check if there are at least a few labeled epochs for each state
if ~all([sum(labels==1)>=3, sum(labels==2)>=3, sum(labels==3)>=3])
    calibrationData = [];
    disp('At least a few epochs of each state must be labeled');
    return
end

% select frequencies up to 50 Hz, and downsample between 20 and 50 Hz
[~,f20idx] = min(abs(f - 20)); % index in f of 20Hz
[~,f50idx] = min(abs(f - 50)); % index in f of 50Hz
s = s(:, [1:(f20idx-1), f20idx:2:f50idx]);
% take log of the spectrogram
s = log(s);
% calculate log rms for each EMG bin
processedEMG = processEMG(EMG, SR, epochLen);

% make an image for the entire recording
s = [s, processedEMG']; % we only need one of the emg columns

m = zeros(size(s, 2), 3);
v = zeros(size(s, 2), 3);
% for each sleep stage
for i = 1:3
    % calculate mean and var for all features
    m(:,i) = mean(s(labels==i,:));
    v(:,i) = var(s(labels==i,:));
end

% mixture means are just weighted combinations of state means
calibrationData = zeros(size(s, 2), 2);
calibrationData(:,1) = m * weights';

% mixture variance is given by law of total variance
% sqrt to get the standard deviation
calibrationData(:,2) = sqrt(v * weights' +...
    ((m - repmat(calibrationData(:,1),1,3)).^2) * weights');