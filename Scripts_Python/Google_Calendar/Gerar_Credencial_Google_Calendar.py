from __future__ import print_function
import httplib2
import os

from apiclient import discovery
import oauth2client
from oauth2client import client
from oauth2client import tools

import datetime

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/calendar-python-quickstart.json
SCOPES = 'https://www.googleapis.com/auth/calendar.readonly'
CLIENT_SECRET_FILE = 'client_secret_966374513540-tfucbo1phtq26kupogk23s2c6hoqj360.apps.googleusercontent.com.json'
APPLICATION_NAME = 'Client_Google_Calendar'
CREDENTIAL_PATH = ''

def get_credentials():

	home_dir = os.path.expanduser('~')
	credential_dir = os.path.join(home_dir, '.credentials')
	if not os.path.exists(credential_dir):
		os.makedirs(credential_dir)

	credential_path = os.path.join(credential_dir,'calendar-python-quickstart.json')

	flow = client.flow_from_clientsecrets(CLIENT_SECRET_FILE, SCOPES)
	flow.user_agent = APPLICATION_NAME

	store = oauth2client.file.Storage(credential_path)
	credentials = store.get()

	if flags:
			credentials = tools.run_flow(flow, store, flags)
	else: # Needed only for compatibility with Python 2.6
			credentials = tools.run(flow, store)
	
	print('Storing credentials to ' + credential_path)
	return credentials

get_credentials()