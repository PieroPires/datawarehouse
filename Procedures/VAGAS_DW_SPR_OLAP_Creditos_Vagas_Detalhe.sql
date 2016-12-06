USE VAGAS_DW
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Creditos_Vagas_Detalhe' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Creditos_Vagas_Detalhe]
GO


-- =============================================
-- Author:      Fiama dos Santos Cristi
-- Create date: 10/08/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================
CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Creditos_Vagas_Detalhe]

AS
SET NOCOUNT ON 

TRUNCATE TABLE [VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE] ;



WITH Clientes_FIT(DATA, TIPO, SEGMENTACAO, DESCRICAO, VALOR) AS (
	SELECT A.DataFechamento ,
		A.PRODUTO ,
		'CONVERS�O' ,
		'Total de leads ou pedido de rescis�es' ,
		1
	FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A
	WHERE EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1
				  WHERE A.CONTAID = A1.CONTA_ID
					AND A1.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1))
		AND A.PRODUTO = 'FIT'
		AND A.FASE = 'fechado_e_ganho' 
		AND A.DataFechamento = (SELECT MAX(A1.DataFechamento) FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
								WHERE A.CONTAID = A1.CONTAID 
									AND A1.PRODUTO = 'FIT'
									AND A1.FASE = 'fechado_e_ganho')
		AND A.OportunidadeCategoria = 'rescisao'
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						 WHERE A.CONTAID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FLEX'
							AND A1.PRODUTO != 'CRED.VAGAS'
							AND A1.DataFechamento > A.DataFechamento)
UNION ALL

SELECT B.DataFechamento ,
		B.PRODUTO ,
		'CONVERS�O' ,
		CASE WHEN A.CONTEM_CREDITOS_VAGAS = 1 AND A.EX_CLIENTE = 0 THEN 'Total de clientes no novo modelo' ELSE 'Total de clientes que n�o aceitaram' END ,
		1
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO ,
																	A1.OportunidadeCategoria
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO = 'FIT'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC, A1.DataCriacao DESC) AS B -- Clientes FIT que pediram rescisao
	WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND B.OportunidadeCategoria = 'rescisao'
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FLEX'
							AND A1.PRODUTO != 'CRED.VAGAS'
							AND A1.DataFechamento > B.DataFechamento)


), Clientes_FLEX(DATA, TIPO, SEGMENTACAO, DESCRICAO, VALOR) AS (
	SELECT B.DataFechamento ,
		CASE WHEN B.PRODUTO = 'FLEXA' THEN 'FLEX A' ELSE 'FLEX C' END ,
		'CONVERS�O' ,
		'Total de leads ou pedido de rescis�es' ,
		1
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO_GRUPO = 'FLEX'
																	AND A1.PRODUTO != 'CRED.VAGAS'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC) AS B
	WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FIT'
							AND A1.OportunidadeCategoria = 'rescisao'
							AND A1.DataFechamento > B.DataFechamento ) 

UNION ALL

	SELECT B.DataFechamento ,
		CASE WHEN B.PRODUTO = 'FLEXA' THEN 'FLEX A' ELSE 'FLEX C' END ,
		'CONVERS�O' ,
		CASE WHEN A.CONTEM_CREDITOS_VAGAS = 1 AND A.EX_CLIENTE = 0 THEN 'Total de clientes no novo modelo' ELSE 'Total de clientes que n�o aceitaram' END ,
		1
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO_GRUPO = 'FLEX'
																	AND A1.PRODUTO != 'CRED.VAGAS'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC) AS B
	WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FIT'
							AND A1.OportunidadeCategoria = 'rescisao'
							AND A1.DataFechamento > B.DataFechamento ) 

), Clientes_NOVOS (DATA, TIPO, SEGMENTACAO, DESCRICAO, VALOR) AS (
	SELECT B.DataFechamento ,
		'NOVO',
		'CONVERS�O' ,
		'Total de clientes no novo modelo' ,
		1
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO = 'CRED.VAGAS'
																ORDER BY A1.DataFechamento DESC) AS B
	WHERE A.EX_CLIENTE = 0
		AND A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND A.CONTEM_CREDITOS_VAGAS = 1
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND (A1.RECORRENTE = 1 OR (A1.PRODUTO_GRUPO = 'FLEX' AND A1.PRODUTO != 'CRED.VAGAS')) 
							AND A1.DataFechamento < B.DataFechamento )
)
SELECT *
INTO #CONVERSOES
FROM Clientes_FIT
UNION ALL
SELECT * 
FROM Clientes_FLEX
UNION ALL
SELECT *
FROM Clientes_NOVOS ;



