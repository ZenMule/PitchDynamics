# Modified by Miao Zhang based on Christian DiCanio's Pitch_Dynamics_6.2.praat
# For details of the previous versions, please refer to Christian's original script.
# Feel free to use but please cite when you use it.

# Last updated by Miao Zhang, 11/09/2023.

# Major modifications include:
# 1. Changed the log file format from wide format to long format.
# 2. Outputs two separate log files: 
# 		one with the f0 and intensity values from each equidistant interval, 
#		and the other one with the f0 maxima and minima.
# 3. Changed to the new Praat syntax to improve code-readability.

# Folder version:
# The script loops through all subfolders in the directory you choose.
# The script sets F0 analysis ranges for different genders. 
# Each of your subfolders should contain recordings from only one speaker.

# !!!IMPORTANT!!!
# Please format your folder names as: (f/F/m/M)(id_number)_***.
# For example: f1_SC, m1_TC, F2_KW, or M2_AP.
# This is for the script to identify the gender of the speaker.


#######################################################################
#######################################################################


form Extract Pitch data from labelled intervals
	comment Suffix of the output files:
	sentence Log_file_f0 _f0
	sentence Log_file_dur _dur
	comment Labels you want the script to skip (separate by white space):
	sentence Skip_list c
	comment How many F0 values do you want to extract from each labeled interval
	positive Number_of_chunks 10
	comment On which tier are the target intervals labeled?:
	positive Labeled_tier_number 2
	comment Set the next two tier numbers to 0 if you don't have syllable/word tiers:
	integer Syllable_tier_number 1
	integer Word_tier_number 0
	comment Pitch analysis settings:
	positive Analysis_points_time_step 0.005
	positive Record_with_precision 1
	positive Octave_jump 0.10
	positive Voicing_threshold 0.65
	positive Pitch_window_threshold 0.05
	comment Set the F0 analysis range for different genders:
	positive F0_minimum_for_female 100
	positive F0_maximum_for_female 600
	positive F0_minimum_for_male 70
	positive F0_maximum_for_male 400

endform


#######################################################################
#######################################################################

# Choose a directory
pauseScript: "Choose the folder that contains subfolders of your sound and textgrid files."
directory_name$ = chooseDirectory$: "Choose <SOUND> folder"

# measure run time
stopwatch

# Create header rows for both log files
# Time log
sep$ = ","

output_file_t$ = directory_name$ + log_file_f0$ + ".csv"
deleteFile: output_file_t$
header_t$ = "Folder_name" + sep$
	...+ "File_name" + sep$
	...+ "Seg_num" + sep$
  	...+ "Seg" + sep$
  	...+ "t" + sep$
  	...+ "t_m" + sep$
  	...+ "F0" + sep$
  	...+ "Int" 
writeFileLine: output_file_t$, header_t$

# Dynamic log
output_file_dyn$ = directory_name$ + log_file_dur$ + ".csv"
deleteFile: output_file_dyn$
header_dyn$ = "Folder_name" + sep$
  ...+ "File_name" + sep$
  ...+ "Seg_num" + sep$
  ...+ "Seg" + sep$
  ...+ "Dur" + sep$
  ...+ "Syll_dur" + sep$
  ...+ "Word_dur"
writeFileLine: output_file_dyn$, header_dyn$

# Skip labels
skip_labels$# = splitByWhitespace$# (skip_list$)

