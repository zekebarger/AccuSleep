function varargout = AccuSleep_GUI(varargin)
% AccuSleep_GUI A GUI for classifying rodent sleep stages
% Zeke Barger, 081120
% To see the user manual, run this code and press the user manual button, or run:
% doc AccuSleep_instructions

% First, check that all required toolboxes are installed, and that MATLAB 
% is at least version 2017b
toolboxes = {'nnet','stats','signal','images'};
installed = zeros(1,5);
for i = 1:4
    if ~isempty(ver(toolboxes{i}))
        installed(i) = 1;
    end
end
if ~verLessThan('matlab','9.3')
    installed(5) = 1;
end
if ~all(installed) % something needs to be installed
    tboxNames = {'Deep Learning','Statistics and Machine Learning',...
        'Signal Processing','Image Processing'};
    msg ='%sError: the following updates are required:';
    for i = 1:4
        if ~installed(i)
            msg = [msg,'\nInstall the ',tboxNames{i},' Toolbox'];
        end
    end
    if ~installed(5)
        msg = [msg,'\nUpdate to MATLAB 2017b or later'];
    end
    error(msg,'')
end


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

% store data in various parts of the GUI
% console text
setappdata(handles.console,'text',{});
setappdata(handles.console,'line',1);

% store most data in an invisible text box called "D"
% hey, it works
% list box information
setappdata(handles.D,'recList',{'Recording 1'}); % the list itself
setappdata(handles.D,'recCountMax',1); % how many items have ever been in the list
% data for each recording
setappdata(handles.D,'recordings',{makeRecordingObject()});
% calibration data
setappdata(handles.D,'calibrationData',[]);
% trained network
setappdata(handles.D,'net',[]);
% indicator handles - this lets us animate the indicators easily
allIndicators = {[handles.sr1, handles.sr2, handles.sr3, handles.sr4],...
    [handles.ts1, handles.ts2, handles.ts3, handles.ts4],...
    [handles.eeg1, handles.eeg2, handles.eeg3, handles.eeg4],...
    [handles.emg1, handles.emg2, handles.emg3, handles.emg4],...
    [handles.output1, handles.output2, handles.output3, handles.output4],...
    [handles.calib1, handles.calib2],...
    [handles.net1, handles.net2]};
setappdata(handles.D,'srIndicators',allIndicators{1});
setappdata(handles.D,'tsIndicators',allIndicators{2});
setappdata(handles.D,'eegIndicators',allIndicators{3});
setappdata(handles.D,'emgIndicators',allIndicators{4});
setappdata(handles.D,'outputIndicators',allIndicators{5});
setappdata(handles.D,'calibIndicators',allIndicators{6});
setappdata(handles.D,'netIndicators',allIndicators{7});
setappdata(handles.D,'allIndicators',allIndicators);
% set the default appearance of the indicators
for i = 1:length(allIndicators)
    setIndicator(allIndicators{i}, 'failure')
    for j = 1:length(allIndicators{i})
        set(allIndicators{i}(j),'BackgroundColor',[1 1 1]);
    end
end

% display a logo, of sorts
text(handles.axes1,.51,.496,'AccuSleep','FontSize',43,'Rotation',90,'Color',[.68 .87 .71],...
    'HorizontalAlignment','center')
text(handles.axes1,.49,.504,'AccuSleep','FontSize',43,'Rotation',90,'Color',[.17 .26 .62],...
    'HorizontalAlignment','center')
    
% clear all fields
set(handles.recbox,'String',{'Recording 1'});
set(handles.recbox,'Value',1);
set(handles.srBox,'String','');
set(handles.tsBox,'String','');
set(handles.eegTxt,'String','');
set(handles.emgTxt,'String','');
set(handles.outputTxt,'String','');
set(handles.calibTxt,'String','');
set(handles.netTxt,'String','');
set(handles.boutBox,'String','5');
set(handles.overwriteBox,'Value',0);
set(handles.console,'String',{})

% --- Outputs from this function are returned to the command line.
function varargout = AccuSleep_GUI_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% selects file with EEG data
function eegBtn_Callback(hObject, eventdata, handles) 
% choose default location to look for EEG file
currentEEGpath = get(handles.eegTxt,'String');
currentEMGpath = get(handles.emgTxt,'String');
if isempty(currentEEGpath) && ~isempty(currentEMGpath)
    default = getDir(currentEMGpath);
