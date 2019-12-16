function [message] = AccuSleep_viewer(EEG, EMG, SR, epochLen, userLabels, savepath)
%AccuSleep_viewer A GUI for manually assigning sleep stage labels to EEG/EMG data.
%   Zeke Barger 103019
%   Arguments:
%   EEG: the EEG signal as a vector
%   EMG: the EMG signal as a vector
%   SR: the sampling rate for the EEG and EMG in Hz
%   epochLen: the desired epoch length for sleep stage labels, in seconds.
%             Values below 2.5 are not supported, and values above 5 are not
%             recommended.
%   labels (optional): a vector of sleep stage labels. The length
%             must match the number of epochs in the EEG/EMG signal.
%             1 = REM, 2 = wake, 3 = NREM, 4 = undefined
%   savepath (optional): a filename for saving the sleep stage labels.
%             AccuSleep_GUI uses this argument, but if you are calling this
%             function yourself, you can probably ignore it.
%
%   Press the 'help' button for the user manual / keyboard shortcuts
%
%   Sleep stage labels will be saved to .mat files. The filename can be
%   anything, but the labels will be stored in a variable called 'labels'
%
%   Likewise, labels can be loaded from a .mat file as long as it contains
%   a variable called 'labels' that is a vector with the same number of
%   epochs as the EEG/EMG signals and values ranging from 1 to 4.

%% Check the inputs
G = struct; % holds everything

% make sure we have at least 3 arguments
switch nargin
    case {0,1,2,3}
        disp('Not enough arguments')
        message = 'ERROR: Not enough arguments';
        return
    case 4
        G.labels = [];
    case {5,6}
        if ~isempty(userLabels) % user tried to pass some labels
            % check whether they have the correct format
            q = struct;
            q.labels = userLabels;
            if checkLabels(q, 0) % meets certain conditions
                G.labels = q.labels;
                if isrow(G.labels)
                    G.labels = G.labels';
                end
            else
                message = 'ERROR: Labels file is incorrectly formatted';
                return
            end
        else
            G.labels = [];
        end
end

G.originalSR = SR; % EEG/EMG sampling rate
G.SR = 128; % sampling rate used when calculating spectrogram and processed EMG
G.epochLen  = epochLen; % length of one epoch (spectrogram column) in seconds

if length(EEG) ~= length(EMG)
    message = 'ERROR: EEG and EMG are different lengths';
    return
end

G.EEG = EEG - mean(EEG);
G.EMG = EMG - mean(EMG);
clear('EMG','EEG');

% create spectrogram and process EMG at a standard SR (128)
[spec, tAxis, fAxis] = createSpectrogram(standardizeSR(G.EEG, G.originalSR, G.SR), G.SR, G.epochLen);
G.processedEMG = processEMG(standardizeSR(G.EMG, G.originalSR, G.SR), G.SR, G.epochLen);
% set ceiling for EMG trace at 2.5 SD when plotting
G.cappedEMG = G.processedEMG;
emgCap = mean(G.cappedEMG) + 2.5*std(G.cappedEMG);
G.cappedEMG(G.cappedEMG > emgCap) = emgCap;

% set various parameters
G.show = 5; %  default number of bins to display on screen
G.dt = 1/G.originalSR; % duration of each EEG/EMG sample in seconds
G.advance = 0; % whether to advance automatically when a state is assigned
G.colors = [1 1 1; .47 .67 .19; .14 .2 .57; 0.996 0.758 0.039; 0 0 0]; %colors for sleep stages
G.mid = ceil(G.show/2); % important for plotting the current time marker - middle of G.show
G.savepath = ''; % where to save the sleep stage labels
G.nbins = length(tAxis); % total number of time bins in the recording
G.unsavedChanges = 0; % whether anything has changed since user last saved

% check to make sure labels has the proper length
if ~isempty(G.labels)
    if length(G.labels) ~= G.nbins
        disp(['length of labels must be ',num2str(G.nbins),' for this recording'])
        message = 'ERROR: Length of labels file does not match EEG/EMG. Check SR / epoch length?';
        return
    end
else % if no sleep stages provided, set to undefined
    G.labels = ones(G.nbins,1) * 4;
end

% get spectrogram and time axes
showFreqs = find(fAxis <= 30); % only show frequencies under 30 Hz
G.specTs = (1:G.nbins)*G.epochLen - G.epochLen/2; % spectrogram time axis, in seconds
G.specTh = G.specTs./3600; % spectrogram time axis, in hours
G.spectrogram = spec(:,showFreqs); % our EEG spectrogram
if nargin == 6 % this probably only happens when called by AccuSleep_GUI
    G.f = fAxis; % frequency axis
    G.s = spec;
    G.savepath = savepath;
