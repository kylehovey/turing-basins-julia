from dotenv import dotenv_values
import re

config = dotenv_values(".env")

data_directory = config["DATA_DIR"]

# Extend the regex pattern to match either dthresh or threshhold
params_pattern = r"steps-(?P<steps>\d+)_size-(?P<size>\d+)(?:_dthresh-(?P<dthresh>[0-9.]+)|_threshhold-(?P<threshhold>[0-9.]+))_averages-(?P<averages>\d+)"
match = re.search(params_pattern, data_directory)

# If the pattern matches, create the params dictionary
if match:
    params = match.groupdict()
    
    # Convert values to appropriate types and handle n_initial_conditions
    for key in params:
        if params[key] and key in ["steps", "size", "averages"]:
            params[key] = int(params[key])
        elif params[key] and key in ["dthresh", "threshhold"]:
            params[key] = float(params[key])

    if 'dthresh' in params and params['dthresh'] is not None:
        params['n_initial_conditions'] = round(1/params['dthresh']) + 1
    elif 'threshhold' in params and params['threshhold'] is not None:
        params['n_initial_conditions'] = 1  # Change n_initial_conditions if threshhold is present
    else:
        raise ValueError("Neither dthresh nor threshhold were found in the data directory.")
else:
    raise ValueError("The data directory does not contain the required parameters in the expected format.")
