function [processedEMG] = processEMG(EMG, SR, epochLen)
% processEMG  Compute the RMS in each epoch of the EMG signal
% Zeke Barger 100119
%
%   Arguments:
%   EMG - a 1-D matrix of EMG data
%   SR - sampling rate, in Hz
%   epochLen - length of each epoch, in seconds
%
%   Output:
%   processedEMG - the processed EMG signal

% filter the EMG between 20 and 50 Hz
d = designfilt('bandpassfir','DesignMethod','kaiserwin','PassbandFrequency1',...
    20, 'PassbandFrequency2', 50, 'PassbandRipple',0.1, 'SampleRate', SR, ...
    'StopbandAttenuation1',60,'StopbandAttenuation2',60,...
    'StopbandFrequency1',16.86, 'StopbandFrequency2',52.198);
EMG = filtfilt(d, EMG);

% truncate EMG to a multiple of SR
samplesPerEpoch = SR*epochLen;
EMG = EMG(1:(length(EMG)-mod(length(EMG), samplesPerEpoch)));

% calculate log(rms) in each time window
% we can do this faster if the number of samples per epoch is an integer
if samplesPerEpoch == floor(samplesPerEpoch)
    processedEMG = log(rms(reshape(EMG,samplesPerEpoch,length(EMG)/samplesPerEpoch)));
else
    processedEMG = zeros(1,floor(length(EMG)/samplesPerEpoch));
    for i = 1:length(processedEMG)
        processedEMG(i)=log(rms(EMG(floor((i-1)*samplesPerEpoch + 1):floor(i*samplesPerEpoch))));
    end
end