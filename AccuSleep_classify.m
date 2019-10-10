function [labels] = AccuSleep_classify(EEG, EMG, net, SR, epochLen, calibrationData, minBoutLen)
% AccuSleep_classify  Classify brain states
% Zeke Barger 062519
%
%   Arguments: (note that these are data, not paths to files)
%   EEG - a 1-D matrix of EEG data
%   EMG - a 1-D matrix of EMG data
%   net - a trained network. To create one, use AccuSleep_train
%   SR - sampling rate (Hz)
%   epochLen - length of each epoch (sec). THIS MUST MATCH THE EPOCH LENGTH
%              THAT WAS USED WHEN TRAINING THE NETWORK
%   calibrationData - matrix specifying how to scale features of the
%       EEG/EMG. It is recommended to create one of these for each
%       combination of mouse and recording equipment. This is the output of
%       createCalibrationData.m
%   minBoutLen (optional) - minimum length (sec) of a bout of any brain state

if nargin < 7
   minBoutLen = 0; 
end

if length(EEG) ~= length(EMG)
    disp('ERROR: EEG and EMG are different lengths')
    labels = [];
    return
end

% create the spectrogram
[s, ~, f] = createSpectrogram(EEG, SR, epochLen);
% select frequencies up to 50 Hz, and downsample between 20 and 50 Hz
[~,f20idx] = min(abs(f - 20)); % index in f of 20Hz
[~,f50idx] = min(abs(f - 50)); % index in f of 50Hz
s = s(:, [1:(f20idx-1), f20idx:2:f50idx]);
% if the spectrogram isn't the same height as the network, that's a problem
if size(s,2) ~= (net.Layers(1,1).InputSize(2) - 9)
   disp('Error: frequency axes for network and data do not match')
   labels = [];
   return
end

% take log of the spectrogram
s = log(s);
% calculate log rms for each EMG bin
processedEMG = processEMG(EMG, SR, epochLen);

% scale the spectrogram
for j = 1:size(s,2)
    s(:,j) = (s(:,j) - calibrationData(j,1)) ./ calibrationData(j,2);
    s(:,j) = (s(:,j) + 4.5)./9; % clip z scores
end
% scale the EMG
processedEMG = (processedEMG - calibrationData(end,1)) ./ calibrationData(end,2);
processedEMG = (processedEMG + 4.5)./9;

% clip them
processedEMG(processedEMG < 0)=0;
processedEMG(processedEMG > 1)=1;
s(s < 0)=0;
s(s > 1)=1;

% find how much time on either side of central timepoint to include
% this is based on the size of the trained network.
pad = round((net.Layers(1,1).InputSize(1) - 1)/2);

% pad the spectrogram and emg
s = [repmat(s(1,:), pad, 1); s; repmat(s(end,:), pad, 1)];
processedEMG = [repmat(processedEMG(1), 1, pad), processedEMG, repmat(processedEMG(end), 1, pad)];

% preallocate the image stack
X = zeros((pad*2+1),net.Layers(1,1).InputSize(2),1,length(processedEMG)-pad*2);

% create an image for each time step
for i = (pad+1):(length(processedEMG)-pad)
    X(:,:,1,(i-pad)) = [s((i-pad):(i+pad),:), repmat(processedEMG((i-pad):(i+pad))',1,9)];
end

% classify
X = uint8(X.*255);
labels = double(classify(net,X))';

% remove bouts that are too short
if minBoutLen > epochLen
    labels = enforceMinDuration(labels, ones(1,3) * ceil(minBoutLen / epochLen), [2 1 3], 0);
end