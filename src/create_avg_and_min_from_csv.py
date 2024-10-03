import os
import pandas as pd
import numpy as np

def compute_avg_and_min_matirces_from_csv_dir(directory_path, output_min_file, output_avg_file):
    # List all CSV files in the directory
    csv_files = [f for f in os.listdir(directory_path) if f.endswith('.csv')]

    # Initialize variables
    min_matrix = None
    sum_matrix = None
    count_matrix = None  # for average calculation

    for file in csv_files:
        file_path = os.path.join(directory_path, file)
        df = pd.read_csv(file_path, index_col=0)

        # Replace NaN
        df_filled_min = df.fillna(np.inf)  # infinity for min comparison
        df_filled_sum = df.fillna(0)  # zero for sum/avg calculation

        # If it's the first file, initialize the matrices for output
        if min_matrix is None:
            min_matrix = df_filled_min.copy()
            sum_matrix = df_filled_sum.copy()
            count_matrix = df.notna().astype(int)
        else:
            # Update the min matrix using element-wise comparison
            min_matrix = pd.DataFrame(
                data=np.minimum(min_matrix.values, df_filled_min.values),
                index=min_matrix.index, columns=min_matrix.columns
            )
            # Update the sum and count matrices for average calculation
            sum_matrix += df_filled_sum
            count_matrix += df.notna().astype(int)

    # Calculate the average matrix
    avg_matrix = sum_matrix.div(count_matrix.replace(0, np.nan))  # make sure no divide by 0 possible

    min_matrix.replace(np.inf, np.nan).to_csv(output_min_file)  # Replace inf back with NaN in min_matrix for output
    avg_matrix.to_csv(output_avg_file)

    print(f"Minimum matrix saved to {output_min_file}")
    print(f"Average matrix saved to {output_avg_file}")

directory_path = "."
output_min_file = "merged_min_values.csv"
output_avg_file = "merged_average_values.csv"

compute_avg_and_min_matirces_from_csv_dir(directory_path, output_min_file, output_avg_file)