end

% take a sample of the spectrogram to help initialize the colormap
sampleBins = randperm(G.nbins, round(G.nbins/10));
specSample = reshape(spec(sampleBins,showFreqs),1,length(sampleBins)*length(showFreqs));
G.caxis1 = prctile(specSample,[6 98]);
G.cmax = G.caxis1(2);
clear spec

% figure out how to scale eeg and emg visually
G.eegLen = length(G.EEG); % length of our recording, in samples
yl = prctile(abs(G.EEG(1:10:end)),95);
G.eegYlim = [-2.2*yl, 2.2*yl];
G.emgYlim = G.eegYlim;

% load our colormap
try
    G.colormap = AccuSleep_colormap();
catch
    try
        G.colormap = parula;
    catch
        G.colormap = jet;
    end
end



%% Make the figure window

WIN = figure('Units', 'Normalized', 'CloseRequestFcn',@closeReq,...
    'Position', [0.08, 0.12, 0.83, 0.75],'KeyPressFcn',@keypress,...
    'Menubar', 'none','Color', 'w', 'Name', 'AccuSleep_viewer');

% create axes
% panel divider and y labels
G.A5 = axes('Units', 'Normalized', 'Position', [0 .579 .05 .02],'XColor','w','YColor','w');
hold(G.A5,'on');
plot(G.A5,[0 10000],[0 0],'k','LineWidth',2)
set(G.A5,'Box','off','XLim',[0 1],'YLim',[0 0.1],'XTick',[],'YTick',[],'Clipping','off')
G.A5.Toolbar.Visible = 'off';
% Upper sleep stage labels
G.A1 = axes('Units', 'Normalized', 'Position', [0.05 0.915 0.87 0.08]);
G.A1.Toolbar.Visible = 'off';
% EEG spectrogram
G.A3 = axes('Units', 'Normalized', 'Position', [0.05 0.735 0.87 0.16]);
G.A3.Toolbar.Visible = 'off';
set(gca, 'FontSize', 10, 'LineWidth', 2, 'XTick', [], 'YTick', []);
% EMG signal
G.A6 = axes('Units', 'Normalized', 'Position', [0.05 0.21 0.87 .175]);
G.A6.Toolbar.Visible = 'off';
% EEG signal
G.A6a = axes('Units', 'Normalized', 'Position', [0.05 0.385 0.87 .175]);
G.A6a.Toolbar.Visible = 'off';
% Lower sleep stage labels
G.A7 = axes('Units', 'Normalized', 'Position', [0.05 0.01 0.87 0.16]);
G.A7.Toolbar.Visible = 'off';
% Time point indicator
G.A2 = axes('Units', 'Normalized', 'Position', [0.05 0.895  0.87 0.02],'XTick',[],'YTick',[]);
G.A2.Toolbar.Visible = 'off';
% Processed emg
G.A4 = axes('Units', 'Normalized', 'Position', [0.05 0.58  0.87 0.12]);
G.A4.Toolbar.Visible = 'off';
axis(G.A4, 'off');

linkaxes([G.A1, G.A2, G.A3, G.A4], 'x'); % upper panel x axes should stay linked

% buttons
G.helpbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized','BackgroundColor',[1 .8 .8],...
    'Position',[.93 .94 .062 .055],'String','Help','Callback',@showHelp,'FontSize',9,...
    'ToolTip','Show help menu (H)');
G.savebtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized','BackgroundColor',[.8 1 .8],...
    'Position',[.93 .885 .062 .045],'String','Save labels','Callback',@saveCallback,'FontSize',9,...
    'ToolTip','Save labels to file (F)');
G.loadbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .845 .062 .03],'String','Load labels','Callback',@loadFile,'FontSize',9,...
    'ToolTip','Load labels from file');
G.brightbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .8 .062 .025],'String','Brighter','Callback',@brightSpect,...
    'FontSize',9,'ToolTip','Make EEG spectrogram brighter');
G.dimbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .77 .062 .025],'String','Dimmer','Callback',@dimSpect,...
    'FontSize',9,'ToolTip','Make EEG spectrogram dimmer');
G.selectbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .705 .062 .04],'String','<html>Select<br>timepoint',...
    'Callback',@fct_selectlocation,'FontSize',9,'ToolTip','Click a timepoint to show (A)');
