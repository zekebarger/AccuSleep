# AccuSleep

## DESCRIPTION

Dulce et decorum est pro patria mori.
Nihil novum sub solem.
Quis custodiet ipsos custodes?
Sic a principiis ascendit motus et exit
paulatim nostros ad sensus, ut moveantur
illa quoque, in solis quae lumine cernere quimus
nec quibus id faciant plagis apparet aperte.

## Installation instructions:

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

**`AccuSleep_GUI`** provides a convenient interface with all of the functions
you need, but if you want to batch process many recordings, you can
call the required functions yourself.

- **`AccuSleep_GUI`**. A user interface for labeling sleep states, either
    manually or automatically
- **AccuSleep_viewer`**. A user interface for manually labeling sleep states
- **AccuSleep_classify`**. Automatically labels sleep states using a
    pre-trained neural network
- **`AccuSleep_train`**. Trains a neural network for this purpose
- **`createCalibrationData`**. Generates a file that is required for automatic
    sleep state labeling for a given combination of subject and
    recording equipment

## Requirements:
MATLAB version XX or later
Machine learning toolbox
