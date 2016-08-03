# -*- coding: utf-8 -*
import sys
import codecs
import ast
import os
import requests, gspread
from oauth2client.client import SignedJwtAssertionCredentials
from pandas import DataFrame
from time import gmtime, strftime
import pyodbc
import sqlalchemy as sa

def authenticate_google_docs():
	# read .p12 file we generated in Google's console developer site
	#f = file(os.path.join('C:\\Users\\luiz.braz\\Desktop\\Projetos_Python\\IntegracaoGoogleSpreadSheet-536661d91d48.p12'), 'rb')
	f = file(os.path.join('\\\\SRV-SQLMIRROR02\\M$\\Projetos\\Scripts_Python\\Exportacao_Arquivos_Google_Drive\\IntegracaoGoogleSpreadSheet-536661d91d48.p12'), 'rb')
	#f = file(os.path.join('M:\\Projetos\\Scripts_Python\\IntegracaoGoogleSpreadSheet-536661d91d48.p12'), 'rb')
	SIGNED_KEY = f.read()
	f.close()

	# add some informations to authenticate
	scope = ['https://spreadsheets.google.com/feeds', 'https://docs.google.com/feeds']
	credentials = SignedJwtAssertionCredentials('luiz.braz@vagas.com.br', SIGNED_KEY, scope)

	# refresh_token we get from creds.data file
	# client_id and client_secret we get from OAuth 2.0
	data = {
	    'refresh_token' : '1/A6MISE7ZHFywZuQCkPhl4wDa2KAmDAYsQUol6sj3QZQ', 
	    'client_id' : '202379785889-9ln68an8pr9o7ldlckaev64bjej76mnm.apps.googleusercontent.com', # we won't modify this
	    'client_secret' : '7bf431wrB0zWxGyhDTRonKXl', # we won't modify this
	    'grant_type' : 'refresh_token',
	}

	r = requests.post('https://accounts.google.com/o/oauth2/token', data = data)
	credentials.access_token = ast.literal_eval(r.text)['access_token']

	# try to authenticate
	gc = gspread.authorize(credentials)
	return gc	

def conect_db():
	engine = pyodbc.connect(r'Driver={SQL Server};Server=SRV-SQLMIRROR02;Database=VAGAS_DW;Trusted_Connection=yes;')
	return engine

def conect_db_sa():
	engine = sa.create_engine('mssql+pyodbc://srv-sqlmirror02/VAGAS_DW?driver=SQL+Server+Native+Client+11.0',legacy_schema_aliasing=False)
	return engine

def read_google_docs(gc,id_controle_spreadsheet,path_out): 
	#gc = authenticate_google_docs()
	engine = conect_db()
	cursor = engine.cursor()

	# execute query to get URL and sheets name
	command = "SELECT ID_CONTROLE_SPREADSHEET,URL,CONVERT(NVARCHAR,SHEET_NAME) AS SHEET_NAME FROM VAGAS_DW.CONTROLE_SPREADSHEET WHERE ID_CONTROLE_SPREADSHEET = " + id_controle_spreadsheet
	result = cursor.execute(command)

	# get information 
	for row in result:
			ID_CONTROLE_SPREADSHEET = str(row[0]) # ID_CONTROLE_SPREADSHEET
			URL = row[1] # URL
			SHEET_NAME = row[2] # URL

	# we must use the same encoding from the server
	SHEET_NAME = SHEET_NAME.encode('cp437').decode('cp437')

	msg = ('Iniciando Processamento do ID_CONTROLE_SPREADSHEET ' + ID_CONTROLE_SPREADSHEET 
	+ ' | aba ' + SHEET_NAME + ' | arquivo .csv gerados em : ' + path_out)
	
	print msg

	# Open a sheet by URL
	sh = gc.open_by_url(URL)

	# Get the worksheet by title
	worksheet = sh.worksheet(SHEET_NAME) 
	
	#Get all values from ws
	sheet_data = worksheet.get_all_values() 
	return sheet_data,ID_CONTROLE_SPREADSHEET,SHEET_NAME
	
	# Call transformation to .csv
	#save_to_csv(file_name,sheet_name,sheet_data,path_out)

def save_to_table(sheet_data,sheet_name,table_name):
	print 'Salvando para tabela'
	
	# connecting by sqlalchemy
	engine = conect_db_sa()
	
	df = DataFrame(sheet_data)
	df.to_sql(table_name,engine,if_exists ='replace',schema='VAGAS_DW')
	
def save_to_csv(sheet_data,file_name,sheet_name,path_out):
	# Get current date and time to concatenate in the filename. We also create a tag "_csv_google_spreadsheet_" because it
	# will be necessary to split the filename
	current_datetime = strftime("%Y%m%d%H%M%S", gmtime())
	csv_file_name = ( path_out + file_name + '_gspread_sheet_' 
	+ sheet_name.encode('ASCII', 'ignore') +  '_csv_gspread_' # here we remove accents to avoid problems
	+ current_datetime + '.csv' )

	row_id = int(0)
	column_id = int(0)

	# Loop over rows to remove delimiter |
	for row in sheet_data:
		sheet_columns = len(row)
		# Loop over columns
		for column in row:
			sheet_data[row_id][column_id] = sheet_data[row_id][column_id].replace('|', ' ')
			column_id = column_id + 1

		column_id = 0
		row_id = row_id + 1
	
	print 'colunas no arquivo : ' + str(sheet_columns)
	df = DataFrame(sheet_data)
	
	# Export to csv
	df.to_csv(csv_file_name, encoding='latin-1',index=False,sep='|')	
	#df.to_csv(csv_file_name,index=False,sep='|')	

# arg1 = nome arquivo (planilha)
# arg2 = diretorio de saida (pasta TMP) | nome da tabela

def main(arg1,arg2):
	try:
		# Google's Authentication 
		gc = authenticate_google_docs()
		# Read Google Spreadsheet
		print 'Leitura da planilha ...'
		sheet_data,ID_CONTROLE_SPREADSHEET,SHEET_NAME = read_google_docs(gc,arg1,arg2)
		print 'Exportar arquivo .csv'
		
		# Save sheet's data to .csv file in arg2 [path folder]
		if (arg3 == 0):
			save_to_csv(sheet_data,ID_CONTROLE_SPREADSHEET,SHEET_NAME,arg2)
		else: # Otherwise, sheet's data to the table in arg2 [Table's name]
			save_to_table(sheet_data,SHEET_NAME,arg2)
	except:
		# Get the error_message
		error_message = str(sys.exc_info())
		print 'ERRO ocorrido na leitura/exportacao dos arquivos. ERROR_MESSAGE : ' + error_message

if __name__ == "__main__":
	if len(sys.argv) > 1:
		
		arg1 = sys.argv[1]
		arg2 = sys.argv[2]
		
		# this arg control how we export data from sheets. 
		# If we do not pass, the default is to export to .csv (| separated)
		# otherwise, we must pass table's name (in arg2) to be able to export to SQL Server
		if len(sys.argv) > 3:
			arg3 = 1
		else:
			arg3 = 0

		#print arg1
		#print arg2
		#print arg3

		#print arg3.encode('ascii').decode('cp850') #.encode('cp437').decode('cp437')
		# Call main function
		main(arg1,arg2)