else
    default = currentEEGpath;
end
[file,path] = uigetfile('*.mat','Select .mat file containing "EEG" variable',...
    default); % get user input
if ~ischar(file) % if nothing was selected, return
    return
end

lockInputs(handles,1); % lock inputs so they can't be changed at this time

idx = handles.recbox.Value; % get index of currently selected recording
allRecordings = getappdata(handles.D,'recordings'); % get all the recordings
rec = allRecordings{idx}; % just get contents of selected recording

disptext(handles, 'Inspecting EEG file...'); % show a helpful message
set(handles.eegTxt,'String',''); % clear the stored EEG-related data
rec.EEGpath = '';
setIndicator(getappdata(handles.D,'eegIndicators'), 'working')
drawnow;

EEGvar = whos('-file',[path,file],'EEG'); % get info about the EEG variable
if ~isempty(EEGvar) % if we found a variable named 'EEG'
    % check that it's the right shape, and is numeric
    numericClasses = {'int8', 'uint8', 'int16', 'uint16', ...
        'int32', 'uint32', 'int64', 'uint64','double','single'};
    
    if (length(EEGvar.size)>2 || min(EEGvar.size)~=1) || ...
            ~any(strcmp(EEGvar.class, numericClasses))
        disptext(handles, 'ERROR: EEG variable must be a numeric 1D matrix');
        % update the recording's information
        rec.indicators{1} = 'failure';
        allRecordings{idx}=rec;
        setappdata(handles.D,'recordings',allRecordings);
        lockInputs(handles,0); % unlock the inputs
        updateDisplay(handles); % update the display
        return
    end
    % store the information
    rec.EEGlen = max(EEGvar.size);
    rec.EEGpath = [path,file];
    rec.indicators{1} = 'success';
    
    disptext(handles, 'EEG file selected');
    % check if EEG/EMG are the same length
    if ~isempty(get(handles.emgTxt,'String')) % if EMG file has been selected
        if rec.EEGlen ~= rec.EMGlen
            rec.indicators{1} = 'serious_warn';
            rec.indicators{2} = 'serious_warn';
            disptext(handles, 'WARNING: EEG and EMG are not currently the same length');
        else
            rec.indicators{1} = 'success';
            rec.indicators{2} = 'success';
        end
    end
else
    disptext(handles, 'ERROR: File must contain a variable named EEG');
    rec.indicators{1} = 'failure';
end
allRecordings{idx}=rec; % store new EEG data
setappdata(handles.D,'recordings',allRecordings);
lockInputs(handles,0); % unlock the inputs
updateDisplay(handles); % update the display

% selects EMG data file
function emgBtn_Callback(hObject, eventdata, handles) 
currentEEGpath = get(handles.eegTxt,'String');
currentEMGpath = get(handles.emgTxt,'String');
if isempty(currentEMGpath) && ~isempty(currentEEGpath)
    default = getDir(currentEEGpath);
else
    default = currentEMGpath;
end
[file,path] = uigetfile('*.mat','Select .mat file containing "EMG" variable',...
    default);
if ~ischar(file)
    return
end

lockInputs(handles,1); 
idx = handles.recbox.Value; % get currently selected recording
allRecordings = getappdata(handles.D,'recordings'); % get all the recordings
rec = allRecordings{idx}; % just get info for current recording

disptext(handles, 'Inspecting EMG file...');
set(handles.emgTxt,'String','');
rec.EMGpath = '';
setIndicator(getappdata(handles.D,'emgIndicators'), 'working')
drawnow;

