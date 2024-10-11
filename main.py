import datetime
from dotenv import load_dotenv
import os
import pronotepy
from pronotepy.ent import *

# Load environment variables
load_dotenv()

# Access environment variables
USERNAME = os.getenv('USERNAME')
PASSWORD = os.getenv('PASSWORD')
ENT = os.getenv('ENT')

# Creating the client and passing the function to automatically get cookies from ENT
client = pronotepy.Client('https://0841093g.index-education.net/pronote/eleve.html',
	username=USERNAME,
	password=PASSWORD,
	ent=atrium_sud)

if client.logged_in: # Check if client successfully logged in
	menus = client.menus(datetime.datetime.now().date()) # Get today's menus
	print(menus[0].first_meal[0].name) # Print first menu's first meal name
