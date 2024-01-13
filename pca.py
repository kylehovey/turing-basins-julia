import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from environment import data_directory, params
import plotly.graph_objects as go
from plotly.subplots import make_subplots
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
ax[0].set_title(f'Explained Variance by Principal Components - P(life)={params["threshhold"]}')
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

def save_surface_plot_grid(pca, nrows, ncols, output_dir):
    y = np.linspace(0, 1, nrows)  # We assume the y-axis ranges from 0 to 1
    y_percentages = list(reversed(["{:.2f}%".format(100 * yi) for yi in y]))
    x = np.linspace(1, ncols, ncols)
    X, Y = np.meshgrid(x, y)
    
    # Define the number of rows and columns for the subplot grid
    grid_rows = 3
    grid_cols = 3
    subplot_titles = [f"PC {i+1}" for i in range(grid_rows * grid_cols)]

    # Initialize subplots
    fig = make_subplots(
        rows=grid_rows, cols=grid_cols,
        specs=[[{'type': 'surface'}] * grid_cols] * grid_rows,  # All plots are of type 'surface'
        subplot_titles=subplot_titles,
        vertical_spacing=0.02,
        horizontal_spacing=0.02,
    )

    # Populate the subplots with surface plots of PCA components
    for i in range(grid_rows * grid_cols):
        pc_reshaped = pca.components_[i].reshape((nrows, ncols))
        Z = pc_reshaped

        row = (i // grid_cols) + 1
        col = (i % grid_cols) + 1

        fig.add_trace(
            go.Surface(z=Z, x=X, y=Y, showscale=False, name=f"PC {i+1}"),
            row=row, col=col
        )

    # Update layout and camera for all subplots
    for i in range(1, grid_rows * grid_cols + 1):
        fig.update_scenes(
            xaxis_title="Principal Component Index",
            yaxis=dict(
                title="Initial Probability of Life",
                tickvals=y,
                ticktext=y_percentages
            ),
            zaxis_title="Z Value",
            camera=dict(
                eye=dict(x=1.5, y=1.5, z=2)
            ),
            row=(i - 1) // grid_cols + 1, col=(i - 1) % grid_cols + 1
        )

    # Update the layout for the entire figure with reduced margins and increased font size
    fig.update_layout(
        title_text="<b>Principal Component Surface Plots</b>",  # Bold main title
        title_font_size=24,
        autosize=True,
        width=900 * grid_cols,
        height=800 * grid_rows,
        margin=dict(l=40, r=40, b=40, t=90)
    )

    # Save the plot as a PNG file
    png_filename = os.path.join(output_dir, "PCA_surface_plot_grid.png")
    fig.write_image(png_filename)
    print(f"Surface plot grid saved as '{png_filename}'.")

    # Save individual surface plots for each principal component
    for i in range(grid_rows * grid_cols):
        pc_reshaped = pca.components_[i].reshape((nrows, ncols))
        single_fig = go.Figure(data=[go.Surface(z=pc_reshaped, x=X, y=Y, showscale=False)])
        single_fig.update_layout(
            title=f"Principal Component {i+1}",
            scene=dict(
                xaxis_title="Principal Component Index",
                yaxis=dict(
                    title="Initial Probability of Life",
                    tickvals=y,
                    ticktext=y_percentages
                ),
                zaxis_title="Z Value",
                camera=dict(eye=dict(x=1.5, y=1.5, z=1.5)),
                aspectratio=dict(x=1, y=1, z=1),
            ),
            autosize=True,
            width=700,
            height=700,
            margin=dict(l=40, r=40, b=40, t=90)
        )
        
        # Save the individual principal component plot as a PNG file
        pc_png_filename = os.path.join(output_dir, f"PC_{i+1}_surface_plot.png")
        single_fig.write_image(pc_png_filename)
        print(f"Individual surface plot saved as '{pc_png_filename}'.")

if params['n_initial_conditions'] > 1:
    save_surface_plot_grid(pca, nrows=params['n_initial_conditions'], ncols=params['steps'], output_dir=data_directory)
