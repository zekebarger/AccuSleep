function varargout = AccuSleep_GUI(varargin)
% AccuSleep_GUI A GUI for classifying rodent sleep stages
% Zeke Barger 100119
% To see the user manual, run this code and press the Help button, or run:
% doc AccuSleep_instructions


% Begin initialization code - do not edit
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @AccuSleep_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @AccuSleep_GUI_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code


% --- Executes just before AccuSleep_GUI is made visible.
function AccuSleep_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for AccuSleep_GUI
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% console text
setappdata(handles.console,'text',{});
setappdata(handles.console,'line',1);
% store some data in the button object
% EEG data
setappdata(handles.runBtn,'EEG',[]);
setappdata(handles.runBtn,'EEGlen',[]);
% EMG data
setappdata(handles.runBtn,'EMG',[]);
setappdata(handles.runBtn,'EMGlen',[]);
% calibration data
setappdata(handles.runBtn,'calibrationData',[]);
% trained network
setappdata(handles.runBtn,'net',[]);
% indicator handles
allIndicators = {[handles.eeg1, handles.eeg2, handles.eeg3, handles.eeg4],...
    [handles.emg1, handles.emg2, handles.emg3, handles.emg4],...
    [handles.output1, handles.output2, handles.output3, handles.output4],...
    [handles.sr1, handles.sr2, handles.sr3, handles.sr4],...
    [handles.ts1, handles.ts2, handles.ts3, handles.ts4],...
    [handles.calib1, handles.calib2],...
    [handles.net1, handles.net2]};
setappdata(handles.runBtn,'eegIndicators',allIndicators{1});
setappdata(handles.runBtn,'emgIndicators',allIndicators{2});
setappdata(handles.runBtn,'outputIndicators',allIndicators{3});
setappdata(handles.runBtn,'srIndicators',allIndicators{4});
setappdata(handles.runBtn,'tsIndicators',allIndicators{5});
setappdata(handles.runBtn,'calibIndicators',allIndicators{6});
setappdata(handles.runBtn,'netIndicators',allIndicators{7});
setappdata(handles.runBtn,'allIndicators',allIndicators);
for i = 1:length(allIndicators)
    setIndicator(allIndicators{i}, 'failure')
    for j = 1:length(allIndicators{i})
        %         set(allIndicators{i}(j),'BackgroundColor',[.93 .93 .93]);
        set(allIndicators{i}(j),'BackgroundColor',[1 1 1]);
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = AccuSleep_GUI_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;


function eegBtn_Callback(hObject, eventdata, handles) % loads EEG data
% choose default string
currentEEG = get(handles.eegTxt,'String');
currentEMG = get(handles.emgTxt,'String');
if isempty(currentEEG) && ~isempty(currentEMG)
    default = getDir(currentEMG);
else
    default = currentEEG;
end
[file,path] = uigetfile('*.mat','Select .mat file containing "EEG" variable',...
    default); % get user input
if ischar(file) % if something was selected
    disptext(handles, 'Loading EEG...');
    set(handles.eegTxt,'String','');
    setappdata(handles.runBtn,'EEG',[]);
    setIndicator(getappdata(handles.runBtn,'eegIndicators'), 'working')
    drawnow;
    d = load([path,file]); % load the data
    if isfield(d,'EEG')
        % check that it's the right shape
        if (length(size(d.EEG))>2 || min(size(d.EEG))>1) || (isempty(d.EEG) || ~isnumeric(d.EEG))
            disptext(handles, 'ERROR: EEG variable must be a numeric vector');
            setIndicator(getappdata(handles.runBtn,'eegIndicators'), 'failure')
            return
        end
        setappdata(handles.runBtn,'EEG',d.EEG); % store the data
        setappdata(handles.runBtn,'EEGlen',length(d.EEG));
        set(handles.eegTxt,'String',[path,file]); % store filename in the text box
        disptext(handles, 'EEG file selected');
        setIndicator(getappdata(handles.runBtn,'eegIndicators'), 'success')
        % check if EEG/EMG are the same length
        if ~isempty(get(handles.emgTxt,'String'))
            if getappdata(handles.runBtn,'EEGlen') ~= getappdata(handles.runBtn,'EMGlen')
                setIndicator([getappdata(handles.runBtn,'eegIndicators'),...
                    getappdata(handles.runBtn,'emgIndicators')], 'serious_warn')
                disptext(handles, 'WARNING: EEG and EMG are not currently the same length');
            else
                setIndicator([getappdata(handles.runBtn,'eegIndicators'),...
                    getappdata(handles.runBtn,'emgIndicators')], 'success')
            end
        end
    else
        disptext(handles, 'ERROR: File must contain a variable named EEG');
        setIndicator(getappdata(handles.runBtn,'eegIndicators'), 'failure')
    end
