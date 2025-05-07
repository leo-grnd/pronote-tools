import datetime
import os
import pronotepy
import configparser
import getpass
from tabulate import tabulate
import json
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.ticker import MaxNLocator
import matplotlib.dates as mdates
from datetime import datetime as dt
from collections import defaultdict
from pronotepy.ent import (
    cas_arsene76,
    cas_ent27,
    cas_kosmos,
    ent_creuse,
    occitanie_montpellier,
    val_doise,
    val_de_marne,
    cas_cybercolleges42_edu,
    ecollege_haute_garonne_edu,
    ac_orleans_tours,
    ac_poitiers,
    ac_reunion,
    cas_agora06,
    cas_seinesaintdenis_edu,
    eclat_bfc,
    ent_auvergnerhonealpe,
    laclasse_educonnect,
    monbureaunumerique,
    ent77,
    ent_ecollege78,
    ent_essonne,
    ent_mayotte,
    ile_de_france,
    neoconnect_guadeloupe,
    paris_classe_numerique,
    lyceeconnecte_aquitaine,
    ent_94,
    ent_hdf,
    ent_var,
    l_normandie,
    lyceeconnecte_edu,
    ent_elyco,
    bordeaux,
    atrium_sud,
    laclasse_lyon,
    extranet_colleges_somme
)

# Mapping of ENT options with their names
ent_options = {
    "1": ("cas_arsene76", cas_arsene76),
    "2": ("cas_ent27", cas_ent27),
    "3": ("cas_kosmos", cas_kosmos),
    "4": ("ent_creuse", ent_creuse),
    "5": ("occitanie_montpellier", occitanie_montpellier),
    "6": ("val_doise", val_doise),
    "7": ("val_de_marne", val_de_marne),
    "8": ("cas_cybercolleges42_edu", cas_cybercolleges42_edu),
    "9": ("ecollege_haute_garonne_edu", ecollege_haute_garonne_edu),
    "10": ("ac_orleans_tours", ac_orleans_tours),
    "11": ("ac_poitiers", ac_poitiers),
    "12": ("ac_reunion", ac_reunion),
    "13": ("cas_agora06", cas_agora06),
    "14": ("cas_seinesaintdenis_edu", cas_seinesaintdenis_edu),
    "15": ("eclat_bfc", eclat_bfc),
    "16": ("ent_auvergnerhonealpe", ent_auvergnerhonealpe),
    "17": ("laclasse_educonnect", laclasse_educonnect),
    "18": ("monbureaunumerique", monbureaunumerique),
    "19": ("ent77", ent77),
    "20": ("ent_ecollege78", ent_ecollege78),
    "21": ("ent_essonne", ent_essonne),
    "22": ("ent_mayotte", ent_mayotte),
    "23": ("ile_de_france", ile_de_france),
    "24": ("neoconnect_guadeloupe", neoconnect_guadeloupe),
    "25": ("paris_classe_numerique", paris_classe_numerique),
    "26": ("lyceeconnecte_aquitaine", lyceeconnecte_aquitaine),
    "27": ("ent_94", ent_94),
    "28": ("ent_hdf", ent_hdf),
    "29": ("ent_var", ent_var),
    "30": ("l_normandie", l_normandie),
    "31": ("lyceeconnecte_edu", lyceeconnecte_edu),
    "32": ("ent_elyco", ent_elyco),
    "33": ("bordeaux", bordeaux),
    "34": ("atrium_sud", atrium_sud),
    "35": ("laclasse_lyon", laclasse_lyon),
    "36": ("extranet_colleges_somme", extranet_colleges_somme)
}

