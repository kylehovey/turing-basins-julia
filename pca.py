import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from environment import data_directory, params
import plotly.graph_objects as go
import os

'''
Use this file for generating PCA charts treating dataset as 1D vectors. For
varied initial condition data, the slices will be concatenated into a single
vector and you will see the slices in the PCA's that are found. To get a better
representation, this script will generate surface plots of the PCA's for varied
initial conditions.
'''

print("Loading data...")
data = np.load(f'{data_directory}/data.npy')
print(f"Loaded data of shape {data.shape}")

(_, n_components) = np.shape(data)

# If we use more than 100 components PCA begins to diverge as matrix
# stability decreases. I've never seen the variance be that significant
# past the first 50 dimensions for any dataset I've generated, so this
# is likely fine. We only chart the first few principal components anyways.
n_components = min(100, n_components)

pca = PCA(n_components=n_components)
pca.fit(data)

# Create a subplot grid of 2 rows and 1 column
fig, ax = plt.subplots(2, 1, figsize=(12, 12))  # Adjust the figure size as needed

# First subplot for explained variance
ax[0].plot(pca.explained_variance_, label='Explained Variance', color='blue')
ax[0].set_yscale('log')
ax[0].set_xlabel('Principal Component Index')
ax[0].set_ylabel('Explained Variance (log scale)')
ax[0].set_title('Explained Variance by Principal Components')
ax[0].legend()

# Enable horizontal grid lines for the first subplot
ax[0].grid(True, which='both', axis='y', linewidth=0.5, color='gray')

# Change this to adjust how many principal components
# we want to chart.
pca_display_count = 5

# Create a plotting color map
colors = plt.cm.hsv(np.linspace(0.3, 1, pca_display_count))

# Define line styles for principal components
line_styles = ['-', '--', '-.', ':', (0, (3, 5, 1, 5))]

# Second subplot for the first few principal component vectors
for i in range(pca_display_count):
    ax[1].plot(pca.components_[i], label=f'PC {i+1}', color=colors[i], linestyle=line_styles[i])
ax[1].set_xlabel('Principal Component Index')
ax[1].set_ylabel('Principal Component Value')
ax[1].set_title(f'First {pca_display_count} Principal Components')

# Create a custom legend for the second subplot with line styles
custom_lines = [plt.Line2D([0], [0], color=colors[i], linestyle=line_styles[i], lw=2) for i in range(pca_display_count)]
ax[1].legend(custom_lines, [f'PC {i+1}' for i in range(pca_display_count)], loc='upper right', bbox_to_anchor=(1.1, 1))

# Adjust layout to prevent the subplots from overlapping
plt.tight_layout()

# Display the plots
plt.savefig(f"{data_directory}/pca.png")

def save_surface_plots(pca, pca_display_count, nrows, ncols, output_dir):
    y = np.linspace(0, 1, nrows)  # We assume the y-axis ranges from 0 to 1
    # Calculate percentages for y-axis scale
    y_percentages = ["{:.2f}%".format(100 * yi) for yi in y]
    x = np.linspace(1, ncols, ncols)
    X, Y = np.meshgrid(x, y)

    for i in range(pca_display_count):
        pc_reshaped = pca.components_[i].reshape((nrows, ncols))
        Z = pc_reshaped
        
        fig = go.Figure(data=[go.Surface(z=Z, x=X, y=Y)])
        
        fig.update_layout(
            title=f"PC {i+1} - Surface Plot",
            autosize=True,
            width=1000,
            height=1000,
            scene=dict(
                xaxis=dict(
                    title="Principal Component Index",
                ),
                yaxis=dict(
                    title="Initial Probability of Life",
                    tickvals=y,
                    ticktext=y_percentages
                ),
                zaxis=dict(
                    title="Z Value",
                ),
                camera=dict(
                    eye=dict(x=2, y=2, z=2)  # Adjust the camera's eye position
                ),
                aspectratio=dict(x=1, y=1, z=1),  # Keep the aspect ratio square
            ),
            margin=dict(l=40, r=40, b=40, t=90)
        )

        # Save the plot as a PNG file
        png_filename = os.path.join(output_dir, f"PC_{i+1}_surface_plot.png")
        fig.write_image(png_filename)
        print(f"Surface plot saved as '{png_filename}'.")

if params['n_initial_conditions'] > 1:
    dthresh = 1.0 / (params['n_initial_conditions'] - 1)  # adjust based on your data
    save_surface_plots(
        pca,
        pca_display_count,
        nrows=params['n_initial_conditions'],
        ncols=params['steps'],
        output_dir=data_directory,
    )