end


function emgBtn_Callback(hObject, eventdata, handles) % loads EMG data
currentEEG = get(handles.eegTxt,'String');
currentEMG = get(handles.emgTxt,'String');
if isempty(currentEMG) && ~isempty(currentEEG)
    default = getDir(currentEEG);
else
    default = currentEMG;
end
[file,path] = uigetfile('*.mat','Select .mat file containing "EMG" variable',...
    default);
if ischar(file)
    disptext(handles, 'Loading EMG...');
    set(handles.emgTxt,'String','');
    setappdata(handles.runBtn,'EMG',[]);
    setIndicator(getappdata(handles.runBtn,'emgIndicators'), 'working')
    drawnow;
    d = load([path,file]);
    if isfield(d,'EMG')
        if (length(size(d.EMG))>2 || min(size(d.EMG))>1) || (isempty(d.EMG) || ~isnumeric(d.EMG))
            disptext(handles, 'ERROR: EMG variable must be a numeric vector');
            setIndicator(getappdata(handles.runBtn,'emgIndicators'), 'failure')
            return
        end
        setappdata(handles.runBtn,'EMG',d.EMG);
        setappdata(handles.runBtn,'EMGlen',length(d.EMG));
        set(handles.emgTxt,'String',[path,file]);
        disptext(handles, 'EMG file selected');
        setIndicator(getappdata(handles.runBtn,'emgIndicators'), 'success')
        if ~isempty(get(handles.eegTxt,'String'))
            if getappdata(handles.runBtn,'EEGlen') ~= getappdata(handles.runBtn,'EMGlen')
                setIndicator([getappdata(handles.runBtn,'eegIndicators'),...
                    getappdata(handles.runBtn,'emgIndicators')], 'serious_warn')
                disptext(handles, 'WARNING: EEG and EMG are not currently the same length');
            else
                setIndicator([getappdata(handles.runBtn,'eegIndicators'),...
                    getappdata(handles.runBtn,'emgIndicators')], 'success')
            end
        end
    else
        disptext(handles, 'ERROR: File must contain a variable named EMG');
        setIndicator(getappdata(handles.runBtn,'emgIndicators'), 'failure')
    end
end

function outputBtn_Callback(hObject, eventdata, handles) % sets location of output file
if ~isempty(get(handles.outputTxt,'String'))
    default = getDir(get(handles.outputTxt,'String'));
else
    if ~isempty(get(handles.eegTxt,'String'))
        default = getDir(get(handles.eegTxt,'String'));
    else
        if ~isempty(get(handles.emgTxt,'String'))
            default = getDir(get(handles.emgTxt,'String'));
        else
            default='';
        end
    end
end

[file,path] = uiputfile('*.mat',...
    'Enter new filename for saving sleep stage labels, or select existing file',...
    default); % get user input
if ischar(file) % user gave some input
    set(handles.outputTxt,'String',[path,file]); % store the input
    % set all indicators except for creating a calibrationData file to green
    ind = getappdata(handles.runBtn,'outputIndicators');
    setIndicator(ind([1,2,4]), 'success')
    setIndicator(ind(3), 'unknown')
    % try to load the file
    if isfile(get(handles.outputTxt,'String')) % if the file exists
        d = load(get(handles.outputTxt,'String')); % load it
        if isfield(d,'labels') % if it has a field called labels
            disptext(handles,'Label file found');
        else
            if isempty(fieldnames(d)) % if file is just empty
                disptext(handles, 'Name for label file has been set');
            else % file has some other contents that could be overwritten
                setIndicator(getappdata(handles.runBtn,'outputIndicators'),'serious_warn');
                disptext(handles,...
                    'WARNING: label file has other (non-label) contents that will be overwritten.');
                disptext(handles,...
                    '         See the user manual for instructions on formatting the label file.');
            end
        end
    else
        disptext(handles, 'Output filename set');
    end
