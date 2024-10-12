# Setup Python virtual environment and install necessary libraries
python3 -m venv venv
source venv/bin/activate
echo "Installing dependencies..."
pip install -q pycryptodome beautifulsoup4 requests autoslot pronotepy

# Prompt the user for the Python file to execute and run it
read -p "Enter the Python file to execute (e.g., all-scripts/get_meals.py): " python_file
python3 "$python_file"