EMGvar = whos('-file',[path,file],'EMG'); % get information about file contents
if ~isempty(EMGvar) % if we found a variable named 'EMG'
    % check that it's the right shape, and is numeric
    numericClasses = {'int8', 'uint8', 'int16', 'uint16', ...
        'int32', 'uint32', 'int64', 'uint64','double','single'};
    
    if (length(EMGvar.size)>2 || min(EMGvar.size)~=1) || ...
            ~any(strcmp(EMGvar.class, numericClasses))
        disptext(handles, 'ERROR: EMG variable must be a numeric 1D matrix');
        % update the recording's information
        rec.indicators{2} = 'failure';
        allRecordings{idx}=rec;
        setappdata(handles.D,'recordings',allRecordings);
        lockInputs(handles,0); % unlock the inputs
        updateDisplay(handles); % update the display
        return
    end
    % store the information
    rec.EMGlen = max(EMGvar.size);
    rec.EMGpath = [path,file];
    rec.indicators{2} = 'success';
    
    disptext(handles, 'EMG file selected');
    if ~isempty(get(handles.eegTxt,'String'))
        if rec.EEGlen ~= rec.EMGlen
            rec.indicators{1} = 'serious_warn';
            rec.indicators{2} = 'serious_warn';
            disptext(handles, 'WARNING: EEG and EMG are not currently the same length');
        else
            rec.indicators{1} = 'success';
            rec.indicators{2} = 'success';
        end
    end
else
    disptext(handles, 'ERROR: File must contain a variable named EMG');
    rec.indicators{2} = 'failure';
end
allRecordings{idx}=rec;
setappdata(handles.D,'recordings',allRecordings);
lockInputs(handles,0);
updateDisplay(handles); % update the display

function outputBtn_Callback(hObject, eventdata, handles) % sets location of output file
% find default folder in which to look for a labels file
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

% get file
[file,path] = uiputfile('*.mat',...
    ['Enter new filename for saving sleep stage labels, or select existing file',...
    ' (IGNORE the message about replacement)'],...
    default); % get user input
if ~ischar(file) % user did not give input
    return
end

lockInputs(handles,1); % lock the inputs

idx = handles.recbox.Value; % get currently selected recording
allRecordings = getappdata(handles.D,'recordings'); % get all the recordings
rec = allRecordings{idx}; % just get info for current recording

rec.labelpath = [path,file]; % store the input
rec.indicators{3} = 'success';

% try to load the file
if exist(rec.labelpath)==2 % if the file exists
    d = load(rec.labelpath); % load it
    if isfield(d,'labels') % if it has a field called labels
        disptext(handles,'Label file found');
    else
        if isempty(fieldnames(d)) % if file is just empty
            disptext(handles, 'Name for label file has been set');
        else % file has some other contents that could be overwritten
            rec.indicators{3} = 'serious_warn';
            disptext(handles,...
                'WARNING: label file has other (non-label) contents that will be overwritten.');
            disptext(handles,...
                '         See the user manual for instructions on formatting the label file.');
        end
    end
else
    disptext(handles, 'Output filename set');
end

allRecordings{idx}=rec; % store the loaded labels
setappdata(handles.D,'recordings',allRecordings);
lockInputs(handles,0); % unlock the inputs
updateDisplay(handles);


% view or manually score a recording
function manualBtn_Callback(hObject, eventdata, handles)
% make sure we have the data we need
if checkMissingEntries(handles, 0,0)
    return
end

disptext(handles, 'Working...');
lockInputs(handles,1);
drawnow;

% check if a label file already exists, and load those labels if possible
idx = handles.recbox.Value; % get currently selected recording
allRecordings = getappdata(handles.D,'recordings'); % get all the recordings
selectedFile = allRecordings{idx}.labelpath; % just get info for current recording
labels = [];
if exist(selectedFile)==2 % if the file exists
    d = load(selectedFile, 'labels'); % load it
    if isfield(d,'labels') % if it has a field called labels
        labels = d.labels; % use them
    end
end

% show animation
ind = getappdata(handles.D,'allIndicators');
codes=animateBoxes([ind{1}(2), ind{2}(2),ind{3}(2),ind{4}(2),ind{5}(2)], 1);

% load the EEG/EMG data
eegFile = load(allRecordings{idx}.EEGpath,'EEG');
emgFile = load(allRecordings{idx}.EMGpath,'EMG');

% launch AccuSleep_viewer to manually annotate the recording
message = AccuSleep_viewer(eegFile.EEG, emgFile.EMG,...
    str2num(get(handles.srBox,'String')),...
    str2num(get(handles.tsBox,'String')), labels, selectedFile);
disptext(handles, message);

