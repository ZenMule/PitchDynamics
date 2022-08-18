# Copyright@ Miao Zhang, University at Buffalo, 2022.
# Feel free to use but please cite when you use it.


#######################################################################
#######################################################################


form Extract Pitch data from labelled intervals
   sentence Log_file_t _f0t
   sentence Log_file_dyn _f0d
   positive Numintervals 5
   positive Labeled_tier_number 2
   integer Syllable_tier_number 1
   integer Word_tier_number 0
   positive Analysis_points_time_step 0.005
   positive Record_with_precision 1
   comment F0 Settings:
   positive F0_minimum 70
   positive F0_maximum 350
   positive Octave_jump 0.10
   positive Voicing_threshold 0.65
   positive Pitch_window_threshold 0.05
endform


#######################################################################
#######################################################################

# Choose a directory
directory_name$ = chooseDirectory$: "Choose <SOUND> folder"

# Create header rows for both log files
fileappend 'directory_name$''log_file_t$'.txt File_name'tab$'Segment'tab$'t'tab$'t_m'tab$'F0'tab$'Int'newline$'
fileappend 'directory_name$''log_file_dyn$'.txt File_name'tab$'Segment'tab$'Dur'tab$'Syll_dur'tab$'Word_dur'tab$'F0_min'tab$'F0_min_loc'tab$'F0_max'tab$'F0_max_loc'tab$'F0_mgnt'tab$'F0_changerate'newline$'

# Create a list of all files in the target directory
Create Strings as file list: "fileList", directory_name$ + "/*.wav"
selectObject: "Strings fileList"
num_file = Get number of strings