WITH Compras_FIT (DATA, CLIENTE, TIPO, SEGMENTACAO, DESCRICAO, VALOR) AS (
	SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		B.PRODUTO ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		C.TIPO_COMPRA ,
		C.CREDITOS_COMPRA
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO ,
																	A1.OportunidadeCategoria
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO = 'FIT'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC, A1.DataCriacao DESC) AS B -- Clientes FIT que pediram rescisao
													INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.COD_CLI
													LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
		WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND B.OportunidadeCategoria = 'rescisao'
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FLEX'
							AND A1.PRODUTO != 'CRED.VAGAS'
							AND A1.DataFechamento > B.DataFechamento)
		AND A.CONTEM_CREDITOS_VAGAS = 1

UNION ALL

	SELECT C.DATA_COMPRA ,
			A.CLIENTE_VAGAS ,
			B.PRODUTO ,
			CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
				 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
			ISNULL(CASE WHEN D.FORMA_PAGTO LIKE '%Boleto%' THEN 'Boleto banc�rio'
						WHEN D.FORMA_PAGTO LIKE '%Cart[a�]o%de%cr[e�]dito%' THEN 'Cart�o de cr�dito'
						WHEN D.FORMA_PAGTO LIKE '%D[�e]bito%' THEN 'D�bito em conta' ELSE D.FORMA_PAGTO END, 'N�O INFORMADO') ,
			C.CREDITOS_COMPRA
		FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																		A1.PRODUTO ,
																		A1.OportunidadeCategoria
																	 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																	 WHERE A.CONTA_ID = A1.CONTAID
																		AND A1.PRODUTO = 'FIT'
																		AND A1.FASE = 'fechado_e_ganho'
																	 ORDER BY A1.DataFechamento DESC, A1.DataCriacao DESC) AS B -- Clientes FIT que pediram rescisao
														INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.COD_CLI
														LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
			WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
			AND B.OportunidadeCategoria = 'rescisao'
			AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
							WHERE A.CONTA_ID = A1.CONTAID
								AND A1.FASE = 'fechado_e_ganho'
								AND A1.PRODUTO_GRUPO = 'FLEX'
								AND A1.PRODUTO != 'CRED.VAGAS'
								AND A1.DataFechamento > B.DataFechamento)
			AND A.CONTEM_CREDITOS_VAGAS = 1

UNION ALL

SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		B.PRODUTO ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		'Total de novos cr�ditos comprados' ,
		C.CREDITOS_COMPRA
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO ,
																	A1.OportunidadeCategoria
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO = 'FIT'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC, A1.DataCriacao DESC) AS B -- Clientes FIT que pediram rescisao
													INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.COD_CLI
													LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
		WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND B.OportunidadeCategoria = 'rescisao'
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FLEX'
							AND A1.PRODUTO != 'CRED.VAGAS'
							AND A1.DataFechamento > B.DataFechamento)
		AND A.CONTEM_CREDITOS_VAGAS = 1
		AND C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos'

), Compras_FLEX (DATA, CLIENTE, TIPO, SEGMENTACAO, DESCRICAO, VALOR) AS (
SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		CASE WHEN B.PRODUTO = 'FLEXA' THEN 'FLEX A' ELSE 'FLEX C' END ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		C.TIPO_COMPRA ,
		C.CREDITOS_COMPRA
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO_GRUPO = 'FLEX'
																	AND A1.PRODUTO != 'CRED.VAGAS'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC) AS B
													INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.Cod_cli
													LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
	WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FIT'
							AND A1.OportunidadeCategoria = 'rescisao'
							AND A1.DataFechamento > B.DataFechamento ) 
		AND A.CONTEM_CREDITOS_VAGAS = 1

UNION ALL

SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		CASE WHEN B.PRODUTO = 'FLEXA' THEN 'FLEX A' ELSE 'FLEX C' END ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		ISNULL(CASE WHEN D.FORMA_PAGTO LIKE '%Boleto%' THEN 'Boleto banc�rio'
					WHEN D.FORMA_PAGTO LIKE '%Cart[a�]o%de%cr[e�]dito%' THEN 'Cart�o de cr�dito'
					WHEN D.FORMA_PAGTO LIKE '%D[�e]bito%' THEN 'D�bito em conta' ELSE D.FORMA_PAGTO END, 'N�O INFORMADO') ,
		C.CREDITOS_COMPRA
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO_GRUPO = 'FLEX'
																	AND A1.PRODUTO != 'CRED.VAGAS'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC) AS B
													INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.Cod_cli
													LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
	WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FIT'
							AND A1.OportunidadeCategoria = 'rescisao'
							AND A1.DataFechamento > B.DataFechamento ) 
		AND A.CONTEM_CREDITOS_VAGAS = 1

UNION ALL

SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		CASE WHEN B.PRODUTO = 'FLEXA' THEN 'FLEX A' ELSE 'FLEX C' END ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		'Total de novos cr�ditos comprados' ,
		C.CREDITOS_COMPRA
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																 WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO_GRUPO = 'FLEX'
																	AND A1.PRODUTO != 'CRED.VAGAS'
																	AND A1.FASE = 'fechado_e_ganho'
																 ORDER BY A1.DataFechamento DESC) AS B
													INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.Cod_cli
													LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
	WHERE A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO = 'FIT'
							AND A1.OportunidadeCategoria = 'rescisao'
							AND A1.DataFechamento > B.DataFechamento ) 
		AND A.CONTEM_CREDITOS_VAGAS = 1
		AND C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos'

), Compras_NOVO (DATA, CLIENTE, TIPO, SEGMENTACAO, DESCRICAO, VALOR) AS (
	SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		CASE WHEN B.PRODUTO = 'CRED.VAGAS' THEN 'NOVO' END ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		C.TIPO_COMPRA ,
		C.CREDITOS_COMPRA
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO = 'CRED.VAGAS'
																ORDER BY A1.DataFechamento DESC) AS B
												INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.Cod_cli
												LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
	WHERE A.EX_CLIENTE = 0
		AND A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND (A1.RECORRENTE = 1 OR (A1.PRODUTO_GRUPO = 'FLEX' AND A1.PRODUTO != 'CRED.VAGAS')) 
							AND A1.DataFechamento < B.DataFechamento)
		AND A.CONTEM_CREDITOS_VAGAS = 1

UNION ALL

SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		CASE WHEN B.PRODUTO = 'CRED.VAGAS' THEN 'NOVO' END ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		ISNULL(CASE WHEN D.FORMA_PAGTO LIKE '%Boleto%' THEN 'Boleto banc�rio'
					WHEN D.FORMA_PAGTO LIKE '%Cart[a�]o%de%cr[e�]dito%' THEN 'Cart�o de cr�dito'
					WHEN D.FORMA_PAGTO LIKE '%D[�e]bito%' THEN 'D�bito em conta' ELSE D.FORMA_PAGTO END, 'N�O INFORMADO') ,
		C.CREDITOS_COMPRA 
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO = 'CRED.VAGAS'
																ORDER BY A1.DataFechamento DESC) AS B
												INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.Cod_cli
												LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
	WHERE A.EX_CLIENTE = 0
		AND A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND (A1.RECORRENTE = 1 OR (A1.PRODUTO_GRUPO = 'FLEX' AND A1.PRODUTO != 'CRED.VAGAS')) 
							AND A1.DataFechamento < B.DataFechamento)
		AND A.CONTEM_CREDITOS_VAGAS = 1

UNION ALL

