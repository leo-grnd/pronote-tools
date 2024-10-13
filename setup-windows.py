import pip
import subprocess

# Install necessary libraries
print("Installing dependencies...")
pip.main(['install', 'pycryptodome', 'beautifulsoup4', 'requests', 'autoslot', 'tabulate', 'pronotepy', 'openpyxl', 'pandas', 'fpdf', 'xlsxwriter'])

# Prompt the user for the Python file to execute and run it
python_file = input("Enter the Python file to execute (e.g., all-scripts/get_meals.py): ")

# Execute the specified Python file
subprocess.run(['python3', python_file])