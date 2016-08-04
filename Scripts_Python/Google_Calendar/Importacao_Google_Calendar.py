# -*- coding: utf-8 -*
from oauth2client import client,file
from apiclient.discovery import build
from apiclient import discovery
import oauth2client
import httplib2
import datetime
from pandas import DataFrame
import pyodbc
import json

def conect_db():
	engine = pyodbc.connect(r'Driver={SQL Server};Server=SRV-SQLMIRROR02;Database=VAGAS_DW;Trusted_Connection=yes;')
	return engine

def clean_date(string):
	string = string.replace('dateTime','')
	string = string.replace('UTC','')
	string = string.replace('timeZone','')
	string = string.replace('America/Sao_Paulo','')
	string = string.replace(',','')
	string = string.replace('u','')
	string = string.replace("'",'')
	string = string.replace("'",'')
	string = string.replace('{','')
	string = string.replace('}','')
	string = string.replace(':','')
	string = string.replace('T','')
	string = string.replace('-','')
	string = string.replace(' ','')
	string = string[:-6]
	return string

def read_google_calendar(calendar_id,max_results):
	store = file.Storage('credential.json')
	credential = store.get()

	http = credential.authorize(httplib2.Http())
	service = discovery.build('calendar', 'v3', http=http)

	now = datetime.datetime.utcnow().isoformat() + 'Z' # 'Z' indicates UTC time
	print('Getting the upcoming 10 events')
	
	eventsResult = service.events().list(
		calendarId = calendar_id, 
		timeMin = now, 
		maxResults = max_results, 
		singleEvents = True,
		orderBy ='startTime').execute()
	
	calendar_list_entry = service.calendarList().get(calendarId = calendar_id).execute()
	events = eventsResult.get('items', [])
	return events,calendar_list_entry

def save_to_db(events,calendar_list_entry):	
	# treat each row from events in the calendar
	for event in events:
		# Cleaning source fields
		summary = event['summary']
		start_date = clean_date(str(event['start']))
		end_date = clean_date(str(event['end']))
		id_calendar = str(event['id'])
		calendar = calendar_list_entry['summary']
		
		# params to be sent to db
		params = (id_calendar,summary, start_date, end_date, calendar)

		# connect to MSSQL
		cn = conect_db()
		cursor = cn.cursor()

		# insert calendar 
		command = "EXEC VAGAS_DW.SPR_OLTP_Carga_Agenda '%s','%s','%s','%s','%s'" % params
		cursor.execute(command)

		# if is a meeting we get all attendees
		if (event.has_key('attendees')):
			number_attendees = len(event['attendees'])

			# loop for each attendee
			for i in range(0,number_attendees):
				attendee = event['attendees'][i]
				
				# for some users we dont receive this field
				if (attendee.has_key('displayName')):
					display_name = attendee['displayName']	
				else:
					display_name = 'NC'

				# when is a resource (room, etc) we put a mark
				if (attendee.has_key('resource')):
					resource = 1
				else:
					resource = 0
				
				email = attendee['email']
				response_status = attendee['responseStatus']
				
				#print id_calendar,display_name,email,response_status,resource 
				params = (id_calendar,display_name, email, response_status, resource)
		
				command = "EXEC VAGAS_DW.SPR_OLTP_Carga_Agenda_Participantes '%s','%s','%s','%s',%s" % params
				#print command
				cursor.execute(command)


		# close connection		
		cn.commit()
		cn.close()
	
events,calendar_list_entry = read_google_calendar('vagas.com.br_lrfdu1kl4enpm2rfrqghc3qsck@group.calendar.google.com',20)
save_to_db(events,calendar_list_entry)
#read_google_calendar('luiz.braz@vagas.com.br')