end

% --- Executes on button press in manualBtn.
function manualBtn_Callback(hObject, eventdata, handles)
% make sure we have the files we need
if checkMissingEntries(handles, 0)
    return
end

% check if a label file already exists, and load those labels if possible
labels = [];
if isfile(get(handles.outputTxt,'String')) % if the file exists
    d = load(get(handles.outputTxt,'String')); % load it
    if isfield(d,'labels') % if it has a field called labels
        labels = d.labels; % use them
    end
end

disptext(handles, 'Working...');
drawnow;

% show success animation
ind = getappdata(handles.runBtn,'allIndicators');
codes=animateBoxes([ind{1}(2), ind{2}(2),ind{3}(2),ind{4}(2),ind{5}(2)], 1);

% launch AccuSleep_viewer to manually annotate the recording
message = AccuSleep_viewer(getappdata(handles.runBtn,'EEG'), getappdata(handles.runBtn,'EMG'),...
    str2num(get(handles.srBox,'String')),...
    str2num(get(handles.tsBox,'String')), labels, get(handles.outputTxt,'String'));
disptext(handles, message);

animateBoxes([ind{1}(2), ind{2}(2),ind{3}(2),ind{4}(2),ind{5}(2)], 2, codes);

function calibBtn_Callback(hObject, eventdata, handles) % sets calibration file path
[file,path] = uigetfile('*.mat','Select .mat file containing "calibrationData" variable',...
    get(handles.calibTxt,'String')); % get user input
if ischar(file)
    disptext(handles, 'Loading calibration file...');
    set(handles.calibTxt,'String','');
    setappdata(handles.runBtn,'calibrationData',[]);
    setIndicator(getappdata(handles.runBtn,'calibIndicators'), 'working')
    drawnow;
    d = load([path,file]);
    if isfield(d,'calibrationData')
        setappdata(handles.runBtn,'calibrationData',d.calibrationData);
        set(handles.calibTxt,'String',[path,file]);
        disptext(handles, 'Calibration file selected');
        setIndicator(getappdata(handles.runBtn,'calibIndicators'), 'success')
    else
        disptext(handles, 'ERROR: File must contain a variable named calibrationData');
        setIndicator(getappdata(handles.runBtn,'calibIndicators'), 'failure')
    end
end

function netFile_Callback(hObject, eventdata, handles) % sets network file path
[file,path] = uigetfile('*.mat','Select .mat file containing "net" variable (the trained network)',...
    get(handles.netTxt,'String')); % get user input
if ischar(file)
    disptext(handles, 'Loading trained network...');
    set(handles.netTxt,'String','');
    setappdata(handles.runBtn,'net',[]);
    setIndicator(getappdata(handles.runBtn,'netIndicators'), 'working')
    drawnow;
    d = load([path,file]);
    if isfield(d,'net')
        setappdata(handles.runBtn,'net',d.net);
        set(handles.netTxt,'String',[path,file]);
        disptext(handles, 'Trained network file selected');
        setIndicator(getappdata(handles.runBtn,'netIndicators'), 'success')
    else
        disptext(handles, 'ERROR: File must contain a variable named net');
        setIndicator(getappdata(handles.runBtn,'netIndicators'), 'failure')
    end
end

function createBtn_Callback(hObject, eventdata, handles) % creates a calibration data file
% make sure we have the files we need
if checkMissingEntries(handles, 0)
    return
end

% check if label file exists
if exist(get(handles.outputTxt,'String'))~=2
    animateBoxes(getappdata(handles.runBtn,'outputIndicators'),0);
    disptext(handles, 'ERROR: Sleep stage label file does not exist, see Section 4 of the user manual');
    return
end

% check if it has the correct contents
d = load(get(handles.outputTxt,'String')); % load label file
if isfield(d,'labels') % if it has a field called labels
    labels = d.labels; % get the labels