SELECT C.DATA_COMPRA ,
		A.CLIENTE_VAGAS ,
		CASE WHEN B.PRODUTO = 'CRED.VAGAS' THEN 'NOVO' END ,
		CASE WHEN C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos' THEN 'COMPRA' 
			 WHEN C.TIPO_LANCAMENTO_COMPRA = 'Cr�ditos de cortesia' THEN 'CR�DITOS DE CORTESIA'	ELSE 'CONVERS�O DE CR�DITOS' END ,
		'Total de novos cr�ditos comprados' ,
		C.CREDITOS_COMPRA
	FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A		CROSS APPLY (SELECT TOP 1 A1.DataFechamento ,
																	A1.PRODUTO
																FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
																WHERE A.CONTA_ID = A1.CONTAID
																	AND A1.PRODUTO = 'CRED.VAGAS'
																ORDER BY A1.DataFechamento DESC) AS B
												INNER JOIN [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC] AS C ON A.Cod_cli = C.Cod_cli
												LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CREDITOS_VAGAS] AS D ON C.CODIGO_COMPRA = D.CODIGO_COMPRA
	WHERE A.EX_CLIENTE = 0
		AND A.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1)
		AND NOT EXISTS (SELECT 1 FROM [VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE A.CONTA_ID = A1.CONTAID
							AND A1.FASE = 'fechado_e_ganho'
							AND (A1.RECORRENTE = 1 OR (A1.PRODUTO_GRUPO = 'FLEX' AND A1.PRODUTO != 'CRED.VAGAS')) 
							AND A1.DataFechamento < B.DataFechamento)
		AND A.CONTEM_CREDITOS_VAGAS = 1
		AND C.TIPO_LANCAMENTO_COMPRA = 'Compra de cr�ditos'
)
SELECT *
INTO	#COMPRAS_MODALIDADE
FROM Compras_FIT
UNION ALL
SELECT * 
FROM Compras_FLEX
UNION ALL
SELECT *
FROM Compras_NOVO ;

SELECT DATA ,
	TIPO ,
	'Pacotes de cr�ditos comprados' + ' ' + '-' + ' ' + CONVERT(VARCHAR(15), DESCRICAO) AS SEGMENTACAO,
	CASE WHEN SEGMENTACAO = 'COMPRA' AND VALOR IN (1, 2, 3, 5, 10) THEN CONVERT(VARCHAR(29), VALOR) 
		 WHEN SEGMENTACAO = 'CONVERS�O DE CR�DITOS' THEN 'Total de cr�ditos convertidos' 
		 WHEN SEGMENTACAO = 'CR�DITOS DE CORTESIA' THEN 'Total de cr�ditos cortesia' ELSE 'OUTROS' END AS DESCRICAO ,
	CASE WHEN SEGMENTACAO IN ('CONVERS�O DE CR�DITOS', 'CR�DITOS DE CORTESIA') THEN VALOR ELSE 1 END AS VALOR
INTO #COMPRA_PACOTE
FROM #COMPRAS_MODALIDADE
WHERE SEGMENTACAO IN ('COMPRA', 'CONVERS�O DE CR�DITOS', 'CR�DITOS DE CORTESIA') 
	AND DESCRICAO IN ('OFFLINE/MANUT', 'ONLINE/EMPRESA');



SELECT  DATA_CREDITO_CONSUMO AS DATA , 
	TIPO ,
	'CONSUMO DE CREDITOS' AS SEGMENTACAO ,
	TIPO_CONSUMO AS DESCRICAO ,
	CREDITOS_CONSUMO AS VALOR
INTO #TMP_CREDITOS_CONSUMO 
FROM [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_CONSUMO]	INNER JOIN ( SELECT DISTINCT CLIENTE, TIPO FROM #COMPRAS_MODALIDADE 
																 WHERE SEGMENTACAO IN ('COMPRA', 'CR�DITOS DE CORTESIA', 'CONVERS�O DE CR�DITOS')) AS A1 ON A1.CLIENTE COLLATE SQL_Latin1_General_CP1_CI_AI = CLIENTE_VAGAS COLLATE SQL_Latin1_General_CP1_CI_AI 

UNION ALL

SELECT  DATA_CREDITO_CONSUMO AS DATA , 
	TIPO ,
	'CONSUMO DE CREDITOS' AS SEGMENTACAO ,
	'Total de cr�ditos consumidos' ,
	CREDITOS_CONSUMO AS VALOR
FROM [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_CONSUMO]	INNER JOIN ( SELECT DISTINCT CLIENTE, TIPO FROM #COMPRAS_MODALIDADE 
																 WHERE SEGMENTACAO IN ('COMPRA', 'CR�DITOS DE CORTESIA', 'CONVERS�O DE CR�DITOS')) AS A1 ON A1.CLIENTE COLLATE SQL_Latin1_General_CP1_CI_AI = CLIENTE_VAGAS COLLATE SQL_Latin1_General_CP1_CI_AI ;



