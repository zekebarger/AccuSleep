# AccuSleep

## Updates
**11/09/2022** - A [video walkthrough](https://www.youtube.com/watch?v=O81qdHlzTbc) is now available.

**06/12/2021** - Support for scoring more than three brain states is now available with [AccuSleep X](https://github.com/zekebarger/AccuSleep_X).

**08/11/2020** - Mac compatibility. AccuSleep should now be functional on Mac computers.

**04/09/2020** - Implemented a better algorithm for removing short bouts.

**11/05/2019** - EEG/EMG data are now only loaded when necessary to avoid out-of-memory errors.
    
**10/30/2019** - The primary user interface has received a major update, and now
    allows all recordings from one subject to be processed simultaneously. A 
    small bug was also fixed, the user manual was updated, and error messages 
    should be more helpful. 

## Description

AccuSleep is a set of graphical user interfaces for scoring rodent
sleep using EEG and EMG recordings. If you use AccuSleep in your research, please cite our [publication](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0224642):

Barger, Z., Frye, C. G., Liu, D., Dan, Y., & Bouchard, K. E. (2019). Robust, automated sleep scoring by a compact neural network with distributional shift correction. *PLOS ONE, 14*(12), 1–18.

The data used for training and testing AccuSleep are available at https://osf.io/py5eb/

Please contact zekebarger (at) gmail (dot) com with any questions or comments about the software.

## Installation instructions

1. Make sure your version of MATLAB meets the specifications in the
"Requirements" section below.

2. Click the "Clone or download" button and choose "Download ZIP".

3. Extract the contents of the zip file.

4. Add AccuSleep to your MATLAB path. You can do this in the MATLAB "Current Folder"
window by right-clicking the AccuSleep folder, clicking "Add to Path"
--> "Selected Folders and Subfolders", then running the command
`savepath`
in the Command Window.

To get started, run `AccuSleep_GUI` and click the "User manual" button, check out the [video walkthrough](https://www.youtube.com/watch?v=O81qdHlzTbc), or run
`doc AccuSleep_instructions`
for a full explanation of these functions and the types of input
they require.

## Requirements
- MATLAB version 2017b or later
- Statistics and Machine Learning Toolbox
- Deep Learning Toolbox
- Signal Processing Toolbox
- Image Processing Toolbox

## Functions

`AccuSleep_GUI` provides an interface for most of the functions
in this package, but if you want to batch process recordings from multiple subjects, you can
call the required functions yourself.

- **`AccuSleep_GUI`** A user interface for labeling sleep states, either
    manually or automatically
- **`AccuSleep_viewer`** A user interface for manually labeling sleep states
- **`AccuSleep_classify`** Automatically labels sleep states using a
    pre-trained neural network
- **`AccuSleep_train`** Trains a neural network for labeling sleep states
- **`createCalibrationData`** Generates a file that is required for automatic
    sleep state labeling for a given combination of subject and
    recording equipment

## Tips & Troubleshooting
- Make sure the required toolboxes are installed.
- Using more data for calibration will produce better results. However, labeling 
  more than a few minutes of each state probably isn't necessary.
- If you create a calibration file using one recording, then use it to score another
  recording automatically, and the accuracy is low, the signals might be different
  between the two recordings. In this case, it's best to create a new calibration file.
- If your accuracy seems low no matter what you do, you may wish to train your own
  network.
- Make sure to click the 'Help' button in AccuSleep_viewer for a list of keyboard shortcuts.
- Make sure to run `doc AccuSleep_instructions` and read the documentation before using
  this software.
- If your recordings are very long (>48 hours) and are not displaying properly, try splitting
  them into smaller files.
- Ensure the epoch length associated with the labels, calibration data, and trained network 
  are the same.
- Networks trained using MATLAB 2019a or later do not seem to be backward compatible with earlier
  versions of MATLAB. However, networks trained on 2018b or earlier seem to be forward compatible.
- Make sure the recordings are free of NaN and Inf values.

## Acknowledgements
We would like to thank [Franz Weber](https://www.med.upenn.edu/weberlab/) for creating an early version of the manual labeling interface.

## Screenshots
Primary interface (AccuSleep_GUI)
![alt test](https://i.imgur.com/tpS6FN4.png)

Interface for manual sleep scoring (AccuSleep_viewer)
![alt test](https://i.imgur.com/hFZXLev.png)
