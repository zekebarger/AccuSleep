function AccuSleep_instructions
% AccuSleep user manual
% 
% Section 1: Overview of the GUI
% Section 2: AccuSleep data structures
% Section 3: Manually assigning sleep stage labels
% Section 4: Automatically assigning sleep stage labels
%
% 
% ----------------------------------------------------------------------- 
% Section 1: Overview of the GUI
% ----------------------------------------------------------------------- 
% 
% This interface allows a user to assign sleep stage labels to 1-channel 
% electroencephalogram (EEG) and electromyogram (EMG) data. Controls for 
% manual labeling are in the upper panel, and controls for automatic 
% labeling are in the middle panel. The lower panel displays messages 
% about the state of the program. 
% 
% Please read Section 2 for information on how to structure the inputs to
% this program. Five inputs are required for manual labeling, and seven 
% are required for automatic labeling. To the right of each input is a 
% colored indicator. If an input is required by a function listed on the
% left side of the interface, its indicator will also be shown there. The
% indicators can have several colors:
% 
% Red: the input is missing or is not in the required format. 
% Green: the input has the correct format.
% Yellow: the input is not in the recommended range.
% Orange: there may be a serious problem with the input.
% Gray: the state of the input is unknown, and may or may not be correct. 
% 
% 
% ----------------------------------------------------------------------- 
% Section 2: AccuSleep data structures
% ----------------------------------------------------------------------- 
% 
% There are five types of files associated with AccuSleep:
% 
% EEG file: a .mat file containing a variable named ‘EEG’ that is a 1-D
%    numeric matrix. No filtering or other preprocessing is necessary. 
%    This should be a 1-channel electroencephalogram signal.
% 
% EMG file: same format as EEG, but the variable is named ‘EMG’. The EEG
%    and EMG data must be the same length. This should be a 1-channel 
%    electromyogram signal.
% 
% Label file: a .mat file containing a variable called ‘labels’ that is
%    a 1-D numeric matrix with values ranging from 1-4 (1 = REM sleep, 
%    2 = wakefulness, 3 = NREM sleep, 4 = undefined) corresponding to
%    the sleep stage in each epoch. 
% 
% Calibration data file: required for automatic labeling. See Section 4 
%    for details.
% 
% Trained network file: required for automatic labeling. See Section 4 
%    for details.
% 
% 
% ----------------------------------------------------------------------- 
% Section 3: Manually assigning sleep stage labels
% ----------------------------------------------------------------------- 
% 
% 1. Click the ‘Load EEG file’ button to load the EEG data.
% 
% 2. Click the ‘Load EMG file’ button to load the EMG data.
% 
% 3. Click the ‘Output file location’ and enter a filename for saving the
%    sleep stage labels. You can also select an existing label file if
%    you wish to view or modify its contents.
% 
% 4. Enter the sampling rate of the EEG/EMG data, in Hz.
% 
% 5. Enter the epoch length, in seconds. This determines the time 
%    resolution of the labels. Typical values are 2.5, 4, and 5.
% 
% 6. Click ‘Classify manually’ to launch an interactive figure window for
%    manual sleep stage labeling. Click the ‘help’ button in the upper
%    right of the figure for instructions. Click the save button at any
%    time to save the sleep stage labels to the file specified in 
%    step 3, and close the window when you are finished.
% 
% 
% ----------------------------------------------------------------------- 
% Section 4: Automatically assigning sleep stage labels using a trained
%    neural network
% ----------------------------------------------------------------------- 
% 
% Automatic sleep stage labeling requires the five inputs described in 
% Section 3, as well as a calibration data file and a trained network
% file. If you have these two files, proceed to Section 4C.
% 
% 
% Section 4A: Creating a calibration data file
% 
% You must create a new calibration data file for each subject. If you
% record from the same subject using different recording equipment, you
% must create a new calibration data file for each combination of 
% subject + recording setup. This ensures that inputs to the neural
% network are in the same range as its training data. 
% 
% Instructions for creating a calibration data file using this GUI are 
% below. You can also run createCalibrationData.m and save the output 
% in a .mat file in a variable called ‘calibrationData’.
% 
% 1. Complete steps 1-5 of Section 3 (specifying the EEG file, EMG file,
%    label file, sampling rate, and epoch length).
% 
% 2. The label file must contain at least some labels for each sleep 
%    stage (REM, wakefulness, and NREM). It is recommended to label at
%    least several minutes of each stage, and more labels will improve 
%    classification accuracy. If the label file already meets this 
%    condition, continue to step 3. Otherwise, click 
%    ‘Classify manually’, assign some sleep stage labels to the 
%    recording, and save the labels. 
% 
% 3. Click ‘Create calibration data file’.
% 
% 4. Enter a filename for the calibration data file.
% 
% 
% Section 4B: Creating a trained network file
% 
% Pre-trained neural networks are located in the trainedNetworks folder 
% with epoch lengths of 2.5, 4, 5, and 10 seconds. If you wish to train 
% your own network, see AccuSleep_train.m for details. You will need to 
% create a cell array containing filenames of EEG, EMG, and label files 
% in the training set. AccuSleep_train produces a SeriesNetwork object. 
% Name this variable ‘net’ and save it in a .mat file. You can then load 
% it in step 3 of Section 4C. Unfortunately, it seems that networks 
% trained using MATLAB 2019a or later are not readable by versions
% 2018b or earlier. However, networks trained using MATLAB 2018b or
% earlier seem to be forward compatible.
% 
% 
% Section 4C: Automatic labeling
% 
% Instructions for automatic labeling using this GUI are below. For 
% batch processing of many recordings, see AccuSleep_classify.m
% 
% 1. Complete steps 1-5 of Section 3 (specifying the EEG file, EMG file,
%    label file, sampling rate, and epoch length).
% 
% 2. If you completed the steps in Section 4A, a calibration data file 
%    has already been specified. Otherwise, click 
%    ‘Load calibration file’ to load the calibration data file.
% 
% 3. Click ‘Load trained network file’ to load the trained neural
%    network. The epoch length used when training this network should be
%    the same as the current epoch length.
% 
% 4. If you with to preserve any existing labels in the label file, and
%    only overwrite undefined epochs, uncheck
%    ‘Overwrite existing labels’.
% 
% 5. Set the minimum bout length, in seconds. A typical value is 5. 
%    Following automatic labeling, any sleep stage bout shorter than this 
%    duration will be reassigned to the surrounding stage (if the stages 
%    on either side of the bout match). 
% 
% 6. Click ‘Classify automatically’. Labels will be saved to the file 
%    specified by the ‘Output file location’. You can click 
%    ‘Classify manually’ to visualize the results.
% 
doc AccuSleep_instructions