% complete animation
animateBoxes([ind{1}(2), ind{2}(2),ind{3}(2),ind{4}(2),ind{5}(2)], 2, codes);
lockInputs(handles,0); 


% sets calibration file path
function calibBtn_Callback(hObject, eventdata, handles) 
[file,path] = uigetfile('*.mat','Select .mat file containing "calibrationData" variable',...
    get(handles.calibTxt,'String')); % get user input
if ischar(file) % if something was selected
    disptext(handles, 'Loading calibration file...');
    set(handles.calibTxt,'String',''); % clear currently stored data
    setappdata(handles.D,'calibrationData',[]);
    setIndicator(getappdata(handles.D,'calibIndicators'), 'working')
    drawnow;
    d = load([path,file], 'calibrationData'); % load the file
    if isfield(d,'calibrationData') % if it has the field we need
        setappdata(handles.D,'calibrationData',d.calibrationData); % store new data
        set(handles.calibTxt,'String',[path,file]);
        disptext(handles, 'Calibration file selected');
        setIndicator(getappdata(handles.D,'calibIndicators'), 'success')
    else
        disptext(handles, 'ERROR: File must contain a variable named calibrationData');
        setIndicator(getappdata(handles.D,'calibIndicators'), 'failure')
    end
end


% sets path to the trained network file
function netFile_Callback(hObject, eventdata, handles) 
[file,path] = uigetfile(...
    '*.mat','Select .mat file containing "net" variable (the trained network)',...
    get(handles.netTxt,'String')); % get user input
if ischar(file)
    disptext(handles, 'Loading trained network...');
    set(handles.netTxt,'String','');
    setappdata(handles.D,'net',[]);
    setIndicator(getappdata(handles.D,'netIndicators'), 'working')
    drawnow;
    d = load([path,file], 'net');
    if isfield(d,'net')
        setappdata(handles.D,'net',d.net);
        set(handles.netTxt,'String',[path,file]);
        disptext(handles, 'Trained network file selected');
        setIndicator(getappdata(handles.D,'netIndicators'), 'success')
    else
        disptext(handles, 'ERROR: File must contain a variable named net');
        setIndicator(getappdata(handles.D,'netIndicators'), 'failure')
    end
end

function createBtn_Callback(hObject, eventdata, handles) % creates a calibration data file
lockInputs(handles,1); % lock the inputs

idx = handles.recbox.Value; % get currently selected recording
allRecordings = getappdata(handles.D,'recordings'); % get all the recordings
rec = allRecordings{idx}; % the currently considered recording

% make sure we have the files we need
if checkMissingEntries(handles, 0, 0)
    lockInputs(handles,0); 
    return
end

% check if label file exists
if exist(rec.labelpath)~=2
    animateBoxes(getappdata(handles.D,'outputIndicators'),0);
    disptext(handles,...
        'ERROR: Sleep stage label file does not exist, see Section 4 of the user manual');
    lockInputs(handles,0);
    return
end

% check if it has the correct contents
d = load(rec.labelpath, 'labels'); % load label file
if isfield(d,'labels') % if it has a field called labels
    labels = d.labels; % get the labels
else
    animateBoxes(getappdata(handles.D,'outputIndicators'),0);
    disptext(handles, 'ERROR: Sleep stage label file must have a variable called "labels"');
    lockInputs(handles,0);
    return
end
% check if all labels are outside the range 1:3
if all(labels > 3 | labels < 1)
    animateBoxes(getappdata(handles.D,'outputIndicators'),0);
    disptext(handles, 'ERROR: At least some labels must be in the range 1:3.');
    disptext(handles, '       See Section 4 of the user manual.');
    lockInputs(handles,0);
    return
end
% check if there are at least a few labels for each state
if ~all([sum(labels==1)>=3, sum(labels==2)>=3, sum(labels==3)>=3])
    animateBoxes(getappdata(handles.D,'outputIndicators'),0);
    disptext(handles, 'ERROR: At least some epochs of each stage must be labeled.');
    disptext(handles, '       Click the user manual button for details.');
    lockInputs(handles,0);
    return
