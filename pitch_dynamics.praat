# Modified by Miao Zhang based on Christian DiCanio's Pitch_Dynamics_6.2.praat
# For details of the previous versions, please refer to Christian's original script.
# Feel free to use but please cite when you use it.

# Last updated by Miao Zhang, 10/8/2022.

# Major modifications include:
# 1. Changed the log file format from wide format to long format.
# 2. Outputs two separate log files: 
# 		one with the f0 and intensity values from each equidistant interval, 
#		and the other one with the f0 maxima and minima.
# 3. Changed to the new Praat syntax to improve code-readability.


#######################################################################
#######################################################################


form Extract Pitch data from labelled intervals
	comment Suffix of the output file:
	sentence Log_file_t _f0t
	sentence Log_file_dyn _f0d
	comment Labels you want the script to skip (separate by white space):
	sentence Skip_list c
	comment How many F0 values do you want to extract from each segment
	positive Number_of_chunks 10
	comment Which tier are the target segments on?:
	positive Labeled_tier_number 2
	comment Set the next two tier numbers to 0 if you don't have syllable/word tier:
	integer Syllable_tier_number 1
	integer Word_tier_number 0
	comment Pitch analysis settings:
	positive Analysis_points_time_step 0.005
	positive Record_with_precision 1
	positive F0_minimum 50
	positive F0_maximum 700
	positive Octave_jump 0.10
	positive Voicing_threshold 0.65
	positive Pitch_window_threshold 0.05
endform


#######################################################################
#######################################################################

# Choose a directory
pauseScript: "Choose the directory that contains subfolders of your sound and textgrid files."
directory_name$ = chooseDirectory$: "Choose <SOUND> folder"

# Create header rows for both log files
# Time log
sep$ = ","
output_file_t$ = directory_name$ + log_file_t$ + ".csv"
deleteFile: output_file_t$
header_t$ = "File_name" + sep$
	...+ "Seg_num" + sep$
  	...+ "Seg" + sep$
  	...+ "t" + sep$
  	...+ "t_m" + sep$
  	...+ "F0" + sep$
  	...+ "Int" 
writeFileLine: output_file_t$, header_t$

# Dynamic log
output_file_dyn$ = directory_name$ + log_file_dyn$ + ".csv"
deleteFile: output_file_dyn$
header_dyn$ = "File_name" + sep$
  ...+ "Seg_num" + sep$
  ...+ "Seg" + sep$
  ...+ "Dur" + sep$
  ...+ "Syll_dur" + sep$
  ...+ "Word_dur" + sep$
  ...+ "F0_min" + sep$
  ...+ "F0_min_loc" + sep$
  ...+ "F0_max" + sep$
  ...+ "F0_max_loc" 
writeFileLine: output_file_dyn$, header_dyn$

# Skip labels
skip_labels$# = splitByWhitespace$# (skip_list$)

# Create a list of all files in the target directory
wavNames$# = fileNames$# (directory_name$ + "/*.wav")
num_file = size (wavNames$#)

# Open the soundfile in Praat
for i_file from 1 to num_file
	wav_name$ = wavNames$# [i_file]

	# Read sound file
	sound_file = Read from file: directory_name$ + "/" + wav_name$
	sound_name$ = wav_name$ - ".wav"

	# Read the corresponding TextGrid file into Praat
	textgrid_file = Read from file: directory_name$ + "/" + sound_name$ + ".TextGrid"

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
			appendFile: output_file_dyn$, sound_name$ + sep$

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

				# Get the duration of the syllable interval
				syll_start = Get start time of interval: syllable_tier_number, i_syll_label
				syll_end = Get end time of interval: syllable_tier_number, i_syll_label
				syll_dur = syll_end - syll_start
				# Paste the result
				appendFile: output_file_dyn$, "'syll_dur:3'" + sep$
			endif

			if word_tier_number = 0
				# If there is no word tier, paste the word duration as NA
				appendFile: output_file_dyn$, "NA" + sep$
			else
				# Find the interval on the labeled word tier
				i_word_label = Get interval at time: word_tier_number, label_mid
				# Get the duration of the word interval
				word_start = Get start time of interval: word_tier_number, i_word_label
				word_end = Get end time of interval: word_tier_number, i_word_label
				word_dur = word_end - word_start
				# Paste the result
				appendFile: output_file_dyn$, "'word_dur:3'" + sep$
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
			f0_min = Get minimum: label_start, label_end, "Hertz", "parabolic"
			f0_min_time = Get time of minimum: label_start, label_end, "Hertz", "parabolic"
			f0_min_loc = (f0_min_time - label_start)/dur

			if f0_min = undefined
				# If f0 minima wasn't found, paste NA to F0_min and F0_minloc
				appendFile: output_file_dyn$, "NA" + sep$ + "NA" + sep$
			else
				# If yes, paste the value
				appendFile: output_file_dyn$, "'f0_min:0'" + sep$ + percent$(f0_min_loc,0) + sep$
			endif

			# F0 maximum
			f0_max = Get maximum: label_start, label_end, "Hertz", "parabolic"
			f0_max_time = Get time of maximum: label_start, label_end, "Hertz", "parabolic"
			f0_max_loc = (f0_max_time - label_start)/dur

			if f0_max = undefined
				# If f0 maxima wasn't found, paste NA to F0_min and F0_minloc
				appendFileLine: output_file_dyn$, "NA" + sep$ + "NA"
			else
				## If yes, paste the value
				appendFileLine: output_file_dyn$, "'f0_max:0'" + sep$ + percent$(f0_max_loc,0)
			endif

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

					appendFileLine: output_file_t$, sound_name$ + sep$
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