else
    animateBoxes(getappdata(handles.runBtn,'outputIndicators'),0);
    disptext(handles, 'ERROR: Sleep stage label file must have a variable called "labels"');
    return
end
% check if all labels are outside the range 1:3
if all(labels > 3 | labels < 1)
    animateBoxes(getappdata(handles.runBtn,'outputIndicators'),0);
    disptext(handles, 'ERROR: At least some labels must be in the range 1:3.');
    disptext(handles, '       See Section 4 of the user manual.');
    return
end
% check if there are at least a few labels for each state
if ~all([sum(labels==1)>=3, sum(labels==2)>=3, sum(labels==3)>=3])
    animateBoxes(getappdata(handles.runBtn,'outputIndicators'),0);
    disptext(handles, 'ERROR: At least some epochs of each stage must be labeled.');
    disptext(handles, '       Press the Help button for details.');
    return
end
% check if we have a reasonable number of labels
ts = str2num(get(handles.tsBox,'String')); % epoch length
if sum(labels <= 3 | labels >= 1) * ts / 60 < 10
    disptext(handles, 'WARNING: At least 10 minutes of labeled data are recommended for');
    disptext(handles, '         creating a calibration data file');
    disptext(handles, '         Press the Help button for details.');
end

EEG = getappdata(handles.runBtn,'EEG');
EMG = getappdata(handles.runBtn,'EMG');
if length(EEG) ~= length(EMG)
    animateBoxes([getappdata(handles.runBtn,'eegIndicators'),...
        getappdata(handles.runBtn,'eegIndicators')],0);
    disptext(handles, 'ERROR: EEG and EMG must be the same length');
    return
end

% show progress animation
ind = getappdata(handles.runBtn,'allIndicators');
codes = animateBoxes([ind{1}(3), ind{2}(3),ind{3}(3),ind{4}(3),ind{5}(3)], 1);
disptext(handles, 'Working...');
drawnow;

% create calibrationData
oldSR = str2num(get(handles.srBox,'String'));
calibrationData = createCalibrationData(standardizeSR(EEG, oldSR, 128),...
    standardizeSR(EMG, oldSR, 128),...
    labels, 128, str2num(get(handles.tsBox,'String')));

% complete progress animation
animateBoxes([ind{1}(3), ind{2}(3),ind{3}(3),ind{4}(3),ind{5}(3)], 2, codes);

% check if it failed
if isempty(calibrationData)
    animateBoxes(getappdata(handles.runBtn,'outputIndicators'),0);
    disptext(handles, 'ERROR: Length of label file does not match length');
    disptext(handles, '       of EEG/EMG. Check the epoch size?');
    return
end

% ask for save location
[file,path] = uiputfile('*.mat','Set filename for calibration data file');
if ~ischar(file) % if no file given
    disptext(handles, 'ERROR: No filename chosen');
    return
end

% save file
save([path,file], 'calibrationData');
disptext(handles, 'Calibration file saved');

% store it
setappdata(handles.runBtn,'calibrationData', calibrationData);

% insert filename into text box
set(handles.calibTxt,'String', [path,file]);
setIndicator(getappdata(handles.runBtn,'calibIndicators'), 'success')


function runBtn_Callback(hObject, eventdata, handles) % classify sleep stages automatically
% check that all boxes are filled
if checkMissingEntries(handles, 1)
    return
end

disptext(handles, 'Working...');
drawnow;

% get minimum bout length
minBoutLen = str2num(get(handles.boutBox,'String'));
if isempty(minBoutLen)
    minBoutLen = 0;
end

% animate
ind = getappdata(handles.runBtn,'allIndicators');
codes = animateBoxes([ind{1}(4), ind{2}(4),ind{3}(4),ind{4}(4),ind{5}(4), ind{6}(2), ind{7}(2)], 1);

% run AccuSleep
oldSR = str2num(get(handles.srBox,'String'));
labels = AccuSleep_classify(standardizeSR(getappdata(handles.runBtn,'EEG'), oldSR, 128),...
    standardizeSR(getappdata(handles.runBtn,'EMG'), oldSR, 128),...
    getappdata(handles.runBtn,'net'),128, str2num(get(handles.tsBox,'String')),...
    getappdata(handles.runBtn,'calibrationData'), minBoutLen);
