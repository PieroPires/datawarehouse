import sys
import requests
import BeautifulSoup
import openpyxl
from pandas import DataFrame
import pyodbc
import sqlalchemy as sa

def busca_informacoes_indicadores(url):
	print "buscando informacoes ..."
	return requests.get(url, timeout=10.000)

def cria_lista_indicador_ipca(response):
	print "cria_lista_ipca"

	mes_ano = []
	indice_mes = []
	indice_acumulado_ano = []
	indice_acumulado_12_meses = []

	soup = BeautifulSoup.BeautifulSoup(response.content)
	table = soup.findAll('table')[4] # table's position
	
	for tr in table.findAll('tr')[1:]:
		col = tr.findAll('td')
		# get variables for using in pandas
		mes_ano.append(col[0].text )
		indice_mes.append(col[1].text )
		indice_acumulado_ano.append(col[2].text )
		indice_acumulado_12_meses.append(col[3].text )

	columns = {'mes_ano': mes_ano,'indice_mes':indice_mes,'indice_acumulado_ano':indice_acumulado_ano,'indice_acumulado_12_meses':indice_acumulado_12_meses }
	df = DataFrame(columns)
	return df

def cria_lista_indicador_igpm(response):
	print "cria_lista_igpm"

	mes_ano = []
	indice_mes = []
	indice_acumulado_ano = []
	indice_acumulado_12_meses = []

	soup = BeautifulSoup.BeautifulSoup(response.content)
	table = soup.findAll('table')[2] # table's position

	for tr in table.findAll('tr')[1:]:
		col = tr.findAll('td')
		# get variables for using in pandas
		mes_ano.append(col[0].text )
		indice_mes.append(col[1].text )
		indice_acumulado_ano.append(col[2].text )
		indice_acumulado_12_meses.append(col[3].text )

	columns = {'mes_ano': mes_ano,'indice_mes':indice_mes,'indice_acumulado_ano':indice_acumulado_ano,'indice_acumulado_12_meses':indice_acumulado_12_meses }
	df = DataFrame(columns)
	return df

def cria_lista_indicador_dolar(response):
	print "cria_lista_dolar"

	data = []
	compra = []
	venda = []
	perc_variacao = []

	soup = BeautifulSoup.BeautifulSoup(response.content)
	table = soup.findAll('table')[1] # table's position

	for tr in table.findAll('tr')[1:]:
		col = tr.findAll('td')
		# get variables for using in pandas
		data.append(col[0].text )
		compra.append(col[1].text )
		venda.append(col[2].text )
		perc_variacao.append(col[3].text )

	columns = {'data': data,'compra':compra,'venda':venda,'perc_variacao':perc_variacao }
	df = DataFrame(columns)
	return df
		
def exporta_sql(df,table):
	engine = sa.create_engine('mssql+pyodbc://srv-sqlmirror02/VAGAS_DW?driver=SQL+Server+Native+Client+11.0')
	df.to_sql(table,engine,if_exists ='replace',schema ='VAGAS_DW')
	print "exporta_sql"

def main(arg1):
	
	if arg1 == "IPCA": # Get IPCA's data	
		response = busca_informacoes_indicadores("http://www.portalbrasil.net/ipca.htm")
		df = cria_lista_indicador_ipca(response)
		exporta_sql(df,"TMP_INDICADORES_IPCA")

	if arg1 == "IGPM": # Get IGP-M's data	
		response = busca_informacoes_indicadores("http://www.portalbrasil.net/igpm.htm")
		df = cria_lista_indicador_igpm(response)
		exporta_sql(df,"TMP_INDICADORES_IGPM")

	if arg1 == "DOLAR": # Get dolar's data	
		response = busca_informacoes_indicadores("http://cotacoes.economia.uol.com.br/cambio/cotacoes-historicas.html?cod=BRL&type=s&size=200")
		df = cria_lista_indicador_dolar(response)
		exporta_sql(df,"TMP_INDICADORES_DOLAR")

if __name__ == "__main__":
	if len(sys.argv) > 1:
		arg1 = sys.argv[1].decode('latin-1')
		main(arg1)

