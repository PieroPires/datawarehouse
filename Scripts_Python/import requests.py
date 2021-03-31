import requests
import pandas as pd
import time
import urllib.request
import pymssql
from datetime import datetime, timedelta

conn = pymssql.connect(host='srv-sqlmirror', user='UserReport', password='u$r@2014', database='vagas_dw')
cur = conn.cursor()

cur.execute("""SELECT CONVERT(DATE,ISNULL(MAX(data_resposta_nps), '20210315')) AS data_ult_nps FROM	[VAGAS_DW].[VAGAS_DW].[nps_respostas]""")
row = cur.fetchone()
data_ult_nps = (str(row[0]))

#Passa a data recebida do SQL pro python:
data_ultimo_nps = data_ult_nps
data_ultimo_nps = datetime.strptime(data_ultimo_nps, "%Y-%m-%d")
data_ultimo_nps = data_ultimo_nps.date()
print (data_ultimo_nps)


# Última data de NPS disponível pra consulta na API:
url3 = 'https://api.getbeamer.com/v0/nps?maxResults=1'
headers =  {"Beamer-Api-Key": "b_de4PlGy9kSgmOXmzmTbuxDRWC0sQXfJaDO8bPqx2tBg="}
response = requests.get(url3, headers=headers)
response_json= response.json()
data_ult_nps_api = (response_json[0]['date'])
data_ultimo_nps_api = data_ult_nps_api
data_ultimo_nps_api = data_ultimo_nps_api[0:10]
data_ultimo_nps_api = datetime.strptime(data_ultimo_nps_api, "%Y-%m-%d").date()
print (data_ultimo_nps_api)

results = []
pagination = 18
url = 'https://api.getbeamer.com/v0/nps'
url_count = 'https://api.getbeamer.com/v0/nps/count'
headers =  {"Beamer-Api-Key": "b_de4PlGy9kSgmOXmzmTbuxDRWC0sQXfJaDO8bPqx2tBg="}
params = {'maxResults': 100, 'page': pagination}
r = requests.get(url, params=params, headers=headers)
data = r.json()


# for i in data:
#     results.append(i)
#     print(results)    
while r.status_code == 200 and data_ultimo_nps < data_ultimo_nps_api:

    params['page'] = pagination
    r = requests.get(url, params=params, headers=headers)
    data = r.json()
    print (r.status_code)


    #date = datetime.strptime(data_ultimo_nps, "%Y-%m-%d")
    data_ultimo_nps = data_ultimo_nps + timedelta(days=1)    
    # data_ultimo_nps = data_ultimo_nps + timedelta(days=1)
    print (data_ultimo_nps)

    # urllib.request.urlopen('http://www.python.org/'))
    for i in data:
        results.append(i)
        #print (results)

    # else:
    #     break
#print(results)
pd.DataFrame(results).to_csv('items2.csv', encoding='utf8', index=False, mode='a') 