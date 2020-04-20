function AccuSleep_instructions
% AccuSleep user manual
% Updated 10/30/19
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
% electroencephalogram (EEG) and electromyogram (EMG) data. The algorithm
% has (so far) only been tested on rodents, not humans.
%
% The overall workflow when using AccuSleep_GUI looks like this:
% 1. Enter the sampling rate and epoch length for all recordings from
%    one subject
% 2. For each recording from this subject, add it to the recording list, 
%    load the EEG/EMG data, and determine where to save the sleep stage 
%    labels (or load the labels if they already exist)
% (At this stage, you can score the recordings manually)
% 3. Choose a representative recording that has some epochs of each state
%    labeled and use it to create a calibration data file (or load the
%    calibration data file if it already exists)
% 4. Choose a trained neural network file, with a matching epoch size
% 5. Score all recordings for this subject automatically
% 6. Start over for the next subject
% 
% Please read Section 2 for information on how to structure the inputs to
% this program. Five inputs are required for manual labeling, and seven 
% are required for automatic labeling. To the right of each input is a 
% colored indicator. If an input is required by a function listed on the
% left side of the interface, its indicator will also be shown there. The
% indicators can have several forms:
% 
% Red X: the input is missing or is not in the required format. 
% Green check: the input has the correct format.
% Yellow !: the input is not in the recommended range.
% Orange !!: there may be a serious problem with the input.
% Gray ?: the state of the input is unknown, and may or may not be correct. 
% 
% 
% ----------------------------------------------------------------------- 
% Section 2: AccuSleep data structures
% ----------------------------------------------------------------------- 
% 
% There are five types of files associated with AccuSleep:
% 
% EEG file: a .mat file containing a variable named 'EEG' that is a 1-D
%    numeric matrix. No filtering or other preprocessing is necessary. 
%    This should be a 1-channel electroencephalogram signal.
% 
% EMG file: same format as EEG, but the variable is named 'EMG'. The EEG
%    and EMG data must be the same length. This should be a 1-channel 
%    electromyogram signal.
% 
% Label file: a .mat file containing a variable called 'labels' that is
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
% 1. Select the recording you wish to modify from the recording list, or
%    add a new one. Make sure the sampling rate (in Hz) and epoch length
%    (in seconds) are set. The epoch length determines the time 
%    resolution of the labels. Typical values are 2.5, 4, and 5.
%
% 2. Click the 'Select EEG file' button to set the location of the EEG data.
% 
% 3. Click the 'Select EMG file' button to set the location of the EMG data.
% 
% 4. Click 'Set / load label file' and enter a filename for saving the
%    sleep stage labels. You can also select an existing label file if
%    you wish to view or modify its contents.
% 
% 5. Click 'Score selected manually' to launch an interactive figure 
%    window for manual sleep stage labeling. Click the 'help' button in
%    the upper right of the figure for instructions. Click the save 
%    button at any time to save the sleep stage labels to the file 
%    specified in step 4, and close the window when you are finished.
% 
% 
% ----------------------------------------------------------------------- 
% Section 4: Automatically assigning sleep stage labels using a trained
%    neural network
% ----------------------------------------------------------------------- 
% 
% Automatic sleep stage labeling requires the five inputs described in 
% Section 3, as well as a calibration data file and a trained network
% file. If you already have both of these files, proceed to Section 4C.
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
% in a .mat file in a variable called 'calibrationData'.
% 
% 1. Complete steps 1-4 of Section 3 (specifying the EEG file, EMG file,
%    label file, sampling rate, and epoch length).
% 
% 2. The label file must contain at least some labels for each sleep 
%    stage (REM, wakefulness, and NREM). It is recommended to label at
%    least several minutes of each stage, and more labels will improve 
%    classification accuracy. If the label file already meets this 
%    condition, continue to step 3. Otherwise, click 
%    'core selected manually', assign some sleep stage labels to the 
%    recording, and save the labels. 
% 
% 3. Click 'Create calibration data file'.
% 
% 4. Enter a filename for the calibration data file.
% 
% 
% Section 4B: Creating a trained network file
% 
% Pre-trained neural networks are provided with AccuSleep for epoch 
% lengths of 2.5, 4, 5, 10, 15, and 30 seconds. If you wish to train 
% your own network, see AccuSleep_train.m for details. You will need to 
% create a cell array containing filenames of EEG, EMG, and label files 
% in the training set. See fileList_template.mat for an example of how 
% to structure this array. AccuSleep_train produces a SeriesNetwork 
% object. Name this variable 'net' and save it in a .mat file. You can 
% then load it in step 3 of Section 4C.
% 
% 
% Section 4C: Automatic labeling
% 
% Instructions for automatic labeling using this GUI are below. To
% batch process recordings from multiple subjects, see 
% AccuSleep_classify.m
% 
% 1. Set the sampling rate and epoch length, and complete steps 1-4 of
%    Section 3 (specifying the EEG file, EMG file, and label file) for
%    each recording from one subject. Since each subject requires its
%    own calibration file, only recordings from one subject can be 
%    scored at a time. If the recording conditions are different in
%    some recordings (e.g., a different amplified was used), remove 
%    these recordings from the recording list and process them 
%    separately with their own calibration file.
% 
% 2. If you completed the steps in Section 4A, a calibration data file 
%    has already been specified. Otherwise, click 
%    'Load calibration file' to load the calibration data file.
% 
% 3. Click 'Load trained network file' to load the trained neural
%    network. The epoch length used when training this network should be
%    the same as the current epoch length.
% 
% 4. If you wish to preserve any existing labels in the label file, and
%    only overwrite undefined epochs, check the box labeled
%    'Only overwrite undefined epochs'.
% 
% 5. Set the minimum bout length, in seconds. A typical value is 5. 
%    Following automatic labeling, any sleep stage bout shorter than this 
%    duration will be reassigned to the surrounding stage (if the stages 
%    on either side of the bout match). 
% 
% 6. Click 'Score all automatically' to score all recordings in the
%    recording list. Labels will be saved to the file specified by 
%    the 'Set / load label file' field of each recording. You can click 
%    'Score selected manually' to visualize the results. Note that unless
%    the ‘Only overwrite undefined epochs' box is checked, any other
%    contents (e.g., other variables) in the existing label file will 
%    be automatically overwritten.
% 
doc AccuSleep_instructions
