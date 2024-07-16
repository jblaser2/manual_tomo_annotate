#!/bin/sh

# go to scritps directory
script_dir="$HOME/manual_tomo_annotate/scripts"
cd "$script_dir"

# initialize variables
dataset_id=""
run_id=""
output_dir="$HOME/segmentation_data/annotations"

# Parse command line arguments
while getopts ":d:r:" opt; do
  case $opt in
    d) dataset_id=$OPTARG ;;
    r) run_id=$OPTARG ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Check if both -d (dataset_id) and -r (run_id) were provided
if [ -z "$dataset_id" ] || [ -z "$run_id" ]; then
    echo "Usage: $0 -d <dataset_id> -r <run_id>"
    exit 1
fi

# download the tomogram
echo "Downloading tomogram..."
python "auto_tomo_download.py" "$dataset_id" "$run_id"

target_file="$HOME/segmentation_data/raw_tomograms/dataset_${dataset_id}/run_${run_id}.mrc"

# go back to the scripts directory
cd "$script_dir"

# Run the conversion script )
echo "Running mrc_to_mha.py to convert $target_file..."
python "mrc_to_mha.py" "$target_file" "$dataset_id"

# Check if the conversion was successful
if [ $? -ne 0 ]; then
    echo "Error: mrc_to_mha.py failed to convert $target_file."
    exit 1
fi

# Determine the output file path
output_file="$output_dir/$(basename "${target_file%.*}.mha")"

# Open the output file with itksnap
echo "Opening $output_file with itksnap..."
itksnap "$output_file"

# Check if itksnap was successful
if [ $? -ne 0 ]; then
    echo "Error: itksnap failed to open $output_file."
    exit 1
fi

echo "Process completed successfully."