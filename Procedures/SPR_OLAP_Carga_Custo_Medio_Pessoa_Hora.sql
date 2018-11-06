-- =============================================
-- Author: Fiama
-- Create date: 24/10/2018
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Custo_Medio_Pessoa_Hora' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Custo_Medio_Pessoa_Hora]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Custo_Medio_Pessoa_Hora]
AS
SET NOCOUNT ON


	 -- LIMPEZA DA TABELA:
	 TRUNCATE TABLE [VAGAS_DW].[TMP_CUSTO_MEDIO_PESSOA_HORA] ;

	 DECLARE @CMD VARCHAR(8000) ,
			 @MSG VARCHAR(8000) ;

	 CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY ,
								ERRO VARCHAR(8000)) 


	
	CREATE TABLE #TMP_CUSTO_MEDIO_PESSOA_HORA (
		[DATA_RECEBIMENTO] VARCHAR(100) ,
		[VALOR_HORA_HOMEM] VARCHAR(100) ) ;


	DECLARE	@ID_CONTROLE_SPREADSHEET SMALLINT = 221 ,
			@SHEET_NAME VARCHAR(100) = 'DATABASE' ,
			@NOME_CONTROLE VARCHAR(100) = 'VALOR_HORA_HOMEM' ;


BEGIN		
	-- Carregar tabela baseado na Planilha do Google Drive
	SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python G:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
			' "' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) + '" "TMP_CUSTO_MEDIO_PESSOA_HORA" "1"'

	INSERT INTO #TMP_LOG_ERRO (ERRO)
	EXEC MASTER.DBO.XP_CMDSHELL @CMD
	print @CMD

	INSERT INTO #TMP_CUSTO_MEDIO_PESSOA_HORA
	SELECT	[0],[1]
	FROM	[VAGAS_DW].[TMP_CUSTO_MEDIO_PESSOA_HORA]
	WHERE	[index] > 0 ;

	-- Tratar erros ocorridos na rotina do Python	
	IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
	BEGIN 
		SET @MSG = 'ERRO ocorrido na importa��o dos dados no ID_CONTROLE_SPREADSHEET :' + ' ' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) 
		RAISERROR(@MSG , 16, 1) 
	END

	TRUNCATE TABLE #TMP_LOG_ERRO


END

---------------------------------------
-- CONSOLIDADO CUSTO_MEDIO_PESSOA_HORA:
---------------------------------------
INSERT INTO [VAGAS_DW].[CUSTO_MEDIO_PESSOA_HORA] (DATA_RECEBIMENTO, VALOR_HORA_HOMEM)
SELECT	CONCAT(RIGHT(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A.DATA_RECEBIMENTO)), CHAR(9), ''), CHAR(10), ''), CHAR(13), ''), 4), 
		REVERSE(SUBSTRING(REVERSE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A.DATA_RECEBIMENTO)), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')), 6,2)),
		LEFT(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A.DATA_RECEBIMENTO)), CHAR(9), ''), CHAR(10), ''), CHAR(13), ''), 2)) AS DATA_RECEBIMENTO ,
		CONVERT(MONEY,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A.VALOR_HORA_HOMEM)), CHAR(9), ''), CHAR(10), ''), CHAR(13), ''), 'R$', ''), ',', '.')) AS VALOR_HORA_HOMEM
FROM	#TMP_CUSTO_MEDIO_PESSOA_HORA AS A ;


-- Levanta os registros duplicados pra remo��o:
SELECT	DATA_RECEBIMENTO ,
		COUNT(*) - 1 AS QTD_REGISTROS
INTO	#TMP_REG
FROM	[VAGAS_DW].[CUSTO_MEDIO_PESSOA_HORA]
GROUP BY
		DATA_RECEBIMENTO
HAVING COUNT(*) > 1 ;


-- Mant�m apenas uma �nica ocorr�ncia pra uma mesma data:
DECLARE	@REMOVER SMALLINT ,
		@DATA_RECEBIMENTO DATE ;


WHILE ( SELECT TOP 1 1 FROM #TMP_REG ) IS NOT NULL
BEGIN
	SET	@REMOVER = ( SELECT	A.QTD_REGISTROS
					 FROM	#TMP_REG AS A
					 WHERE	A.DATA_RECEBIMENTO =	( SELECT	MIN(A1.DATA_RECEBIMENTO)
													  FROM		#TMP_REG AS A1 ) ) ;

										   
	SET	@DATA_RECEBIMENTO =	( SELECT A.DATA_RECEBIMENTO
							  FROM	#TMP_REG AS A
							  WHERE	A.DATA_RECEBIMENTO = ( SELECT		MIN(A1.DATA_RECEBIMENTO)
														   FROM			#TMP_REG AS A1 ) ) ;

	DELETE	TOP (@REMOVER)
	FROM	[VAGAS_DW].[CUSTO_MEDIO_PESSOA_HORA]
	FROM	[VAGAS_DW].[CUSTO_MEDIO_PESSOA_HORA] AS A
	WHERE	A.DATA_RECEBIMENTO = @DATA_RECEBIMENTO ;
	
	DELETE FROM #TMP_REG
	FROM	#TMP_REG
	WHERE	DATA_RECEBIMENTO = @DATA_RECEBIMENTO
			AND QTD_REGISTROS = @REMOVER ;
END

-- Apagar tabelas:
DROP TABLE #TMP_LOG_ERRO ;
DROP TABLE #TMP_CUSTO_MEDIO_PESSOA_HORA ;
DROP TABLE #TMP_REG ;