SELECT DATA, TIPO, SEGMENTACAO, DESCRICAO COLLATE SQL_Latin1_General_CP1_CI_AI AS DESCRICAO, VALOR
INTO #TMP_CREDITOS_VAGAS_DETALHE
FROM #CONVERSOES
UNION ALL
SELECT DATA, TIPO, SEGMENTACAO, DESCRICAO COLLATE SQL_Latin1_General_CP1_CI_AI, VALOR
FROM #COMPRAS_MODALIDADE
UNION ALL
SELECT DATA, TIPO, SEGMENTACAO, CONVERT(VARCHAR(29), DESCRICAO) AS DESCRICAO, VALOR
FROM #COMPRA_PACOTE
UNION ALL
SELECT DATA, TIPO, SEGMENTACAO, CONVERT(VARCHAR(37), DESCRICAO) AS DESCRICAO, VALOR
FROM #TMP_CREDITOS_CONSUMO ;


DELETE FROM #TMP_CREDITOS_VAGAS_DETALHE
WHERE SEGMENTACAO IN ('CR�DITOS DE CORTESIA', 'CONVERS�O DE CR�DITOS') ;


INSERT INTO [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE](DATA_REFERENCIA, DATA, TIPO, SEGMENTACAO, DESCRICAO, VALOR)
SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)) AS DATA_REFERENCIA ,
	CONVERT(SMALLDATETIME, CONVERT(DATE, DATA)) AS DATA ,
	 TIPO ,
	 SEGMENTACAO ,
	 DESCRICAO ,
	 VALOR
FROM #TMP_CREDITOS_VAGAS_DETALHE ;


-- Layout para manter a estrutura do relat�rio no Excel:
SELECT DISTINCT TIPO
INTO #TMP_TIPO 
FROM [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE] ;


SELECT DISTINCT SEGMENTACAO
INTO #TMP_SEGMENTACAO 
FROM [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE] ;



SELECT DISTINCT DESCRICAO
INTO #TMP_DESCRICAO 
FROM [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE] 
UNION ALL
SELECT 'Convers�o em acesso ao BCE' ;



WITH LAYOUT_PRINCIPAL AS (
	SELECT TIPO 
		, SEGMENTACAO
	FROM #TMP_TIPO CROSS JOIN #TMP_SEGMENTACAO

), LAYOUT_CONVERSAO AS (
	SELECT TIPO , 
		SEGMENTACAO , 
		DESCRICAO
	FROM LAYOUT_PRINCIPAL CROSS JOIN #TMP_DESCRICAO
	WHERE SEGMENTACAO = 'CONVERS�O'
		AND DESCRICAO IN ('Total de leads ou pedido de rescis�es', 'Total de clientes que n�o aceitaram', 'Total de clientes no novo modelo') 
		
), LAYOUT_COMPRA AS (
	SELECT TIPO , 
		SEGMENTACAO , 
		DESCRICAO
	FROM LAYOUT_PRINCIPAL CROSS JOIN #TMP_DESCRICAO
	WHERE SEGMENTACAO = 'COMPRA'
		AND DESCRICAO IN ('Boleto banc�rio', 'Cart�o de cr�dito', 'D�bito em conta', 'N�O INFORMADO', 'OFFLINE/MANUT', 'ONLINE/EMPRESA', 'Total de novos cr�ditos comprados')

), LAYOUT_PACOTE_CREDITO_ONLINE AS (
	SELECT TIPO ,
		SEGMENTACAO ,
		DESCRICAO
	FROM LAYOUT_PRINCIPAL CROSS JOIN #TMP_DESCRICAO
	WHERE SEGMENTACAO IN ('Pacotes de cr�ditos comprados - ONLINE/EMPRESA')
		AND DESCRICAO IN ('1', '2', '3', '5', '10', 'OUTROS', 'Total de cr�ditos convertidos', 'Total de cr�ditos cortesia')

), LAYOUT_PACOTE_CREDITO_OFFLINE AS (
	SELECT TIPO ,
		SEGMENTACAO ,
		DESCRICAO
	FROM LAYOUT_PRINCIPAL CROSS JOIN #TMP_DESCRICAO
	WHERE SEGMENTACAO IN ('Pacotes de cr�ditos comprados - OFFLINE/MANUT')
		AND DESCRICAO IN ('1', '2', '3', '5', '10', 'OUTROS', 'Total de cr�ditos convertidos', 'Total de cr�ditos cortesia')

), LAYOUT_CONSUMO_CREDITO AS (
	SELECT TIPO ,
		SEGMENTACAO ,
		DESCRICAO
	FROM LAYOUT_PRINCIPAL CROSS JOIN #TMP_DESCRICAO
	WHERE SEGMENTACAO = 'CONSUMO DE CR�DITOS'
		AND DESCRICAO IN ('Convers�o em extra��o do BCC', 'Convers�o em acesso ao BCE', 'Convers�o em vaga', 'Total de cr�ditos consumidos')
)
SELECT * INTO #TMP_LAYOUT
FROM LAYOUT_CONVERSAO
UNION ALL
SELECT * FROM LAYOUT_COMPRA
UNION ALL
SELECT * FROM LAYOUT_PACOTE_CREDITO_ONLINE
UNION ALL
SELECT * FROM LAYOUT_PACOTE_CREDITO_OFFLINE
UNION ALL
SELECT * FROM LAYOUT_CONSUMO_CREDITO
ORDER BY TIPO, SEGMENTACAO, DESCRICAO ;