# Define all helper functions first
def generate_subject_averages_graph(data, output_dir):
    """Generate a bar chart showing average grades by subject"""
    plt.figure(figsize=(12, 8))
    
    # Calculate average grade per subject
    subject_grades = defaultdict(list)
    for grade in data["grades"]:
        # Convert grade value to float, handling French decimal format
        try:
            value = float(grade["value"].replace(',', '.'))
            max_value = float(grade["max_value"].replace(',', '.'))
            # Normalize to a scale of 20
            normalized_value = (value / max_value) * 20
            subject_grades[grade["subject"]].append(normalized_value)
        except (ValueError, AttributeError):
            continue
    
    # Calculate averages
    subjects = []
    averages = []
    
    for subject, grades in subject_grades.items():
        if grades:
            subjects.append(subject)
            averages.append(sum(grades) / len(grades))
    
    # Sort by average
    sorted_data = sorted(zip(subjects, averages), key=lambda x: x[1])
    subjects = [x[0] for x in sorted_data]
    averages = [x[1] for x in sorted_data]
    
    # Create bar chart
    bars = plt.barh(subjects, averages, color='skyblue')
    
    # Add value labels to bars
    for i, bar in enumerate(bars):
        plt.text(bar.get_width() + 0.2, bar.get_y() + bar.get_height()/2, 
                f'{averages[i]:.2f}/20', 
                va='center')
    
    plt.xlabel('Moyenne /20')
    plt.ylabel('Matières')
    plt.title('Moyenne par matière')
    plt.grid(axis='x', linestyle='--', alpha=0.7)
    plt.tight_layout()
    
    # Add a vertical line at 10/20
    plt.axvline(x=10, color='red', linestyle='--', alpha=0.7)
    
    # Save the figure
    plt.savefig(os.path.join(output_dir, 'subject_averages.png'), dpi=300, bbox_inches='tight')
    plt.close()

def generate_grade_distribution_graph(data, output_dir):
    """Generate a histogram showing the distribution of grades"""
    plt.figure(figsize=(10, 6))
    
    # Extract normalized grades
    all_grades = []
    for grade in data["grades"]:
        try:
            value = float(grade["value"].replace(',', '.'))
            max_value = float(grade["max_value"].replace(',', '.'))
            # Normalize to a scale of 20
            normalized_value = (value / max_value) * 20
            all_grades.append(normalized_value)
        except (ValueError, AttributeError):
            continue
    
    # Create histogram
    plt.hist(all_grades, bins=10, color='lightgreen', edgecolor='black')
    plt.xlabel('Notes /20')
    plt.ylabel('Fréquence')
    plt.title('Distribution des notes')
    plt.grid(linestyle='--', alpha=0.7)
    
    # Add mean line
    mean_grade = sum(all_grades) / len(all_grades) if all_grades else 0
    plt.axvline(mean_grade, color='red', linestyle='dashed', linewidth=2, label=f'Moyenne: {mean_grade:.2f}/20')
    plt.legend()
    
    # Save the figure
    plt.savefig(os.path.join(output_dir, 'grade_distribution.png'), dpi=300, bbox_inches='tight')
    plt.close()

def generate_time_progression_graph(data, output_dir):
    """Generate a line chart showing grade progression over time"""
    plt.figure(figsize=(12, 8))
    
    # Group grades by subject and sort by date
    subjects_data = defaultdict(list)
    
    for grade in data["grades"]:
        try:
            date = dt.fromisoformat(grade["date"]) if grade["date"].find("T") > 0 else dt.strptime(grade["date"], "%Y-%m-%d")
            value = float(grade["value"].replace(',', '.'))
            max_value = float(grade["max_value"].replace(',', '.'))
            # Normalize to a scale of 20
            normalized_value = (value / max_value) * 20
            subjects_data[grade["subject"]].append((date, normalized_value))
        except (ValueError, AttributeError) as e:
            continue
    
    # Sort by date for each subject
    for subject in subjects_data:
        subjects_data[subject].sort(key=lambda x: x[0])
    
    # Plot each subject
    for subject, points in subjects_data.items():
        if len(points) > 1:  # Only plot subjects with multiple grades
            dates = [p[0] for p in points]
            grades = [p[1] for p in points]
            plt.plot(dates, grades, marker='o', linestyle='-', label=subject)
    
    # Format the plot
    plt.xlabel('Date')
    plt.ylabel('Note /20')
    plt.title('Évolution des notes dans le temps')
    plt.grid(linestyle='--', alpha=0.7)
    
    # Format x-axis as dates
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%d/%m/%Y'))
    plt.gca().xaxis.set_major_locator(mdates.DayLocator(interval=7))
    plt.gcf().autofmt_xdate()  # Rotate date labels
    
    # Add legend
    if len(subjects_data) > 1:
        plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'time_progression.png'), dpi=300, bbox_inches='tight')
    plt.close()

