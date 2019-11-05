# AccuSleep

## Updates
**10/30/2019** - The primary user interface has received a major update, and now
    allows all recordings from one subject to be processed simultaneously. A 
    small bug was also fixed, the user manual was updated, and error messages 
    should be more helpful. **Please replace any older versions of AccuSleep with this one.**

## Description

AccuSleep is a set of graphical user interfaces for scoring rodent
sleep using EEG and EMG recordings. To learn more about the algorithms used
by this software, please see our preprint at https://www.biorxiv.org/content/10.1101/813345v2

Please contact zeke (at) berkeley (dot) edu with any questions or comments about the software.

## Installation instructions

Save the MATLAB package somewhere on your computer, then add it
to your MATLAB path. You can do this in the MATLAB "Current Folder"
window by right-clicking the AccuSleep folder, clicking "Add to Path"
--> "Selected Folders and Subfolders", then running the command
`savepath`
in the Command Window.

To get started, run `AccuSleep_GUI` and click the Help button, or run
`doc AccuSleep_instructions`
for a full explanation of these functions and the types of input
they require.

**`AccuSleep_GUI`** provides an interface for most of the functions
in this package, but if you want to batch process recordings from multiple subjects, you can
call the required functions yourself.

To download the data used for training and testing AccuSleep, please visit
https://osf.io/py5eb/

## Functions

- **`AccuSleep_GUI`**. A user interface for labeling sleep states, either
    manually or automatically
- **`AccuSleep_viewer`**. A user interface for manually labeling sleep states
- **`AccuSleep_classify`**. Automatically labels sleep states using a
    pre-trained neural network
- **`AccuSleep_train`**. Trains a neural network for labeling sleep states
- **`createCalibrationData`**. Generates a file that is required for automatic
    sleep state labeling for a given combination of subject and
    recording equipment

## Requirements
- MATLAB version 2016b or later
- Statistics and Machine Learning Toolbox

## Tips & Troubleshooting
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
- Please contact zeke (at) berkeley (dot) edu if you find any other issues.

## Screenshots
![alt test](https://i.imgur.com/zeoqlfP.png)
Primary interface (AccuSleep_GUI)

![alt test](https://i.imgur.com/hFZXLev.png)
Interface for manual sleep scoring (AccuSleep_viewer)

## Acknowledgements
We would like to thank Franz Weber for creating an early version of the manual labeling interface.
