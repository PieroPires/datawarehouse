﻿-- =============================================
-- Author: Fiama
-- Create date: 25/04/2018
-- Description: Procedure para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Clientes_Intensidade' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Clientes_Intensidade] 
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Clientes_Intensidade]

AS
SET NOCOUNT ON

	-- LIMPEZA DAS TABELAS
	TRUNCATE TABLE [VAGAS_DW].[TMP_CLIENTES_INTENSIDADE] ;
	TRUNCATE TABLE [VAGAS_DW].[CLIENTES_INTENSIDADE] ;

	DECLARE	@CMD VARCHAR(8000) ,
			@MSG VARCHAR(8000)

	CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY ,
								ERRO VARCHAR(8000)) 
	
	CREATE TABLE #TMP_AUXILIAR_CLIENTES_INTENSIDADE (
		[CONTA_CRM] VARCHAR(100) NULL,
		[INTENSIDADE] VARCHAR(100) NULL ,
		[RISCO_RESCISAO] VARCHAR(100) NULL ,
		[PRINCIPAL_MOTIVO_RISCO] VARCHAR(100) NULL ,
		[OBS_DET_RISCO] VARCHAR(300) NULL ) ;

	DECLARE	@ID_CONTROLE_SPREADSHEET SMALLINT ,
			@SHEET_NAME VARCHAR(100) , 
			@NOME_CONTROLE VARCHAR(100) ;


	SET	@ID_CONTROLE_SPREADSHEET = (SELECT	MIN(ID_CONTROLE_SPREADSHEET)
									FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
									WHERE	NOME_CONTROLE = 'INTENSIDADE CLIENTES GOOGLE DRIVE'
											AND SHEET_NAME = 'DB_INTENSIDADE') ;


	SET	@SHEET_NAME = (SELECT TOP 1 SHEET_NAME
					   FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
					   WHERE NOME_CONTROLE = 'INTENSIDADE CLIENTES GOOGLE DRIVE'
							AND SHEET_NAME = 'DB_INTENSIDADE') 
					   
	SET @NOME_CONTROLE = (SELECT TOP 1 NOME_CONTROLE
						  FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
						  WHERE	NOME_CONTROLE = 'INTENSIDADE CLIENTES GOOGLE DRIVE')



	WHILE @ID_CONTROLE_SPREADSHEET IN (SELECT ID_CONTROLE_SPREADSHEET FROM [VAGAS_DW].[CONTROLE_SPREADSHEET] WHERE NOME_CONTROLE = 'INTENSIDADE CLIENTES GOOGLE DRIVE' AND SHEET_NAME = 'DB_INTENSIDADE')
	BEGIN
		
		-- Carregar tabela baseado na Planilha do Google Drive
		SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python G:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) + '" "TMP_CLIENTES_INTENSIDADE" "1"'

		INSERT INTO #TMP_LOG_ERRO (ERRO)
		EXEC MASTER.DBO.XP_CMDSHELL @CMD
		--print @CMD


		INSERT INTO #TMP_AUXILIAR_CLIENTES_INTENSIDADE(CONTA_CRM, INTENSIDADE, RISCO_RESCISAO, PRINCIPAL_MOTIVO_RISCO, OBS_DET_RISCO)
		--SELECT	[3],[5],[6],[7],[8], @SHEET_NAME
		SELECT CONVERT(VARCHAR(100),[1]) AS CONTA_CRM ,
               CONVERT(VARCHAR(100),[3]) AS INTENSIDADE ,
			   CONVERT(VARCHAR(100),[4]) AS RISCO_RESCISAO ,
			   CONVERT(VARCHAR(100),[5]) AS PRINCIPAL_MOTIVO_RISCO ,
			   CONVERT(VARCHAR(100),[6]) AS OBS_DET_RISCO
		FROM	[VAGAS_DW].[TMP_CLIENTES_INTENSIDADE]
		WHERE	[index] > 0 ;


		-- Tratar erros ocorridos na rotina do Python	
		IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
		BEGIN 
			SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET :' + ' ' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) 
			RAISERROR(@MSG , 16, 1) 
		END

		TRUNCATE TABLE #TMP_LOG_ERRO

		SET @ID_CONTROLE_SPREADSHEET +=	(SELECT TOP 1 (ID_CONTROLE_SPREADSHEET - @ID_CONTROLE_SPREADSHEET)
										 FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
										 WHERE	NOME_CONTROLE = 'INTENSIDADE CLIENTES GOOGLE DRIVE'
												AND SHEET_NAME = 'DB_INTENSIDADE'
												AND ID_CONTROLE_SPREADSHEET > @ID_CONTROLE_SPREADSHEET)

		SET @SHEET_NAME = (SELECT TOP 1 SHEET_NAME
						   FROM	  [VAGAS_DW].[CONTROLE_SPREADSHEET]
						   WHERE  NOME_CONTROLE = 'INTENSIDADE CLIENTES GOOGLE DRIVE'
								  AND ID_CONTROLE_SPREADSHEET = @ID_CONTROLE_SPREADSHEET)
	END

	-- REMOÇÃO DE LINHAS EM BRANCO:
	DELETE	FROM #TMP_AUXILIAR_CLIENTES_INTENSIDADE
	FROM	#TMP_AUXILIAR_CLIENTES_INTENSIDADE
	WHERE	ISNULL(CONTA_CRM, '') = '' 
			AND ISNULL(INTENSIDADE, '') = '' ;

------------------------------------
-- CONSOLIDADO CLIENTES_INTENSIDADE:
------------------------------------
INSERT INTO [VAGAS_DW].[CLIENTES_INTENSIDADE]
SELECT	CONTA_CRM ,
		INTENSIDADE ,
		RISCO_RESCISAO ,
		PRINCIPAL_MOTIVO_RISCO ,
		OBS_DET_RISCO
FROM	#TMP_AUXILIAR_CLIENTES_INTENSIDADE ;


-- LIMPEZA DAS TABELAS TEMPORÁRIAS LOCAIS:
DROP TABLE #TMP_LOG_ERRO ;
DROP TABLE #TMP_AUXILIAR_CLIENTES_INTENSIDADE ;