# Create a list of all folders in the target directory
folderNames$# = folderNames$# (directory_name$)
for i_folder from 1 to size(folderNames$#)
	folder_name$ = folderNames$# [i_folder]
	# Seg F0 minimum and maximum for different genders
	findex = index_regex (folder_name$, "f|F\d+")
	mindex = index_regex (folder_name$, "m|M\d+")
	if findex <> 0
		f0_minimum = f0_minimum_for_female
		f0_maximum = f0_maximum_for_female
	elsif mindex <> 0
		f0_minimum = f0_minimum_for_male
		f0_maximum = f0_maximum_for_male
	endif

	# Create a list of all files in the target directory
	wavNames$# = fileNames$# (directory_name$ + "/" + folder_name$ + "/*.wav")
	num_file = size (wavNames$#)

	# Open the soundfile in Praat
	for i_file from 1 to num_file
		wav_name$ = wavNames$# [i_file]
		writeInfoLine: "Processing folder: < 'folder_name$' >."
		appendInfoLine: "Current F0 analysis range is <'f0_minimum', 'f0_maximum'>Hz."
		appendInfoLine: "	Current file: < 'wav_name$' >"
		# Read sound file
		sound_file = Read from file: directory_name$ + "/" + folder_name$ + "/" + wav_name$
		sound_name$ = wav_name$ - ".wav"

		# Read the corresponding TextGrid file into Praat
		textgrid_file = Read from file: directory_name$ + "/" + folder_name$ + "/" + sound_name$ + ".TextGrid"

		# Work through all labeled intervals on the target tier
		num_label = Get number of intervals: labeled_tier_number

		# Get durations
		for i_label from 1 to num_label
			# Select the textgrid file
			selectObject: textgrid_file

			# Get the name of the label
			label$ = Get label of interval: labeled_tier_number, i_label
			label$ = replace_regex$ (label$, "[\s]+", "", 0)

			if label$ <> "" and index (skip_labels$#, label$) = 0
				# When the label name is not empty, excecute the functions below
				# paste the file name and the interval label
				appendFile: output_file_dyn$, folder_name$ + sep$ + sound_name$ + sep$

				# Get the starting and end time point of the label,
				# and calculate the total duration
				label_start = Get start time of interval: labeled_tier_number, i_label
				label_end = Get end time of interval: labeled_tier_number, i_label
				# Get the duration of the label
				dur = label_end - label_start
				# Find the middle point of the labeled interval
				label_mid = label_start + dur/2

			
				# Paste the result
				appendFile: output_file_dyn$, "'i_label'" + sep$ + label$ + sep$ + "'dur:3'" + sep$

				# Find the interval on the labeled sylable tier
				if syllable_tier_number = 0
					# If there is no syllable tier, paste the syllable duration as NA
					appendFile: output_file_dyn$, "NA" + sep$
				else
					i_syll_label = Get interval at time: syllable_tier_number, label_mid
					syll_label$ = Get label of interval: syllable_tier_number, i_syll_label

					if syll_label$ == ""
						appendFile: output_file_dyn$, "NA" + sep$
					else
						# Get the duration of the syllable interval
						syll_start = Get start time of interval: syllable_tier_number, i_syll_label
						syll_end = Get end time of interval: syllable_tier_number, i_syll_label
						syll_dur = syll_end - syll_start
						# Paste the result
						appendFile: output_file_dyn$, "'syll_dur:3'" + sep$
					endif
					
				endif

				if word_tier_number = 0
					# If there is no word tier, paste the word duration as NA
					appendFileLine: output_file_dyn$, "NA"
				else
					# Find the interval on the labeled word tier
					i_word_label = Get interval at time: word_tier_number, label_mid
					# Get the duration of the word interval
					word_start = Get start time of interval: word_tier_number, i_word_label
					word_end = Get end time of interval: word_tier_number, i_word_label
					word_dur = word_end - word_start
					# Paste the result
					appendFileLine: output_file_dyn$, "'word_dur:3'"
				endif

				# Work on individual labeled intervals. Extract pitch and intensity object
				# Make sure the sound file is selected
				selectObject: sound_file

				# Get the boundaries of the target F0-obtaining interval
				pstart = label_start - pitch_window_threshold
				pend = label_end + pitch_window_threshold

				# Extract the sound part from the label
				intv_ID = Extract part: pstart, pend, "rectangular", 1, "yes"

				# Only extract f0 from segments that are longer than 50ms
				# Extract the pitch object first
				selectObject: intv_ID
				pitch_ID = To Pitch (ac): 0, f0_minimum, 15, "yes", 0.03, voicing_threshold, octave_jump, 0.35, 0.14, f0_maximum


				# Extract the intensity object
				selectObject: intv_ID
				intv_ID_filt = Filter (pass Hann band): 40, 4000, 100
				selectObject: intv_ID
				intensity_ID = To Intensity: f0_minimum, 0, "yes"

				# Overall pitch dynamic analysis
				# F0 minimum
				selectObject: pitch_ID

				# Pitch and intensity by-time interval analysis
				if dur >= 0.05
					chunk_length = dur/number_of_chunks
					for i_intv from 1 to number_of_chunks
						# Get the start, end, and middle point of the interval
						intv_start = label_start + (i_intv-1) * chunk_length
						intv_end = label_start + i_intv * chunk_length
						intv_mid = intv_start + (intv_end - intv_start)/2 - label_start

						# Get the mean F0 of the time interval
						selectObject: pitch_ID
						f0_intv = Get mean: intv_start, intv_end, "Hertz"
						if f0_intv = undefined
							f0_intv = 0
						endif

						# Get the mean intensity of the time interval
						selectObject: intensity_ID
						intense_intv = Get mean: intv_start, intv_end, "dB"
						if intense_intv = undefined
							intense_intv = 0
						endif

						appendFileLine: output_file_t$, folder_name$ + sep$
									...+ sound_name$ + sep$
									...+ "'i_label'" + sep$
									...+ label$ + sep$
									...+ "'i_intv'" + sep$
									...+ "'intv_mid:3'" + sep$
									...+ "'f0_intv:0'" + sep$
									...+ "'intense_intv:0'"
					endfor
				endif
				removeObject: intv_ID, pitch_ID, intensity_ID, intv_ID_filt
			endif
		endfor
		removeObject: sound_file, textgrid_file
	endfor
endfor

runtime = stopwatch
runtime = round(runtime)
if runtime < 60
	if runtime < 10
		appendInfoLine: "Total run time was 00:00:0'runtime'"
	else 
		appendInfoLine: "Total run time was 00:00:'runtime'"
	endif
elsif runtime < 3600
	minute = runtime div 60
	second = runtime mod 60
	if minute < 10
		appendInfo: "The total run time was 00:0'minute':"
	else 
		appendInfo: "The total run time was 00:'minute':"
	endif
	if second < 10
		appendInfoLine: "0'second'"
	else 
		appendInfoLine: "'second'"
	endif
else
	hour = runtime div 3600
	rest = runtime mod 3600
	minute = rest div 60
	second = rest mod 60
	if hour < 10
		appendInfo: "The total run time was 0'hour':"
	else
		appendInfo: "The total run time was 'hour':"
	endif
	if minute < 10
		appendInfo: "0'minute':"
	else 
		appendInfo: "'minute':"
	endif
	if second < 10
		appendInfoLine: "0'second'"
	else 
		appendInfoLine: "'second'"
	endif
endif