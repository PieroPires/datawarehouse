USE [VAGAS_DW] ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Congelamento_Mensal' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Congelamento_Mensal]
GO

-- =============================================
-- Author: Fiama
-- Create date: 15/03/2018
-- Description: Procedure para carga das tabelas tempor?rias (BD Stage) para alimenta??o do DW
-- =============================================

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Congelamento_Mensal]
AS
SET NOCOUNT ON 

DECLARE	@DATA_CARGA_INICIO SMALLDATETIME = (SELECT DATEADD(MONTH, -1, DATEADD(DAY, 1, DATEADD(DAY, DATEPART(DAY, CAST(GETDATE() AS DATE)) * -1, CAST(GETDATE() AS DATE))))) ;
DECLARE @DATA_CARGA_FIM  SMALLDATETIME = (SELECT DATEADD(MONTH, -1, DATEADD(DAY, 1, EOMONTH(CAST(GETDATE() AS DATE))))) ;
DECLARE	@ULTIMA_DATA_CARGA SMALLDATETIME = (SELECT	MAX(A1.DATA_CARGA) FROM [VAGAS_DW].[CONGELAMENTO_MENSAL] AS A1)

-- Mant?m a ?ltima data de carga:
DELETE	FROM [VAGAS_DW].[CONGELAMENTO_MENSAL]
FROM	[VAGAS_DW].[CONGELAMENTO_MENSAL] AS A
WHERE	DATEPART(YEAR, @DATA_CARGA_INICIO) = DATEPART(YEAR, @ULTIMA_DATA_CARGA)
		AND DATEPART(MONTH, @DATA_CARGA_INICIO) = DATEPART(MONTH, @ULTIMA_DATA_CARGA)
		AND DATEPART(DAY, EOMONTH(@DATA_CARGA_INICIO)) != DATEPART(DAY, @ULTIMA_DATA_CARGA) ;

-- Mant?m apenas uma carga para a mesma data:
DELETE	FROM [VAGAS_DW].[CONGELAMENTO_MENSAL]
FROM	[VAGAS_DW].[CONGELAMENTO_MENSAL] AS A
WHERE	A.DATA_CARGA = EOMONTH(@DATA_CARGA_INICIO) ;


-------------------------
-- CANDIDATOS (CADASTRO):
-------------------------
SELECT	DATEADD(DAY, -1, @DATA_CARGA_FIM) AS DATA_CARGA ,
		IIF(FEZ_ACESSO_IRRESTRITO = 1, 'BCC', 'BCE') AS CATEGORIA ,
		A.TIPO_CADASTRO AS SUB_CATEGORIA ,
		COUNT(*) AS QTD_CANDIDATOS ,
		COUNT(CASE WHEN DATEPART(YEAR, A.DATA_ULT_ATUALIZACAO) = DATEPART(YEAR, @DATA_CARGA_INICIO) AND DATEPART(MONTH, A.DATA_ULT_ATUALIZACAO) = DATEPART(MONTH, @DATA_CARGA_INICIO)
						THEN A.COD_CAND
					ELSE NULL
				END) AS QTD_CANDIDATOS_ATUALIZACAO ,
		'CUBO CANDIDATOS' AS FONTE_CONGELAMENTO
INTO	#TMP_CANDIDATOS
FROM	[VAGAS_DW].[CANDIDATOS] AS A
WHERE	A.DATA_CADASTRO >= @DATA_CARGA_INICIO
		AND A.DATA_CADASTRO < @DATA_CARGA_FIM
		AND A.TIPO_CADASTRO IN ('Cadastro - BCC', 'Curriculo - BCC', 'Exclusivo de Cliente - BCE')
GROUP BY
		IIF(FEZ_ACESSO_IRRESTRITO = 1, 'BCC', 'BCE') ,
		A.TIPO_CADASTRO ;



----------------------------
-- CANDIDATOS (ATUALIZACAO):
----------------------------
SELECT	DATEADD(DAY, -1, @DATA_CARGA_FIM) AS DATA_CARGA ,
		IIF(FEZ_ACESSO_IRRESTRITO = 1, 'BCC', 'BCE') AS CATEGORIA ,
		A.TIPO_CADASTRO AS SUB_CATEGORIA ,
		COUNT(*) AS QTD_CANDIDATOS ,
		COUNT(CASE WHEN DATEPART(YEAR, A.DATA_ULT_ATUALIZACAO) = DATEPART(YEAR, @DATA_CARGA_INICIO) AND DATEPART(MONTH, A.DATA_ULT_ATUALIZACAO) = DATEPART(MONTH, @DATA_CARGA_INICIO)
						THEN A.COD_CAND
					ELSE NULL
				END) AS QTD_CANDIDATOS_ATUALIZACAO ,
		'CUBO CANDIDATOS' AS FONTE_CONGELAMENTO
INTO	#TMP_CANDIDATOS
FROM	[VAGAS_DW].[CANDIDATOS] AS A
WHERE	A.DATA_CADASTRO >= @DATA_CARGA_INICIO
		AND A.DATA_CADASTRO < @DATA_CARGA_FIM
		AND A.TIPO_CADASTRO IN ('Cadastro - BCC', 'Curriculo - BCC', 'Exclusivo de Cliente - BCE')
GROUP BY
		IIF(FEZ_ACESSO_IRRESTRITO = 1, 'BCC', 'BCE') ,
		A.TIPO_CADASTRO ;

----------------
-- CANDIDATURAS:
----------------
SELECT	DATEADD(DAY, -1, @DATA_CARGA_FIM) AS DATA_CARGA ,
		A.FONTE_CANDIDATURA AS CATEGORIA ,
		'' AS SUB_CATEGORIA ,
		COUNT(*) AS QTD_CANDIDATURAS ,
		'CUBO CANDIDATURAS' AS FONTE_CONGELAMENTO
INTO	#TMP_CANDIDATURAS
FROM	[VAGAS_DW].[CANDIDATURAS] AS A
WHERE	A.DATA_CANDIDATURA >= @DATA_CARGA_INICIO
		AND A.DATA_CANDIDATURA < @DATA_CARGA_FIM
GROUP BY
		A.FONTE_CANDIDATURA ;


-- Carregando os registros de candidatos:
INSERT INTO [VAGAS_DW].[CONGELAMENTO_MENSAL] (DATA_CARGA, CATEGORIA, SUB_CATEGORIA, QTD_CANDIDATOS, QTD_CANDIDATOS_ATUALIZACAO, FONTE_CONGELAMENTO)
SELECT	A.DATA_CARGA ,
		A.CATEGORIA ,
		A.SUB_CATEGORIA ,
		A.QTD_CANDIDATOS ,
		A.QTD_CANDIDATOS_ATUALIZACAO ,
		A.FONTE_CONGELAMENTO
FROM	#TMP_CANDIDATOS AS A ;


-- Carregado os registros de candidaturas:
INSERT INTO [VAGAS_DW].[CONGELAMENTO_MENSAL] (DATA_CARGA, CATEGORIA, SUB_CATEGORIA, QTD_CANDIDATURAS, FONTE_CONGELAMENTO)
SELECT	A.DATA_CARGA , 
		A.CATEGORIA , 
		A.SUB_CATEGORIA , 
		A.QTD_CANDIDATURAS , 
		A.FONTE_CONGELAMENTO
FROM	#TMP_CANDIDATURAS  AS A ;

-- Apagar tempor?rias:
DROP TABLE #TMP_CANDIDATOS ;
DROP TABLE #TMP_CANDIDATURAS ;