animateBoxes([ind{1}(4), ind{2}(4),ind{3}(4),ind{4}(4),ind{5}(4), ind{6}(2), ind{7}(2)], 2, codes);
if isempty(labels) % if something went wrong
    disptext(handles, 'ERROR: No file saved, see command window for details');
    animateBoxes([ind{1}(4), ind{2}(4),ind{3}(4),ind{4}(4),ind{5}(4), ind{6}(2), ind{7}(2)], 0);
    return
end

% save labels to file
% if we need to keep existing labels...
if ~get(handles.overwriteBox,'Value') && exist(get(handles.outputTxt,'String'), 'file')
    d = load(get(handles.outputTxt,'String')); % load the labels
    if isfield(d, 'labels')
        userLabels = d.labels;
        userLabels(userLabels < 1) = 0; % discard undefined states
        userLabels(userLabels > 3) = 0;
        if length(userLabels) ~= length(labels)
            % the labels exist, but are the wrong length. ask to proceed
            answer = questdlg('The length of the existing labels does not match the new labels.', ...
                'Problem with label length', ...
                'Replace old labels','Cancel','Cancel');
            if strcmp(answer,'Cancel')
                return
            end
        else
            % take existing labels
            labels(userLabels > 0) = userLabels(userLabels > 0);
        end
    else
        % the file exists, but does not have a label file. ask to proceed
        answer = questdlg('The existing file does not contain a "labels" variable.', ...
            'Warning', ...
            'Overwrite file','Cancel','Cancel');
        if strcmp(answer,'Cancel')
            return
        end
    end
end
save(get(handles.outputTxt,'String'), 'labels'); % save data to file
disptext(handles, ['Labels saved to ', get(handles.outputTxt,'String')]);
% check if anything is missing before classification
function [missing] = checkMissingEntries(handles, mode) 
missing = 1;
if isempty(handles.eegTxt.String)
    animateBoxes(getappdata(handles.runBtn,'eegIndicators'),0);
    disptext(handles, 'ERROR: Please load an EEG file');
    return
end
if isempty(handles.emgTxt.String)
    animateBoxes(getappdata(handles.runBtn,'emgIndicators'),0);
    disptext(handles, 'ERROR: Please load an EMG file');
    return
end
if isempty(handles.outputTxt.String)
    animateBoxes(getappdata(handles.runBtn,'outputIndicators'),0);
    disptext(handles, 'ERROR: Please specify a filename for the sleep stage labels');
    return
end
if isempty(handles.srBox.String)
    animateBoxes(getappdata(handles.runBtn,'srIndicators'),0);
    disptext(handles, 'ERROR: Please specify EEG/EMG sampling rate');
    return
end
if isempty(handles.tsBox.String)
    animateBoxes(getappdata(handles.runBtn,'tsIndicators'),0);
    disptext(handles, 'ERROR: Please set the epoch length for sleep stage labels');
    return
end
if ~isnumeric(str2num(get(handles.srBox,'String'))) || ~isnumeric(str2num(get(handles.tsBox,'String')))
    animateBoxes([getappdata(handles.runBtn,'srIndicators'),...
        getappdata(handles.runBtn,'tsIndicators')],0);
    disptext(handles, 'ERROR: Sampling rate and epoch length must be numeric');
    return
end
if str2num(get(handles.srBox,'String')) <= 0 || str2num(get(handles.tsBox,'String')) <= 0
    animateBoxes([getappdata(handles.runBtn,'srIndicators'),...
        getappdata(handles.runBtn,'tsIndicators')],0);
    disptext(handles, 'ERROR: Sampling rate and epoch length must be positive');
    return
end
if mode == 1 % automatic rather than manual
    if isempty(handles.calibTxt.String)
        nimateBoxes(getappdata(handles.runBtn,'calibIndicators'),0);
        disptext(handles, 'ERROR: Please select or create a calibration data file');
        return
    end
    if isempty(handles.netTxt.String)
        nimateBoxes(getappdata(handles.runBtn,'netIndicators'),0);
        disptext(handles, 'ERROR: Please select a trained network file');
        return
    end
end
missing = 0;