# Open the soundfile in Praat
for i_file from 1 to num_file
	selectObject: "Strings fileList"
	file_name$ = Get string: i_file

	# Read sound file
	Read from file: directory_name$ + "/" + file_name$

	sound_file = selected("Sound")
	sound_name$ = selected$("Sound")

	# Read the corresponding TextGrid file into Praat
	Read from file: directory_name$ + "/" + sound_name$ + ".TextGrid"
	textGridID = selected("TextGrid")

	# Work through all labeled intervals on the target tier
	num_label = Get number of intervals: labeled_tier_number

	# Get durations
	for i_label from 1 to num_label
		# Select the textgrid file
		selectObject: textGridID

		# Get the name of the label
		label$ = Get label of interval: labeled_tier_number, i_label

		if label$ <> ""
			# When the label name is not empty, excecute the functions below
			# paste the file name and the interval label
			fileappend  'directory_name$''log_file_dyn$'.txt 'sound_name$''tab$'

			# Get the starting and end time point of the label,
			# and calculate the total duration
			label_start = Get start time of interval: labeled_tier_number, i_label
			label_end = Get end time of interval: labeled_tier_number, i_label
			dur = label_end - label_start

			# Paste the result
			fileappend 'directory_name$''log_file_dyn$'.txt 'label$''tab$''dur:3''tab$'

			# Find the middle point of the labeled interval
			anchor = label_start + dur/2

			# Find the interval on the labeled sylable tier
			if syllable_tier_number == 0
				# If there is no syllable tier, paste the syllable duration as NA
				fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'
			else
				i_syll_label = Get interval at time: syllable_tier_number, anchor

				# Get the duration of the syllable interval
				syll_start = Get start time of interval: syllable_tier_number, i_syll_label
				syll_end = Get end time of interval: syllable_tier_number, i_syll_label
				syll_dur = syll_end - syll_start
				# Paste the result
				fileappend 'directory_name$''log_file_dyn$'.txt 'syll_dur:3''tab$'
			endif

			if word_tier_number == 0
				# If there is no word tier, paste the word duration as NA
				fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'
			else
				# Find the interval on the labeled word tier
				i_word_label = Get interval at time: word_tier_number, anchor
				# Get the duration of the word interval
				word_start = Get start time of interval: word_tier_number, i_word_label
				word_end = Get end time of interval: word_tier_number, i_word_label
				word_dur = word_end - word_start
				# Paste the result
				fileappend 'directory_name$''log_file_dyn$'.txt 'word_dur:3''tab$'
			endif

			# Work on individual labeled intervals. Extract pitch and intensity object
			# Make sure the sound file is selected
			selectObject: sound_file

			# Get the boundaries of the target F0-obtaining interval
			pstart = label_start - pitch_window_threshold
			pend = label_end + pitch_window_threshold

			# Extract the sound part from the label
			Extract part: pstart, pend, "rectangular", 1, "yes"
			intv_ID = selected("Sound")

			if dur < 0.05
				# If the label is shorter than 50ms, paste NA in 't', 't_m', 'F0', and 'Int' columns in time log file
				fileappend 'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$'NA'tab$'NA'tab$'NA'tab$'NA'newline$'
				# And paste NA in dynamic log file for columns
				fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'NA'tab$'NA'tab$'NA'tab$'NA'tab$'NA'newline$'
			else
				# Extract the pitch object first
				selectObject: intv_ID
				To Pitch (ac): 0, f0_minimum, 15, "yes", 0.03, voicing_threshold, octave_jump, 0.35, 0.14, f0_maximum
				pitch_ID = selected("Pitch")

				# Extract the intensity object
				selectObject: intv_ID
				Filter (pass Hann band): 40, 4000, 100
				intv_ID_filt = selected("Sound")
				To Intensity: f0_minimum, 0, "yes"
				intensity_ID = selected("Intensity")

				# Overall pitch dynamic analysis
				# F0 minimum
				selectObject: pitch_ID
				f0_min = Get minimum: label_start, label_end, "Hertz", "parabolic"
				f0_min_time = Get time of minimum: label_start, label_end, "Hertz", "parabolic"
				f0_min_loc = (f0_min_time - label_start)/dur

				if f0_min = undefined
					# If f0 minima wasn't found, paste NA to F0_min and F0_minloc
					fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'NA'tab$'
				else
					# If yes, paste the value
					fileappend 'directory_name$''log_file_dyn$'.txt 'f0_min:2''tab$''f0_min_loc:2''tab$'
				endif

				# F0 maximum
				f0_max = Get maximum: label_start, label_end, "Hertz", "parabolic"
				f0_max_time = Get time of maximum: label_start, label_end, "Hertz", "parabolic"
				f0_max_loc = (f0_max_time - label_start)/dur

				if f0_max = undefined
					# If f0 maxima wasn't found, paste NA to F0_min and F0_minloc
					fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'NA'tab$'
				else
					## If yes, paste the value
					fileappend 'directory_name$''log_file_dyn$'.txt 'f0_max:2''tab$''f0_max_loc:2''tab$'
				endif

				# F0 dynamics

				if f0_max <> undefined and f0_min <> undefined
					if f0_max_time > f0_min_time
						f0_mgnt = f0_max - f0_min
						f0_transtime = f0_max_time - f0_min_time
						f0_changerate = f0_mgnt/f0_transtime
					else
						f0_mgnt = f0_min - f0_max
						f0_transtime = f0_min_time - f0_max_time
						f0_changerate = f0_mgnt/f0_transtime
					endif
					fileappend 'directory_name$''log_file_dyn$'.txt 'f0_mgnt:2''tab$''f0_changerate:2''newline$'
				else
					fileappend 'directory_name$''log_file_dyn$'.txt NA'tab$'NA'newline$'
				endif

				# Pitch and intensity by-time interval analysis
        
        		size = dur/numintervals
				for i_intv from 1 to numintervals
					# Get the start, end, and middle point of the interval
					intv_start = label_start + (i_intv-1) * size
					intv_end = label_start + i_intv * size
					intv_mid = intv_start + (intv_end - intv_start)/2 - label_start

					# Get the mean F0 of the time interval
					selectObject: pitch_ID
					f0_intv = Get mean: intv_start, intv_end, "Hertz"

					# Get the mean intensity of the time interval
					selectObject: intensity_ID
					intense_intv = Get mean: intv_start, intv_end, "dB"

					if f0_intv = undefined
						if intense_intv = undefined
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$'NA'tab$'NA'tab$'NA'tab$'NA'newline$'
						else
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$''i_intv''tab$''intv_mid:3''tab$'NA'tab$''intense_intv:2''newline$'
						endif
					else
						if intense_intv = undefined
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$''i_intv''tab$''intv_mid:3''tab$''f0_intv:2''tab$'NA'newline$'
						else
							fileappend  'directory_name$''log_file_t$'.txt 'sound_name$''tab$''label$''tab$''i_intv''tab$''intv_mid:3''tab$''f0_intv:2''tab$''intense_intv:2''newline$'
						endif
					endif
				endfor

				selectObject: pitch_ID, intensity_ID, intv_ID_filt, intv_ID
				Remove

			endif
		endif
	endfor

	selectObject: sound_file, textGridID
	Remove

endfor

select all
Remove