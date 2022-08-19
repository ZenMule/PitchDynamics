# PitchDynamics
This Praat script extracts pitch from labeled tiers. It is modified based on Christian DiCanio's pitch_dynamics script.

## What does the script do?
The script extract f0 (Hz) and intensity (dB) from labeled intervals in all sound files in a directory.

## How to use?
You have to have your sound files in .wav format and textgrid files ready. 

Open the script and change some settings. In the initial form, you will be asked to input the numbers of the labeled tier, the syllable tier, and the word tier, and how many chunks you'd like to split each labeled interval in.

You also need to change the f0 range for different speakers. I usually use 100-500Hz for female speakers and 70-350 for male speakers.

## What do you get?
It outputs two log files. One logs the f0 and intensity values from several equidistant chunks from labeled intervals. The other one logs the duration of the interval, the minima and maxima of f0, the locations of the minima and maxima of f0, the maximum f0 change and its average rate of change.

The log files are logged in long format, which reduces the load of data wrangling and is more ready for further data analysis.