% miscellaneous callbacks
function srBox_Callback(hObject, eventdata, handles)
% setIndicator(getappdata(handles.runBtn,'srIndicators'), [.96 .35 .35])
setIndicator(getappdata(handles.runBtn,'srIndicators'), 'failure')
sr = str2num(get(handles.srBox,'String'));
if ~isempty(sr) % if it's a number
    if sr > 0 % and positive
        if sr >= 128
            setIndicator(getappdata(handles.runBtn,'srIndicators'), 'success')
        else
            setIndicator(getappdata(handles.runBtn,'srIndicators'), 'warning')
            disptext(handles, 'WARNING: Sampling rate of at least 128Hz recommended');
        end
    end
end


function srBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function tsBox_Callback(hObject, eventdata, handles)
% setIndicator(getappdata(handles.runBtn,'tsIndicators'), [.96 .35 .35])
setIndicator(getappdata(handles.runBtn,'tsIndicators'), 'failure')
ts = str2num(get(handles.tsBox,'String'));
if ~isempty(ts) % if it's a number
    if ts > 0 % and positive
        if ts >= 2 % in the range we've tested
            setIndicator(getappdata(handles.runBtn,'tsIndicators'), 'success')
        else
            setIndicator(getappdata(handles.runBtn,'tsIndicators'), 'serious_warn')
            disptext(handles, 'WARNING: Epoch length less than 2 seconds not recommended');
        end
    end
end

function tsBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% add some line of text to the console window
function disptext(handles, string)
t = getappdata(handles.console,'text');
ln = getappdata(handles.console,'line');

t{ln}=string;
ln = ln+1;
if ln == 9
    ln = 8;
    t = t(2:8);
end
set(handles.console,'String',t)
setappdata(handles.console,'text',t);
setappdata(handles.console,'line',ln);

% make some list of indicators a given color
function setIndicator(handles, code)
switch code
    case 'success'
        str = char(hex2dec('2713'));
        color = [.45 .96 .37];
        size = 18;
        weight = 'bold';
    case 'warning'
        str = '!';
        color = [1 .7 .13];
        size = 15;
        weight = 'bold';
    case 'unknown'
        str = '?';
        color = [.5 .5 .5];
        size = 15;
        weight = 'bold';
    case 'failure'
        str = 'X';
        color = [.96 .35 .35];
        size = 15;
        weight = 'bold';
    case 'working'
        str = '*';
        color = [1 .87 .16];
        size = 23;
        weight = 'bold';
    case 'serious_warn'
        str = '!!';
        color = [.96 .35 .35];
        size = 15;
        weight = 'bold';
end

for i = 1:length(handles)
    set(handles(i),'String',str, 'FontSize',size,'ForegroundColor',color,'FontWeight',weight);
    setappdata(handles(i),'code',code);
end



% whether to overwrite existing (not undefined) sleep stage labels after classification
function overwriteBox_Callback(hObject, eventdata, handles)


function boutBox_Callback(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function boutBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% animate indicators to show progress or failure of an action
% animation: 0 = failure, 1 = working, 2 = finished
% codes: if playing the finished animation, return indicators to this state
function [codes] = animateBoxes(handles, animation, codes)
if nargin < 3 % failure or working
    codes = {};
    for i = 1:length(handles)
        %         colors{i} = get(handles(i),'BackgroundColor');
        codes{i} = getappdata(handles(i),'code');
    end
end
switch animation
    case {1,2}
        % if success % show working animation
        t = .037;
        if animation==1
            for i = 1:(length(handles))  
                pause(t)
                setIndicator(handles(i),'working');
            end     
        else
            for i = 1:(length(handles))  
                pause(t)
                setIndicator(handles(i),codes{i});
            end
        end
        % else % show failure animation
    case 0
        t = .1;
        for i = 1:2
            setIndicator(handles,'failure');
            pause(t)
            setIndicator(handles,'unknown');
            pause(t)
        end
        for j = 1:length(handles)
            setIndicator(handles(j), codes{j})
        end
end
drawnow;

% from filename, get containing directory
function [d] = getDir(f)
s = strfind(f,'\');
d = f(1:s(end));


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
doc AccuSleep_instructions
