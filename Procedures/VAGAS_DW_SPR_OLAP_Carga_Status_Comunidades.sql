USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Status_Comunidades' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Status_Comunidades
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 23/01/2017
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Status_Comunidades

AS
SET NOCOUNT ON
	
	-- LIMPEZA DAS TABELAS TEMPORARIAS
	TRUNCATE TABLE VAGAS_DW.TMP_COMUNIDADES_STATUS

	DECLARE @CMD VARCHAR(8000),@MSG VARCHAR(MAX)

	CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY,
								ERRO VARCHAR(8000) )	

	-- Carregar tabela baseado na Planilha do Google Drive 
	SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python G:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + '192' + '" "TMP_COMUNIDADES_STATUS" "1"'

	INSERT INTO #TMP_LOG_ERRO (ERRO)
	EXEC MASTER.DBO.XP_CMDSHELL @CMD

	-- Tratar erros ocorridos na rotina do Python	
	IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
	BEGIN 
		SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET : 189' 
		RAISERROR(@MSG , 16, 1) 
	END
	
	TRUNCATE TABLE VAGAS_DW.COMUNIDADES_STATUS 

	-- Inserção dos novos status e siglas de comunidades
	INSERT INTO VAGAS_DW.COMUNIDADES_STATUS 
	SELECT CONVERT(INT,[0]) AS COD_DIV,
		   [1] AS NOME,
		   [2] AS SIGLA,
		   [3] AS STATUS
	FROM VAGAS_DW.TMP_COMUNIDADES_STATUS
	WHERE [index] > 0
	
DROP TABLE #TMP_LOG_ERRO
	
	
	




