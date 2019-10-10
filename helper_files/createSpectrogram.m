% zeke barger
% 070419
% create a multi-taper spectrogram of EEG data
% s is the spectrogram, t is the time axis, f is the frequency axis

function [s, t, f] = createSpectrogram(EEG, SR, winstep)
window = max([5, winstep]);

params = struct;
params.pad = -1;
params.Fs = SR;
params.fpass = [0 64];
params.tapers = [3 5];
% make sure EEG is a row
if ~isrow(EEG)
    EEG = EEG';
end

% truncate EEG to a multiple of SR*winstep
EEG = EEG(1:(length(EEG)-mod(length(EEG), SR*winstep)));

% pad the EEG signal so that the first bin starts at time 0
EEG = [EEG(1:round(SR*(window-winstep)/2)), EEG, EEG((end+1-round(SR*(window-winstep)/2)):end)];
[s, t, f] = mtspecgramc(EEG, [window, winstep], params);
% adjust time axis to reflect this change
t = t - (window-winstep)/2;

% if the window is larger than 5, downsample along the frequency axis
if window > 5
    fTarget = 0:.2:64; % specify desired frequency axis
    fIdx = zeros(1,length(fTarget)); % find closest indices in f
    for i = 1:length(fTarget)
        [~, fIdx(i)] = min(abs(f-fTarget(i)));
    end
    f = fTarget;
    s = s(:,fIdx);
end