end
% check if we have a reasonable number of labels
ts = str2num(get(handles.tsBox,'String')); % epoch length
if sum(labels <= 3 | labels >= 1) * ts / 60 < 5
    disptext(handles, 'WARNING: At least 5 minutes of labeled data are recommended for');
    disptext(handles, '         creating a calibration data file');
    disptext(handles, '         Click the user manual button for details.');
    lockInputs(handles,0);
end

if rec.EEGlen ~= rec.EMGlen % check EEG and EMG are the same length
    animateBoxes([getappdata(handles.D,'eegIndicators'),...
        getappdata(handles.D,'eegIndicators')],0);
    disptext(handles, 'ERROR: EEG and EMG must be the same length');
    lockInputs(handles,0);
    return
end

% show progress animation
ind = getappdata(handles.D,'allIndicators');
codes = animateBoxes([ind{1}(3), ind{2}(3),ind{3}(3),ind{4}(3),ind{5}(3)], 1);
disptext(handles, 'Working...');
drawnow;

% load the EEG/EMG data
eegFile = load(rec.EEGpath,'EEG');
emgFile = load(rec.EMGpath,'EMG');

% create calibrationData
oldSR = str2num(get(handles.srBox,'String')); % get SR of the recordings
calibrationData = createCalibrationData(standardizeSR(eegFile.EEG, oldSR, 128),...
    standardizeSR(emgFile.EMG, oldSR, 128),...
    labels, 128, str2num(get(handles.tsBox,'String')));

% complete progress animation
animateBoxes([ind{1}(3), ind{2}(3),ind{3}(3),ind{4}(3),ind{5}(3)], 2, codes);

% check if it failed
if isempty(calibrationData)
    animateBoxes(getappdata(handles.D,'outputIndicators'),0);
    disptext(handles, 'ERROR: Length of label file does not match length');
    disptext(handles, '       of EEG/EMG. Check the SR or epoch size?');
    lockInputs(handles,0);
    return
end

% ask for save location
[file,path] = uiputfile('*.mat','Set filename for calibration data file');
if ~ischar(file) % if no file given
    disptext(handles, 'ERROR: No filename chosen');
    lockInputs(handles,0);
    return
end

% save file
save([path,file], 'calibrationData');
disptext(handles, 'Calibration file saved');

% store calibration data
setappdata(handles.D,'calibrationData', calibrationData);

% insert filename into text box
set(handles.calibTxt,'String', [path,file]);
setIndicator(getappdata(handles.D,'calibIndicators'), 'success')
lockInputs(handles,0);


% classify sleep stages automatically
function runBtn_Callback(hObject, eventdata, handles) 
lockInputs(handles,1); % lock the inputs

% check that all boxes are filled
if checkMissingEntries(handles, 1, 1)
    lockInputs(handles,0);
    return
end

% When the minimum bout length is much longer than the epoch length, this
% creates ambiguity that can make the scoring somewhat unreliable. 
% get minimum bout length
minBoutLen = str2num(get(handles.boutBox,'String'));
if isempty(minBoutLen)
    minBoutLen = 0;
end
epoch_length = str2double(get(handles.tsBox,'String'));
if minBoutLen / epoch_length > 5
    answer = questdlg(...
        ['When the minimum bout length is much longer ',...
        'than the epoch length, this creates ambiguity ',...
        'that can decrease the reliability of the labels. ',....
        'Consider using a longer epoch length or shorter ',...
        'minimum bout length.'], ...
        'WARNING', ...
        'Continue anyway','Cancel','Cancel');
    if strcmp(answer,'Cancel')
        lockInputs(handles,0);
        return
    end
end


disptext(handles, 'Working...');
drawnow;

allRecordings = getappdata(handles.D,'recordings'); % get all the recordings


% animate
ind = getappdata(handles.D,'allIndicators');
codes = animateBoxes([ind{1}(4),...
    ind{2}(4),ind{3}(4),ind{4}(4),ind{5}(4), ind{6}(2), ind{7}(2)], 1);

% get SR of the EEG/EMG data
oldSR = str2num(get(handles.srBox,'String'));