G.zoominbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .66 .062 .025],'String','Zoom IN','Callback',@fct_zoomin_t,...
    'FontSize',9,'ToolTip','Increase zoom level (+)');
G.zoomoutbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .63 .062 .025],'String','Zoom OUT','Callback',@fct_zoomout_t,...
    'FontSize',9,'ToolTip','Decrease zoom level (-)');
G.zoomresetbtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .595 .062 .025],'String','Reset zoom','Callback',@fct_zoomreset_t,...
    'FontSize',9,'ToolTip','Reset zoom level (0)');
G.gui_zoominEEG = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[0.93 0.505 0.02 0.02],'Callback', @fct_zoominEEG,'String','+',...
    'FontSize',9);
G.gui_zoomoutEEG = uicontrol(WIN,'Style','pushbutton','Units','normalized',...
    'Position',[0.93 0.475 0.02 0.02],'Callback', @fct_zoomoutEEG,'String','-',...
    'FontSize',9);
G.gui_shiftupEEG = uicontrol(WIN,'Style','pushbutton','Units','normalized',...
    'Position',[0.96 0.475 0.02 0.02],'Callback', @fct_shiftupEEG,'String','\/',...
    'FontSize',9);
G.gui_shiftdownEEG = uicontrol(WIN,'Style','pushbutton','Units','normalized',...
    'Position',[0.96 0.505 0.02 0.02],'Callback', @fct_shiftdownEEG,'String','/\',...
    'FontSize',9);
G.gui_zoominEMG = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[0.93 0.28 0.02 0.02],'Callback', @fct_zoominEMG,'String','+',...
    'FontSize',9);
G.gui_zoomoutEMG = uicontrol(WIN,'Style','pushbutton','Units','normalized',...
    'Position',[0.93 0.25 0.02 0.02],'Callback', @fct_zoomoutEMG,'String','-',...
    'FontSize',9);
G.gui_shiftupEMG = uicontrol(WIN,'Style','pushbutton','Units','normalized',...
    'Position',[0.96 0.25 0.02 0.02],'Callback', @fct_shiftupEMG,'String','\/',...
    'FontSize',9);
G.gui_shiftdownEMG = uicontrol(WIN,'Style','pushbutton','Units','normalized',...
    'Position',[0.96 0.28 0.02 0.02],'Callback', @fct_shiftdownEMG,'String','/\',...
    'FontSize',9);
G.showMenu = uicontrol(WIN,'Style','popupmenu','Units','normalized',...
    'Position',[0.93 0.54 0.062 0.02],'Callback', @fct_showmenu,...
    'String',{'Show 1 epoch','Show 3 epochs','Show 5 epochs','Show 7 epochs','Show 9 epochs'},...
    'Value',3);
G.rangebtn = uicontrol(WIN,'Style','pushbutton','Units','normalized','BackgroundColor',[.92 .92 .92],...
    'Position',[.93 .16 .062 .025],'String','set range','Callback',@setRange,...
    'FontSize',9,'ToolTip',sprintf(['Set state for range of timepoints (*)',...
    '\nDraw an ROI on the upper sleep stage panel,\nand double-click it']));
G.nrembtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .13 .062 .025],'String','NREM','Callback',@(src,evnt)setState(src,evnt,3),...
    'FontSize',9,'ToolTip','Set state to NREM (S)','BackgroundColor',[1 .96 .82]); %.8 .8 .8
G.wakebtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .1 .062 .025],'String','Wake','Callback',@(src,evnt)setState(src,evnt,2),...
    'FontSize',9,'ToolTip','Set state to wake (W)','BackgroundColor',[.86 .88 1]); % .93 .5 .93
G.rembtn = uicontrol(WIN,'Style','pushbutton', 'Units','normalized',...
    'Position',[.93 .07 .062 .025],'String','REM','Callback',@(src,evnt)setState(src,evnt,1),...
    'FontSize',9,'ToolTip','Set state to REM (R)','BackgroundColor',[.84 .92 .73]); % .5 1 1
G.autobox = uicontrol(WIN,'Style','checkbox', 'Units','normalized',...
    'Position',[.93 .005 .062 .06],'String','<html>Auto-<br>scroll','Callback',@scrollCallback,...
    'FontSize',9,'ToolTip','Advance to next time step after assigning label (insert)');

% axis labels
text(G.A5,0.05,1.87,'State')
text(G.A5,0.05,1.15,'EEG')
text(G.A5,0.05,.72,'Time (hr)')
text(G.A5,0.05,.33,'EMG')
text(G.A5,0.05,-.59,'EEG')
text(G.A5,0.05,-1.33,'EMG')
text(G.A5,0.05,-2.38,'State')