CREATE TABLE #TMP_LAYOUT_1 (
	DATA SMALLDATETIME NULL ,
	TIPO VARCHAR(6) NULL ,
	SEGMENTACAO VARCHAR(50) NULL ,
	DESCRICAO VARCHAR(37) NULL ,
	VALOR TINYINT NULL ) ;


INSERT INTO #TMP_LAYOUT_1 (TIPO, SEGMENTACAO, DESCRICAO, VALOR)
SELECT *, 0 FROM #TMP_LAYOUT ;


WITH CTE_DATAS AS (
	SELECT MIN(A.DATA) AS MENOR_DATA ,
		CONVERT(CHAR(6), A.DATA, 112) AS ANOMES ,
		B.TIPO
	FROM [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE] AS A CROSS JOIN #TMP_LAYOUT AS B
	WHERE A.DATA IS NOT NULL
	GROUP BY CONVERT(CHAR(6), A.DATA, 112) ,
		B.TIPO

), CTE_TMP_DATAS AS (
	SELECT MENOR_DATA , 
		TIPO COLLATE SQL_Latin1_General_CP1_CI_AI AS TIPO
	FROM CTE_DATAS 
	UNION ALL
	SELECT DATA ,
		A.TIPO COLLATE SQL_Latin1_General_CP1_CI_AI AS TIPO 
	FROM #TMP_LAYOUT_1 AS A INNER JOIN CTE_DATAS AS B ON A.DATA = B.MENOR_DATA
)
SELECT A.MENOR_DATA AS DATA ,
	A.TIPO ,
	B.SEGMENTACAO ,
	B.DESCRICAO ,
	B.VALOR
INTO #TMP_DADOS_LAYOUT
FROM CTE_TMP_DATAS	AS A INNER JOIN #TMP_LAYOUT_1 AS B ON A.TIPO = B.TIPO 
ORDER BY DATA ASC ,
	TIPO ASC ,
	SEGMENTACAO ASC ;

INSERT INTO [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE] (DATA_REFERENCIA, DATA, TIPO, SEGMENTACAO, DESCRICAO, VALOR)
SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)) , * 
FROM #TMP_DADOS_LAYOUT ;


-- LIMPAR TABELA FATO:
DELETE FROM [VAGAS_DW].[CREDITOS_VAGAS_DETALHE] ;

INSERT INTO [VAGAS_DW].[CREDITOS_VAGAS_DETALHE]
SELECT * FROM [VAGAS_DW].[TMP_CREDITOS_VAGAS_DETALHE] ;


DROP TABLE #CONVERSOES ;
DROP TABLE #COMPRAS_MODALIDADE ;
DROP TABLE #COMPRA_PACOTE ;
DROP TABLE #TMP_CREDITOS_CONSUMO ;
DROP TABLE #TMP_CREDITOS_VAGAS_DETALHE ;
DROP TABLE #TMP_TIPO ;
DROP TABLE #TMP_SEGMENTACAO  ;
DROP TABLE #TMP_DESCRICAO  ;	
DROP TABLE #TMP_LAYOUT ;
DROP TABLE #TMP_LAYOUT_1 ;
DROP TABLE #TMP_DADOS_LAYOUT ;
GO 