% try to classify all recordings
newLabels = {}; % holds new labels for each recording
for i = 1:length(allRecordings)
    % show progress in the message box
    if i == 1
        disptext(handles,['Scoring recording ',num2str(i),' of ',...
            num2str(length(allRecordings))]);
        drawnow;
    else
        t = getappdata(handles.console,'text');
        t{end} = ['Scoring recording ',num2str(i),' of ',...
            num2str(length(allRecordings))];
        set(handles.console,'String',t)
        setappdata(handles.console,'text',t);
        drawnow;
    end
    
    % load the EEG/EMG data
    eegFile = load(allRecordings{i}.EEGpath,'EEG');
    emgFile = load(allRecordings{i}.EMGpath,'EMG');
    
    % run AccuSleep_classify on the recording
    newLabels{i} = AccuSleep_classify(standardizeSR(eegFile.EEG, oldSR, 128),...
        standardizeSR(emgFile.EMG, oldSR, 128),...
        getappdata(handles.D,'net'),128, epoch_length,...
        getappdata(handles.D,'calibrationData'), minBoutLen);
    if isempty(newLabels{i}) % if something went wrong
        % show an error message and quit. This shouldn't happen often.
        currentList = getappdata(handles.D,'recList');
        disptext(handles, ['ERROR: ',currentList{i},' could not be scored.']);
        disptext(handles, '       No files have been changed. See command window for details');
        animateBoxes([ind{1}(4),...
            ind{2}(4),ind{3}(4),ind{4}(4),ind{5}(4), ind{6}(2), ind{7}(2)], 0);
        lockInputs(handles,0);
        return
    end
end

animateBoxes([ind{1}(4),...
    ind{2}(4),ind{3}(4),ind{4}(4),ind{5}(4), ind{6}(2), ind{7}(2)], 2, codes);

