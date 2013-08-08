    [HDR, signal] = loadEDF(filename,channels)

     HDR = loadEDF(filename)`
        HDR is a struct containing .EDF file's header infromation 

     [HDR, signal] = loadEDF(filename,channels)`
       filename - string name identfiying European Data Format file to load.
       channels is a vector of the numeric signals to be loaded.  If left blank,
       then all of the channels in the EDF will be loaded.  

     [HDR, signal] = loadEDF(filename)`
      signals is cell array of numeric channel values for all recorded channels
      stored in the .EDF file filename.

<i>EDF+</i> format is not supported by loadEDF

Examples:
You will need to download the sleep study (*.EDF), the accompanying scored 
data file (.SCO), and the Matlab script to load them (.m).

To get the data use the following commands

<pre>[hdr] = loadEDF('A0210_3 170424.EDF')</pre>


<i>hdr</i> is a struct containing all of the header data found in the EDF file 
(type `hdr` to see its fields).

<i>hdr.label</i> contains the labels for each channel.  If you type hdr.label at 
the matlab prompt you will see

<pre>
>>hdr.label
  ans =

    LOC-M2
    ROC-M1
    C3-M2
    O1-M2
    Chin EMG
    LAT/RAT
    Snore
    ECG
    Nasal/OralTherm
    Nasal/OralTherm
    NasalPres
    Chest
    Abd
    RIP-Sum
    Position
    SaO2
</pre>

The C3-M2 is the central EEG channel and O1-M2 is the occipital eeg.  LOC-M2 
and ROC-M1 are the left and right EOG (eye) channels.

To load channels as a vector form, you type

`[hdr, signal] = loadEDF('A0210_3 170424.EDF',[1,2,3,8]);`

The vector [1,2,4,8] tells the function to load the channels at these 
indices which are
1 LOC-M2
2 ROC-M1
3 C3-M2
8 ECG

The are then stored in numerical order in the cell variable signal

* `signal{1}` is vector of LOC-M2 samples
* `signal{2}` is ROC-M1 samples
* `signal{3}` is C3-M2
* `signal{4}` is ECG

The data is sampled at 100 samples per second, and the stage vector found in 
the .SCO file corresponds to 30 second consecutive epochs.
This equates to 3000 samples per epoch or numeric stage value per row entry 
in the .SCO file.

Scores are interpreted as follows:
* 0 = awake
* 1-4 non-rem sleep stages (stages 1 through 4)
* 5 = REM sleep (stage 5)
* 7 = unknown, problematic epoch.
