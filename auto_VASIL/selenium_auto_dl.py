from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import glob
import os
from itertools import combinations


# Path to your ChromeDriver
CHROME_DRIVER_PATH = "/usr/local/bin/chromedriver"

# URL of the form submission page
URL = "https://projects-raharinirina.pythonanywhere.com/vasil/FoldR_PNeut"


# Function to submit the form using Selenium
def submit_lineage_form_selenium(file1, file2):
    # Set up the Selenium WebDriver (Chrome in this case)
    driver = webdriver.Chrome(CHROME_DRIVER_PATH)

    # Open the website
    driver.get(URL)

    # Wait for the file input elements to be visible
    wait = WebDriverWait(driver, 10)

    # Upload the first file to "lineage1"
    lineage1_input = wait.until(EC.presence_of_element_located((By.NAME, "lineage1")))
    lineage1_input.send_keys(file1)

    # Upload the second file to "lineage2"
    lineage2_input = wait.until(EC.presence_of_element_located((By.NAME, "lineage2")))
    lineage2_input.send_keys(file2)

    # Find and click the submit button (RUN button)
    submit_button = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[@onclick='RUN(this);']")))
    submit_button.click()

    # Wait for the result and Data ID to appear
    data_id = None
    while not data_id:
        try:
            # Look for the Data ID in the div element with class "elem3a"
            elem = wait.until(EC.presence_of_element_located((By.CLASS_NAME, "elem3a")))
            header_text = elem.find_element(By.TAG_NAME, "h4").text
            if "Data ID:" in header_text:
                data_id = header_text.split("Data ID: ")[1].strip()
                print(f"Data ID found: {data_id}")
        except:
            print("Waiting for Data ID to be generated...")
            time.sleep(5)

    # Close the browser
    driver.quit()

    return data_id

# Main function to iterate over all unique combinations of files and collect Data IDs
def process_combinations(filepaths):
    data_ids = []
    # Iterate over unique combinations of files (ignoring order)
    for file1, file2 in combinations(filepaths, 2):
        # Submit the form and get the Data ID
        data_id = submit_lineage_form_selenium(file1, file2)
        if data_id:
            data_ids.append(data_id)

    return data_ids

# Example usage
if __name__ == "__main__":
    # dirpath of mutation profile data files from gisaid
    mutations_dirpath = "../downloads/"
    # List of filepaths to be submitted
    filepaths = glob.glob(os.path.join(mutations_dirpath, '*.txt'))

    # Submit the form using Selenium and get the Data ID
    data_ids = process_combinations(filepaths)

