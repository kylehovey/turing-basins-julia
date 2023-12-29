#!/bin/bash

# Define the directory containing your images. Adjust this to your image directory path.
image_directory=$1
border_color="gray"
border_width=1

# Initiate the ImageMagick convert command
convert_cmd="convert"

# Create an array to hold the sorted list of image files
sorted_files=()
while IFS= read -r file; do
    sorted_files+=("$file")
done < <(find "$image_directory" -maxdepth 1 -type f -name '*_step_*.png' | sort -t '_' -k 3,3n)

# Check if there are any image files found
if [[ ${#sorted_files[@]} -eq 0 ]]; then
    echo "No image files found. Exiting."
    exit 1
fi

# Extract the base prefix from the first sorted file for the output filename.
# This strips away the numeric step part and the file extension, leaving the prefix.
base_prefix=$(basename "${sorted_files[0]}" | sed -E 's/(_step_)[0-9]+(\.png)$//')
output_image="${base_prefix}_concatenated.png"

# Loop over the sorted files and append them to ImageMagick command
for img in "${sorted_files[@]}"; do
    convert_cmd="$convert_cmd \( \"$img\" -bordercolor $border_color -border ${border_width}x0 \) +append"
done

# Append the final output file to the convert command
convert_cmd="$convert_cmd \"$image_directory/$output_image\""

# Execute the command
eval $convert_cmd

convert -append *_entropy_plot.png "$image_directory/$output_image" "$image_directory/$output_image"

for img in "${sorted_files[@]}"; do
    rm $img
done

echo "Concatenated image saved as '$image_directory/$output_image'"
