# 📚 pronote-tools
Additional tools for PRONOTE

## 📝 Description
`pronote-tools` is a project based on the `pronotepy` library. Its goal is to provide a better interface and additional functionalities for PRONOTE users. Features include a **Python console prompt** and **mobile notifications**, among others.

---

## 📖 Table of Contents
- [📋 Requirements](#-requirements)
- [⚙️ Installation and Basic Usage](#-installation-and-basic-usage)

---

## 📋 Requirements
To run most programs in this project, you'll need **Python 3** installed on your system.  
For easier setup, there are **.sh** files available for automated installation. Please follow the instructions carefully based on your operating system.

---

## ⚙️ Installation and Basic Usage
Follow these steps to set up and use the project:

### Step 1: Clone the Repository
```bash
git clone https://github.com/leoo84/pronote-tools.git
cd pronote-tools
```

### Step 2: Install Dependencies and Run Scripts
#### 🐧 For Linux Users
Run the `start-linux.sh` file for automated setup:
```bash
# Run start-linux.sh
./start-linux.sh
```
Simply enter the name of the Python file you want to execute when prompted.

#### 🪟 For Windows Users
Run the `setup-windows.py` file:
```bash
# Run setup-windows.py
python3 setup-windows.py
```

#### 🌐 For Other Operating Systems
Manually install the required dependencies and run your desired script:
```bash
# Install dependencies
pip install -q pycryptodome beautifulsoup4 requests autoslot tabulate pronotepy openpyxl pandas fpdf xlsxwriter

# Run a script
python [your-python-file]
```

---

Enjoy using `pronote-tools`! 🎉  
Feel free to contribute or raise issues if you encounter any problems. 🚀
```