def generate_student_vs_class_graph(data, output_dir):
    """Generate a bar chart comparing student grades to class averages"""
    plt.figure(figsize=(12, 8))
    
    # Extract student grades and class averages by subject
    subjects = []
    student_grades = []
    class_grades = []
    
    # Group by subject and calculate average if multiple grades per subject
    subject_data = defaultdict(lambda: {"student": [], "class": []})
    
    for grade in data["grades"]:
        try:
            # Student grade
            value = float(grade["value"].replace(',', '.'))
            max_value = float(grade["max_value"].replace(',', '.'))
            normalized_value = (value / max_value) * 20
            
            # Class average
            class_avg = float(grade["class_average"].replace(',', '.'))
            normalized_class = (class_avg / max_value) * 20
            
            subject_data[grade["subject"]]["student"].append(normalized_value)
            subject_data[grade["subject"]]["class"].append(normalized_class)
        except (ValueError, AttributeError, KeyError):
            continue
    
    # Calculate averages per subject
    for subject, values in subject_data.items():
        if values["student"] and values["class"]:
            subjects.append(subject)
            student_grades.append(sum(values["student"]) / len(values["student"]))
            class_grades.append(sum(values["class"]) / len(values["class"]))
    
    # Create grouped bar chart
    x = np.arange(len(subjects))
    width = 0.35
    
    fig, ax = plt.subplots(figsize=(12, 8))
    rects1 = ax.bar(x - width/2, student_grades, width, label='Élève', color='skyblue')
    rects2 = ax.bar(x + width/2, class_grades, width, label='Classe', color='lightgreen')
    
    # Add labels and title
    ax.set_xlabel('Matière')
    ax.set_ylabel('Note moyenne /20')
    ax.set_title('Comparaison des notes de l\'élève avec la moyenne de la classe')
    ax.set_xticks(x)
    ax.set_xticklabels(subjects, rotation=45, ha='right')
    ax.legend()
    
    # Add a horizontal line at 10/20
    ax.axhline(y=10, color='red', linestyle='--', alpha=0.7)
    
    # Add value labels on bars
    def add_labels(rects):
        for rect in rects:
            height = rect.get_height()
            ax.annotate(f'{height:.2f}',
                        xy=(rect.get_x() + rect.get_width() / 2, height),
                        xytext=(0, 3),  # 3 points vertical offset
                        textcoords="offset points",
                        ha='center', va='bottom')
    
    add_labels(rects1)
    add_labels(rects2)
    
    fig.tight_layout()
    plt.savefig(os.path.join(output_dir, 'student_vs_class.png'), dpi=300, bbox_inches='tight')
    plt.close()

def generate_graphics(data):
    """Generate graphics based on grades data"""
    # Create graphics directory if it doesn't exist
    graphics_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "graphics")
    os.makedirs(graphics_dir, exist_ok=True)
    
    print("\nGénération des graphiques en cours...")
    
    # Generate different types of visualizations
    generate_subject_averages_graph(data, graphics_dir)
    generate_grade_distribution_graph(data, graphics_dir)
    generate_time_progression_graph(data, graphics_dir)
    generate_student_vs_class_graph(data, graphics_dir)
    
    print(f"Graphiques enregistrés dans le dossier: {graphics_dir}")

config_file = 'config_tool.ini'
config = configparser.ConfigParser()

