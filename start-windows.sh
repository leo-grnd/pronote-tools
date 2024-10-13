# install necessary libraries
echo "Installing dependencies..."
pip install -q pycryptodome beautifulsoup4 requests autoslot tabulate pronotepy openpyxl pandas fpdf xlsxwriter

# Prompt the user for the Python file to execute and run it
read -p "Enter the Python file to execute (e.g., all-scripts/get_meals.py): " python_file
python3 "$python_file"