% keep track of the current timepoint
G.index = 1; % index of current time point
G.timepointS = G.specTs(G.index); % current time point, in seconds
G.timepointH = G.specTh(G.index); % current time point, in hours

% plot spectrogram
caxis(G.A3,G.caxis1);
imagesc(G.A3,G.specTh, fAxis(showFreqs), G.spectrogram',G.caxis1);
axis(G.A3, 'xy')
colormap(G.A3,G.colormap);
G.lims = xlim(G.A3); % store maximum x limits for the upper panel plots

% plot processed EMG
plot(G.A4,G.specTh,G.cappedEMG,'k')
yr = max(G.cappedEMG) - min(G.cappedEMG); % adjust y limits
set(G.A4,'XTick',[],'YTick',[],'box','off',...
    'YLim',[min(G.cappedEMG) - .02*yr, max(G.cappedEMG) + .02*yr])

% Upper sleep stages
box(G.A1, 'on');
xlim(G.A1,[G.specTh(1)-G.epochLen/3600, G.specTh(end)-G.epochLen/3600]);
updateState;

% Plot everything else
updatePlots;
axes(G.A1);

message = 'Data loaded successfully';

%% Functions used by buttons, keypresses, etc.
    function updatePlots(~, ~) % update plots when something changes
        
        
        % plot sleep stage in the lower panel
        n = (G.show-1)/2; % number of bins on either side of center to show
        tp = G.timepointS; % time in seconds at the center of the screen
        gi = G.index; % index of bin in the center of the screen
        if G.index < G.mid
            gi = G.mid;
            tp = gi*G.epochLen-G.epochLen/2;
        end
        if G.nbins - G.index < (G.mid-1)
            gi = G.nbins-(G.mid-1);
            tp = gi*G.epochLen-G.epochLen/2;
        end
        
        seq=G.labels((1:G.show)+gi-G.mid+(G.mid-gi)*(gi<G.mid)-...
            (gi-G.nbins+(G.mid-1))*(gi>(G.nbins-(G.mid-1))));
        x = -n:n;
        
        cla(G.A7)
        hold(G.A7,'on')
        xlim(G.A7, [-n-0.5 n+0.5]);
        ylim(G.A7, [0.5 3.5]);
        set(G.A7, 'XLimMode','manual', 'YLimMode','manual');
        
        for i = 1:length(seq)
            if seq(i)==4
                pX = [x(i)-.5, x(i)+.5, x(i)+.5, x(i)-.5];
                pY = [3.5, 3.5, .5, .5];
                patch(G.A7,pX,pY,G.colors(seq(i)+1,:),'EdgeColor','none');
            else
                pX = [x(i)-.5, x(i)+.5, x(i)+.5, x(i)-.5];
                pY = [seq(i)+.5, seq(i)+.5, seq(i)-.5, seq(i)-.5];
                patch(G.A7,pX,pY,G.colors(seq(i)+1,:),'EdgeColor','none');
            end
        end
        
        set(G.A7, 'XTickLabel', [],'XTick',[], 'YTick', [1 2 3], 'YTickLabel', {'REM', 'Wake', 'NREM'});
        box(G.A7, 'off');
        
        % plot EEG and EMG
        n = round((G.show*G.epochLen)/G.dt/2); % number of samples on either side to show
        i = round(tp / G.dt);
        ii = i-n:i+n; % choose indices to show
        t = tp-n*G.dt:G.dt:tp+n*G.dt;
        ii(ii<=0) = 1;
        ii(ii>=G.eegLen) = G.eegLen;
        
        cla(G.A6);
        hold(G.A6, 'on');
        xlim(G.A6,[t(1)-G.dt t(end)]);
        ylim(G.A6,G.emgYlim);
        set(G.A6, 'XLimMode','manual', 'YLimMode','manual');
        line(G.A6,t, G.EMG(ii), 'Color','k', 'LineWidth', 1); % plot EMG
        % plot indicator for current time bin
        line(G.A6,ones(1,2).*(G.timepointS-G.epochLen/2), [G.emgYlim(1),...
            G.emgYlim(1)+.1*diff(G.emgYlim)],'Color','r','LineWidth', .5);
        line(G.A6,ones(1,2).*(G.timepointS+G.epochLen/2), [G.emgYlim(1),...
            G.emgYlim(1)+.1*diff(G.emgYlim)],'Color','r', 'LineWidth', .5);
        line(G.A6,[G.timepointS-G.epochLen/2, G.timepointS+G.epochLen/2], [G.emgYlim(1) G.emgYlim(1)],...
            'Color','r', 'LineWidth', .5);
        
        
        cla(G.A6a)
        hold(G.A6a, 'on');
        xlim(G.A6a,[t(1)-G.dt t(end)]);
        ylim(G.A6a,G.eegYlim);
        set(G.A6a, 'XLimMode','manual', 'YLimMode','manual');
        line(G.A6a,t, G.EEG(ii), 'Color','k', 'LineWidth', 1); % plot eeg
        line(G.A6a,ones(1,2).*(G.timepointS-G.epochLen/2), [G.eegYlim(2),...
            G.eegYlim(2)-.1*diff(G.eegYlim)],'Color','r', 'LineWidth', .5);
        line(G.A6a,ones(1,2).*(G.timepointS+G.epochLen/2), [G.eegYlim(2),...
            G.eegYlim(2)-.1*diff(G.eegYlim)],'Color','r', 'LineWidth', .5);
        line(G.A6a,[G.timepointS-G.epochLen/2, G.timepointS+G.epochLen/2], [G.eegYlim(2) G.eegYlim(2)],...
            'Color','r', 'LineWidth', .5);
        set(G.A6a,'XTick',[],'YTick',[])
        
        % label x axis nicely
        G.A6.XTick = tp-(G.show/2)*G.epochLen + G.epochLen*(0:G.show);
        ticks = G.A6.XTick;
        xlbl = cell(1, length(ticks));
        for i = 1:length(ticks)
            xlbl{i} = sec2hr(ticks(i));
        end
        G.A6.XTickLabel = xlbl;
        set(G.A6, 'YTick', []);
        
        % Plot Progress Button
        tp = G.timepointH; % time in seconds at the center of the screen
        if G.index < G.mid
            tp = gi*G.epochLen/3600-G.epochLen/3600/2;
        end
        if G.nbins - G.index < (G.mid-1)
            tp = gi*G.epochLen/3600-G.epochLen/3600/2;
        end
        li = get(G.A2,'xlim');
        cla(G.A2);
        hold(G.A2,'on')
        xlim(G.A2,li);
        set(G.A2,'YTick',[],'XTick',[],'XLimMode','manual', 'YLimMode','manual');
        
        % unless we're at the beginning or end
        if G.index < G.mid  || G.nbins - G.index < (G.mid-1)
            plot(G.A2,G.timepointH, 0.5, 'rd', 'LineWidth', 3,'MarkerFaceColor','r');
            if G.index <= (G.mid-1)
                plot(G.A2,[0, G.epochLen/3600*G.show], [0.5,0.5], 'r','LineWidth',2);
            else
                plot(G.A2,[G.specTh(end-G.show)+G.epochLen/3600/2, G.specTh(end)+G.epochLen/3600/2],...
                    [0.5,0.5], 'r','LineWidth',2);
            end
        else
            plot(G.A2,G.timepointH, 0.5, 'rd', 'LineWidth', 3,'MarkerFaceColor','r');
            line(G.A2,[tp-G.epochLen/3600*(G.show/2),tp+G.epochLen/3600*(G.show/2)], [0.5,0.5],...
                'Color','r','LineWidth',2);
        end
        
        
        if tp<(li(1)+.35*diff(li)) && li(1) > G.lims(1) % we are far to the left
            xlim(G.A2,li - min([li(1)-G.lims(1), li(1)+.35*diff(li)-tp]))
        else
            if tp>(li(1)+.65*diff(li)) && li(2) < G.lims(2) % far to the right
                xlim(G.A2,li + min([G.lims(2)-li(2), tp-li(1)-.65*diff(li)]))
            end
        end
    end

    function updateState() % update the sleep stage image
        
        li=xlim(G.A1);
        cla(G.A1);
        hold(G.A1, 'on');
        box(G.A1,'on');
        ylim(G.A1,[0 1]);
        ylim(G.A1,[.5 3.5]);
        xlim(G.A1,li) % make sure x limits are correct
        set(G.A1,'XLimMode','manual','YLimMode','manual');
        imagesc(G.A1,G.specTh,[1 2 3],makeSleepStageImage(G.labels),[0 4]);
        colormap(G.A1,G.colors);
        set(G.A1, 'XTickLabel', [],'XTick',[], 'YTick', [1 2 3], 'YTickLabel', {'REM', 'Wake', 'NREM'});
    end

    function [im] = makeSleepStageImage(state) % create the image to show
        % in the top sleep stage panel
        im = zeros(3,length(state));
        for i = 1:3
            im(i,:) = (state==i).*i;
            im(i,state==4) = 4;
        end
    end

% Process keypresses
    function keypress(~, evt)
        
        switch evt.Key
            case {'rightarrow', 'uparrow'} % advance one time step
                if G.index < G.nbins
                    G.index = G.index + 1;
                    G.timepointS  = G.specTs(G.index);
                    G.timepointH  = G.specTh(G.index);
                    updatePlots;
                end
                
            case {'leftarrow', 'downarrow'} % move back one time step
                if G.index > 1
                    G.index = G.index - 1;
                    G.timepointS = G.specTs(G.index);
                    G.timepointH = G.specTh(G.index);
                    updatePlots;
                end
                
            case 'pageup' % jump to next bin with undefined state
                idx = find(G.labels==4);
                if ~isempty(idx) && any (idx > G.index)
                    idx = idx(idx>G.index);
                    G.index = idx(1);
                    G.timepointS = G.specTs(G.index);
                    G.timepointH = G.specTh(G.index);
                    updatePlots;
                end
                
            case 'pagedown' % jump to previous bin with undefined state
                idx = find(G.labels==4);
                if ~isempty(idx) && any (idx < G.index)
                    idx = idx(idx<G.index);
                    G.index = idx(end);
                    G.timepointS = G.specTs(G.index);
                    G.timepointH = G.specTh(G.index);
                    updatePlots;
                end
                
            case 'space' % jump to next bin with different state than current bin
                idx = find(G.labels~=G.labels(G.index));
                if ~isempty(idx) && any (idx > G.index)
                    idx = idx(idx>G.index);
                    G.index = idx(1);
                    G.timepointS = G.specTs(G.index);
                    G.timepointH = G.specTh(G.index);
                    updatePlots;
                end
                
            case 'insert' % toggle auto-scroll mode
                G.advance = ~G.advance;
                set(G.autobox,'Value',G.advance);
                
            case 'a' % jump to point on spectrogram
                axes(G.A1);
                [x, ~] = ginput(1);
                [G.timepointH, G.index] = findTime(G.specTh, x);
                G.timepointS = G.specTs(G.index);
                updatePlots;
                
            case 'add' % zoom in
                axes(G.A3);
                curlims = xlim;
                xlim([max(curlims(1), G.timepointH-.45*diff(curlims)) min(curlims(2),...
                    G.timepointH+.45*diff(curlims))]);
                
            case 'subtract' % zoom out
                axes(G.A3);
                curlims = xlim;
                xlim([max(G.lims(1), G.timepointH-1.017*diff(curlims)) min(G.lims(2),...
                    G.timepointH+1.017*diff(curlims))]);
                
            case 'numpad0' % reset zoom level
                axes(G.A3);
                xlim(G.lims);
                
            case {'r','1','numpad1'} % set to REM
                G.labels(G.index) = 1;
                G.unsavedChanges = 1;
                updateState;
                updatePlots;
                advance;
                
            case {'w','2','numpad2'} % set to wake
                G.labels(G.index) = 2;
                G.unsavedChanges = 1;
                updateState;
                updatePlots;
                advance;
                
            case {'s','3','numpad3'} % set to NREM
                G.labels(G.index) = 3;
                G.unsavedChanges = 1;
                updateState;
                updatePlots;
                advance;
                
            case {'x','4','numpad4'} % set to undefined
                G.labels(G.index) = 4;
                G.unsavedChanges = 1;
                updateState;
                updatePlots;
                advance;
                
            case 'f' % save file
                saveFile();
                
            case 'h' % show help menu
                showHelp(G.A1, []);
                
            case 'multiply' % apply label to range of timepoints
                t = text(G.A5,18.75,-.9,sprintf(['Move the ROI\n',...
                    'boundaries,\nand then\ndouble-click it',...
                    '\nor press\nescape']),'Color','r');
                axes(G.A1);
                set(G.A1,'Clipping','off')
                xl = xlim(G.A1);
                d = diff(xl);
                roi = imrect(G.A1,[xl(1)+d/2 - d/24,-4.0287,d/12,4.9080]);
                rectPosition = round(wait(roi)./(G.epochLen/3600));
                roi.delete();
                set(G.A1,'Clipping','on')
                if isempty(rectPosition)
                    delete(t);
                    return
                end
                
                [label,~] = listdlg('PromptString','Set label to:',...
                    'SelectionMode','single',...
                    'ListString',{'REM', 'Wake','NREM','Undefined'});
                if isempty(label) % no label selected
                    delete(t);
                    return
                end
                
                idx1 = max([1,rectPosition(1)]); % starting index
                idx2 = min([G.nbins,rectPosition(1)+rectPosition(3)]); % ending index
                G.labels(idx1 : idx2) = label;
                G.unsavedChanges = 1;
                delete(t); % remove helper text
                updatePlots; % update plots
                updateState;
        end
    end

% functions called by button presses
    function brightSpect(src,~)
        
        G.cmax = G.cmax - G.cmax/10;
        G.caxis1 = [G.caxis1(1), G.cmax];
        caxis(G.A3,G.caxis1)
        updatePlots;
        defocus(src);
    end

    function dimSpect(src,~)
        
        G.cmax = G.cmax + G.cmax/10;
        G.caxis1 = [G.caxis1(1), G.cmax];
        caxis(G.A3,G.caxis1)
        updatePlots;
        defocus(src);
    end

    function setState(src,~, a) % apply label to single time bin
        evt= struct;
        keys = {'r','w','s'};
        evt.Key = keys{a};
        keypress([], evt);
        defocus(src);
    end

    function setRange(src, ~) % apply label to range of time bins
        evt= struct;
        evt.Key = 'multiply';
        keypress([], evt);
        defocus(src);
    end

    function fct_showmenu(src, ~)
        
        options = 1:2:9;
        G.show = options(src.Value);
        G.mid = ceil(G.show/2);
        updatePlots;
        defocus(src);
    end

    function fct_shiftupEEG(src,~)
        
        G.eegYlim = [G.eegYlim(1)+.04*diff(G.eegYlim), G.eegYlim(2)+.04*diff(G.eegYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_shiftdownEEG(src,~)
        
        G.eegYlim = [G.eegYlim(1)-.04*diff(G.eegYlim), G.eegYlim(2)-.04*diff(G.eegYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_shiftupEMG(src,~)
        
        G.emgYlim = [G.emgYlim(1)+.04*diff(G.emgYlim), G.emgYlim(2)+.04*diff(G.emgYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_shiftdownEMG(src,~)
        
        G.emgYlim = [G.emgYlim(1)-.04*diff(G.emgYlim), G.emgYlim(2)-.04*diff(G.emgYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_selectlocation(src,~)
        evt= struct;
        evt.Key = 'a';
        keypress([], evt);
        defocus(src);
    end

    function fct_zoomin_t(src,~)
        
        axes(G.A3);
        curlims = xlim;
        xlim([max(curlims(1), G.timepointH-.45*diff(curlims)) min(curlims(2), G.timepointH+.45*diff(curlims))]);
        defocus(src);
    end

    function fct_zoomout_t(src,~)
        
        axes(G.A3);
        curlims = xlim;
        xlim([max(G.lims(1), G.timepointH-1.02*diff(curlims)) min(G.lims(2), G.timepointH+1.02*diff(curlims))]);
        defocus(src);
    end

    function fct_zoominEEG(src,~)
        
        G.eegYlim = [G.eegYlim(1)+.05*diff(G.eegYlim), G.eegYlim(2)-.05*diff(G.eegYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_zoomoutEEG(src,~)
        
        G.eegYlim = [G.eegYlim(1)-.05*diff(G.eegYlim), G.eegYlim(2)+.05*diff(G.eegYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_zoominEMG(src,~)
        
        G.emgYlim = [G.emgYlim(1)+.05*diff(G.emgYlim), G.emgYlim(2)-.05*diff(G.emgYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_zoomoutEMG(src,~)
        
        G.emgYlim = [G.emgYlim(1)-.05*diff(G.emgYlim), G.emgYlim(2)+.05*diff(G.emgYlim)];
        updatePlots;
        defocus(src);
    end

    function fct_zoomreset_t(src,~) % reset zoom level
        
        axes(G.A3);
        xlim(G.lims);
        defocus(src);
    end

    function scrollCallback(a,~) % respond to user input in the auto-scroll box
        
        G.advance = a.Value;
        defocus(a);
    end

    function showHelp(src,~) % show help menu
        createmode = struct;
        createmode.WindowStyle = 'non-modal';
        createmode.Interpreter = 'tex';
        msgbox({'\fontsize{13}\fontname{Courier New}User manual:';
            'After closing this window, click inside the figure to resume.';
            'The lower panels are a zoomed-in subset of data in the upper panels.';
            'The red diamond on top of the EEG shows the current time point,';
            'and the red lines extending on either side mark the subset shown ';
            'in the lower panels.';
            ' ';
            'Keyboard shortcuts:';
            'Up/right arrow : scroll one time step forward';
            'Down/left arrow : scroll one time step backward';
            'A : choose time point: click to jump to a location';
            '+/- : zoom in/out';
            '0 (zero) : reset zoom';
            'F : save sleep stage labels - see code for details';
            'pg up/down : skip to next/previous undefined period';
            'space : skip to first bin with different state than current bin';
            'insert : toggle auto-scroll mode, which advances one time step';
            '         automatically after applying a label';
            'H : show help menu';
            ' ';
            'R or 1 : set label as REM (cyan)';
            'W or 2 : Wake (magenta)';
            'S or 3 : NREM (gray)';
            'X or 4 : Undefined (black)';
            '* (multiply) : set labels for a range of timepoints.';
            'On the upper sleep stage panel, adjust the ROI to';
            'select the timepoints, then double-click it.';
            'Then, choose the sleep stage from the menu.';
            }, createmode);
        defocus(src);
    end

    function saveCallback(src,~)
        saveFile();
        defocus(src);
    end

    function loadFile(src,~) % load sleep stage labels from file
        
        [file,path] = uigetfile('*.mat');
        if ~ischar(file)
            msgbox('No file specified, file not loaded')
            return
        end
        f = load([path,file]); % load the file
        if checkLabels(f,1) % make sure file has the correct contents
            G.labels = f.labels; % use these labels
            G.savepath = ''; % clear the save path to avoid confusion
            updateState; % plot the new labels
        end
        defocus(src);
    end

    function defocus(src) % remove focus from a clicked button so that keypresses work again
        set(src, 'Enable', 'off');
        drawnow;
        set(src, 'Enable', 'on');
    end

% other functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function saveFile()
        
        if isempty(G.savepath) % get file path if we need it
            [file,path] = uiputfile('*.mat');
            if ~ischar(file) % if no file given
                msgbox('No file specified, file not saved')
                return
            end
            G.savepath = [path,file]; % store this filename
        end
        labels = G.labels; % store sleep stage labels in a variable called 'labels'
        save(G.savepath, 'labels'); % write labels to file
        G.unsavedChanges = 0;
    end

% check if a structure x has a properly constructed labels field
    function [allChecksPassed] = checkLabels(x, checkLen)
        allChecksPassed = 0;
        if ~isfield(x, 'labels') % needs a labels variable
            msgbox('Error: file does not contain a variable called labels')
            return
        end
        if ~isa(x.labels,'numeric') % labels are numeric
            msgbox('Error: labels variable must be numeric')
            return
        end
        if ~isempty(setdiff(unique(x.labels), 1:4)) % in the range 1:4
            msgbox('Error: labels variable must be in the range 1:4')
            return
        end
        if length(size(x.labels)) > 2 || min(size(x.labels)) >  1 % should be a vector
            msgbox('Error: labels variable must be a vector')
            return
        end
        if checkLen
            
            if length(x.labels) ~= G.nbins % in the range 1:4
                msgbox(['Error: labels must be of length ',num2str(G.nbins)])
                return
            end
        end
        if isrow(x.labels) % ensure that it's a column
            x.labels = x.labels';
        end
        allChecksPassed = 1;
    end

    function [timeString] = sec2hr(s) % convert seconds into hr:mn:sec.abcd
        m = floor(s/60);
        s2 = mod(s,60);
        h = floor(m/60);
        m2 = mod(m,60);
        timeString = sprintf('%02d:%02d:%05.2f',h,m2,s2);
    end

    function [t, index] = findTime(time, x) % find closest value of time to x
        [~, index] = min(abs(time - x));
        t = time(index);
    end

    function advance() % if auto-scrolling is on, advance to the next time bin
        if G.advance
            if G.index < G.nbins
                G.index = G.index + 1;
                G.timepointS  = G.specTs(G.index);
                G.timepointH  = G.specTh(G.index);
                if G.index < G.nbins-1 && G.index > 2
                    updatePlots;
                end
            end
        end
    end

    function closeReq(~,~) %
        if G.unsavedChanges
            answer = questdlg('There are unsaved changes. Really quit?', ...
                'Unsaved changes', ...
                'Quit','Cancel','Cancel');
            if ~strcmp(answer,'Quit')
                return
            end
        end
        delete(gcf)
    end

end