# If the config file exists, read it
if os.path.exists(config_file):
    config.read(config_file)
    USERNAME = config.get('login', 'username')
    PASSWORD = config.get('login', 'password')
    ENT_KEY = config.get('login', 'ent')

    # Check if the specified ENT_KEY is valid
    if ENT_KEY in ent_options:
        ENT = ent_options[ENT_KEY][1]  # Get the ENT function
    else:
        print(f"ENT clé '{ENT_KEY}' invalide, veuillez sélectionner à nouveau.")
        ENT = None  # Set ENT to None to indicate invalid selection
else:
    # Ask user for login information
    USERNAME = str(input("Quel est votre nom d'utilisateur : "))
    PASSWORD = getpass.getpass("Quel est votre mot de passe : ")

    # Display available ENT options in a table-like format
    ent_items = list(ent_options.items())
    table_data = []

    for i in range(0, len(ent_items), 4):
        row = ent_items[i:i+4]
        table_row = []
        for key, value in row:
            table_row.append(f"{key}: {value[0]}")
        table_data.append(table_row)

    print("Veuillez choisir votre ENT parmi les options suivantes :")
    print(tabulate(table_data, headers=[], tablefmt="grid"))

    # Prompt the user to enter the corresponding ENT number
    ENT_KEY = input("\nEntrez le numéro correspondant à votre ENT : ").strip()

    # Assign the selected ENT
    if ENT_KEY in ent_options:
        ENT = ent_options.get(ENT_KEY)[1]  # Get the ENT function
    else:
        print("Numéro de l'ENT invalide. Veuillez réessayer.")
        exit(1)  # Exit if the ENT is invalid
    
    # Save the information in the config file
    config['login'] = {
        'username': USERNAME,
        'password': PASSWORD,
        'ent': ENT_KEY
    }

    with open(config_file, 'w') as configfile:
        config.write(configfile)

# Create the client using the selected ENT
if ENT is not None:  # Check if ENT is defined
    client = pronotepy.Client('https://0841093g.index-education.net/pronote/eleve.html',
        username=USERNAME,
        password=PASSWORD,
        ent=ENT)
    
if client.logged_in:
    # Afficher les périodes disponibles
    print("Périodes disponibles :")
    for idx, period in enumerate(client.periods):
        print(f"{idx + 1}. {period.name} ({period.start} -> {period.end})")

    # Demander à l'utilisateur de choisir la période
    choix = input("Sélectionnez le numéro de la période souhaitée : ").strip()
    try:
        choix_idx = int(choix) - 1
        current_period = client.periods[choix_idx]
    except (ValueError, IndexError):
        print("Numéro de période invalide.")
        exit(1)

    # Retrieve the grades for this period
    grades = current_period.grades

    # Print the grades
    for grade in grades:
        print(f"Matière: {grade.subject.name}, Note: {grade.grade}/{grade.out_of}, moyenne (classe) : {grade.average}")
    
    # Create a structured data representation for the grades
    grades_data = {
        "student": {
            "name": client.info.name,
            "class": client.info.class_name
        },
        "period": {
            "name": current_period.name,
            "start": current_period.start.isoformat() if hasattr(current_period.start, "isoformat") else str(current_period.start),
            "end": current_period.end.isoformat() if hasattr(current_period.end, "isoformat") else str(current_period.end)
        },
        "grades": []
    }

    # Add each grade to the data structure
    for grade in grades:
        grade_data = {
            "subject": grade.subject.name,
            "value": grade.grade,
            "max_value": grade.out_of,
            "date": grade.date.isoformat() if hasattr(grade.date, "isoformat") else str(grade.date),
            "class_average": grade.average,
            "coefficient": grade.coefficient
        }
        
        # Add optional fields if they exist
        if hasattr(grade, "comment") and grade.comment:
            grade_data["comment"] = grade.comment
            
        grades_data["grades"].append(grade_data)

    # Save to a file
    output_file = "grades_data.json"
    try:
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(grades_data, f, ensure_ascii=False, indent=4)
        print(f"Grades successfully saved to {output_file}")
        
        # Generate graphics
        generate_graphics(grades_data)
    except Exception as e:
        print(f"Error saving grades to file: {e}")
else:
    print("Connexion impossible.")