% save labels to file
for i = 1:length(allRecordings)
    % if we need to keep existing labels...
    if get(handles.overwriteBox,'Value') && exist(allRecordings{i}.labelpath, 'file')
        d = load(allRecordings{i}.labelpath, 'labels'); % load the labels
        if isfield(d, 'labels')
            userLabels = d.labels;
            userLabels(userLabels < 1) = 0; % discard undefined states
            userLabels(userLabels > 3) = 0;
            if length(userLabels) ~= length(newLabels{i})
                % the labels exist, but are the wrong length. ask to proceed
                currentList = getappdata(handles.D,'recList');
                answer = questdlg(...
                    ['The length of the existing labels for ',...
                    currentList{i},' does not match the new labels. ',...
                    'This could be caused by a discrepancy in the ',...
                    'sampling rate or epoch length.'], ...
                    'Problem with label length', ...
                    'Replace old labels','Cancel','Cancel');
                if strcmp(answer,'Cancel')
                    disptext(handles, [currentList{i},' was not scored.']);
                    continue
                end
            else
                % take existing labels (that aren't undefined)
                newLabels{i}(userLabels > 0) = userLabels(userLabels > 0);
            end
        else
            % the file exists, but does not have a label file. ask to proceed
            currentList = getappdata(handles.D,'recList');
            answer = questdlg(['The labels file for ',...
                currentList{i},' does not contain a "labels" variable.',...
                'It may have other contents.'], ...
                'Warning', ...
                'Overwrite file','Cancel','Cancel');
            if strcmp(answer,'Cancel')
                disptext(handles, [currentList{i},' was not scored.']);
                continue
            end
        end
    end
    % save labels to file
    labels = newLabels{i};
    save(allRecordings{i}.labelpath, 'labels'); 
end
disptext(handles, 'Finished scoring recordings.'); 
lockInputs(handles,0); 


% check if anything is missing before classification
% arguments: handles structure, whether to examine calibration and network
% fields also, and whether to look through all recordings or just the
% selected one
function [missing] = checkMissingEntries(handles, checkAllFields, checkAllRecs)
allRecordings = getappdata(handles.D,'recordings'); % get all the recordings

% determine which recordings to check
if ~checkAllRecs
    idx1 = handles.recbox.Value;
    idx2 = idx1;
else
    idx1 = 1;
    idx2 = length(allRecordings);
end
% get names of list items
currentList = getappdata(handles.D,'recList');

for i = idx1:idx2 % for all recordings (or just one)
    rec = allRecordings{i}; % get selected recording
    missing = 1; % assume something is missing
    if isempty(handles.srBox.String)
        animateBoxes(getappdata(handles.D,'srIndicators'),0);
        disptext(handles, 'ERROR: Please specify EEG/EMG sampling rate');
        return
    end
    % perform various checks
    if isempty(handles.tsBox.String)
        animateBoxes(getappdata(handles.D,'tsIndicators'),0);
        disptext(handles, 'ERROR: Please set the epoch length for sleep stage labels');
        return
    end
    if ~isnumeric(str2num(get(handles.srBox,'String'))) ||...
            ~isnumeric(str2num(get(handles.tsBox,'String')))
        animateBoxes([getappdata(handles.D,'srIndicators'),...
            getappdata(handles.D,'tsIndicators')],0);
        disptext(handles, 'ERROR: Sampling rate and epoch length must be numeric');
        return
    end
    if str2num(get(handles.srBox,'String')) <= 0 ||...
            str2num(get(handles.tsBox,'String')) <= 0
        animateBoxes([getappdata(handles.D,'srIndicators'),...
            getappdata(handles.D,'tsIndicators')],0);
        disptext(handles, 'ERROR: Sampling rate and epoch length must be positive');
        return
    end
    if isempty(rec.EEGpath)
        animateBoxes(getappdata(handles.D,'eegIndicators'),0);
        disptext(handles, ['ERROR: Please select an EEG file for ',...
            currentList{i}]);
        return
    end
    if isempty(rec.EMGpath)
        animateBoxes(getappdata(handles.D,'emgIndicators'),0);
        disptext(handles, ['ERROR: Please select an EMG file for ',...
            currentList{i}]);
        return
    end
    if isempty(rec.labelpath)
        animateBoxes(getappdata(handles.D,'outputIndicators'),0);
        disptext(handles,...
            ['ERROR: Please specify a filename for the sleep stage labels for ',...
            currentList{i}]);
        return
    end
    
    if checkAllFields == 1 % if we need to check other fields, too
        if isempty(handles.calibTxt.String)
            animateBoxes(getappdata(handles.D,'calibIndicators'),0);
            disptext(handles, 'ERROR: Please select or create a calibration data file');
            return
        end
        if isempty(handles.netTxt.String)
            animateBoxes(getappdata(handles.D,'netIndicators'),0);
            disptext(handles, 'ERROR: Please select a trained network file');
            return
        end
    end
    % passed all checks
    missing = 0;
end

% what to do when new SR is entered
function srBox_Callback(hObject, eventdata, handles)
setIndicator(getappdata(handles.D,'srIndicators'), 'failure')
sr = str2num(get(handles.srBox,'String'));
if ~isempty(sr) % if it's a number
    if sr > 0 % and positive
        if sr >= 128
            setIndicator(getappdata(handles.D,'srIndicators'), 'success')
        else
            setIndicator(getappdata(handles.D,'srIndicators'), 'warning')
            disptext(handles, 'WARNING: Sampling rate of at least 128Hz recommended');
        end
    end
end

function srBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% what to do when new epoch length is entered
function tsBox_Callback(hObject, eventdata, handles)
setIndicator(getappdata(handles.D,'tsIndicators'), 'failure')
ts = str2num(get(handles.tsBox,'String'));
if ~isempty(ts) % if it's a number
    if ts > 0 % and positive
        if ts >= 2 % in the range we've tested
            setIndicator(getappdata(handles.D,'tsIndicators'), 'success')
        else
            setIndicator(getappdata(handles.D,'tsIndicators'), 'serious_warn')
            disptext(handles, 'WARNING: Epoch length less than 2 seconds not recommended');
        end
    end
end

function tsBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% add a line of text to the message box
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
s = strfind(f,filesep);
d = f(1:s(end));


% --- Executes on button press in helpBtn.
function helpBtn_Callback(hObject, eventdata, handles)
doc AccuSleep_instructions


% --- Executes on selection change in recbox.
function recbox_Callback(hObject, eventdata, handles)
updateDisplay(handles);


% --- Executes during object creation, after setting all properties.
function recbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in addrecbtn.
% adds a recording to the list
function addrecbtn_Callback(hObject, eventdata, handles)
% get the current state of the list
currentList = getappdata(handles.D,'recList');
recCountMax = getappdata(handles.D,'recCountMax');
% add a new recording to the list
currentList{end+1} = ['Recording ',num2str(recCountMax+1)];
setappdata(handles.D,'recCountMax',recCountMax+1);
% update the list box
set(handles.recbox,'String',currentList);
% update our stored list of recordings
setappdata(handles.D,'recList',currentList);
% and update our set of recording data structures
setappdata(handles.D,'recordings',...
    [getappdata(handles.D,'recordings'),makeRecordingObject()]);
% update the display
updateDisplay(handles);

% --- Executes on button press in removerecbtn.
% removes a recording from the list
function removerecbtn_Callback(hObject, eventdata, handles)
% get index of recording to remove from the list
idx = handles.recbox.Value;
% get the current list
currentList = getappdata(handles.D,'recList');
% if this is the last item in the list, clear its contents
if length(currentList) == 1
    % clear first recording's data
    setappdata(handles.D,'recordings',{makeRecordingObject()});
    % update the display
    updateDisplay(handles);
    return
end
% make sure the value attribute of the list stays in a safe range
if idx == length(currentList)
    set(handles.recbox,'Value',length(currentList)-1)
end
% remove item from the current list
currentList(idx) = [];
% update the list box
set(handles.recbox,'String',currentList);
% update our stored list of recordings
setappdata(handles.D,'recList',currentList);
% and update our set of recording data structures
currentRecordings = getappdata(handles.D,'recordings');
currentRecordings(idx) = [];
setappdata(handles.D,'recordings',currentRecordings);
% update the display
updateDisplay(handles);

% create an object to store data for a single recording
function [x] = makeRecordingObject()
x = struct;
x.EEGlen = []; % length of EEG signal
x.EMGlen = [];
x.EEGpath = ''; % path to EEG file
x.EMGpath = '';
x.labelpath = '';
x.indicators = {'failure','failure','failure'}; % status of indicators (EEG,EMG,labels)

% update the text boxes and indicators when something changes
function [] = updateDisplay(handles)
idx = handles.recbox.Value; % get currently selected recording
allRecordings = getappdata(handles.D,'recordings'); % get all the recordings
rec = allRecordings{idx}; % just get info for current recording
% show file paths
set(handles.eegTxt,'String',rec.EEGpath);
set(handles.emgTxt,'String',rec.EMGpath);
set(handles.outputTxt,'String',rec.labelpath);
% set the associated indicators
setIndicator(getappdata(handles.D,'eegIndicators'), rec.indicators{1});
setIndicator(getappdata(handles.D,'emgIndicators'), rec.indicators{2});
setIndicator(getappdata(handles.D,'outputIndicators'), rec.indicators{3});

% indicator for all recordings can only show 'success' if all recordings
%     are also 'success'
overallIndicators = {'success','success','success'};
for j = 1:3 % for each indicator
    for i = 1:length(allRecordings) % for each recording
        if ~strcmp(allRecordings{i}.indicators{j},'success') % if it's not a success
            overallIndicators{j} = allRecordings{i}.indicators{j}; % show that
            if strcmp(overallIndicators{j},'failure') % 'failure' overrides all others
                break
            end
        end
    end
end
% set the indicators
setIndicator(handles.eeg4,overallIndicators{1});
setIndicator(handles.emg4,overallIndicators{2});
setIndicator(handles.output4,overallIndicators{3});
% It can't be determined in advance whether the labels are adequate for
% creating a calibrationData structure
if strcmp(rec.indicators{3},'success')
    ind = getappdata(handles.D,'outputIndicators');
    setIndicator(ind(3), 'unknown')
end

% lock input fields while the program is busy (1), or unlock them (0)
function [] = lockInputs(handles,locked)
handlesToLock = {handles.recbox, handles.addrecbtn, handles.removerecbtn,...
    handles.srBox, handles.tsBox, handles.eegBtn, handles.emgBtn,...
    handles.outputBtn, handles.manualBtn, handles.createBtn,...
    handles.calibBtn, handles.netFile, handles.runBtn,...
    handles.overwriteBox, handles.boutBox};
if locked
    for i = 1:length(handlesToLock)
        set(handlesToLock{i},'Enable','off');
    end
else
    for i = 1:length(handlesToLock)
        set(handlesToLock{i},'Enable','on');
    end
end
