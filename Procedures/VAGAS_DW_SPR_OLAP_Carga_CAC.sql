-- EXEC VAGAS_DW.SPR_OLAP_Carga_CAC
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_CAC' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_CAC
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 02/06/2017
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_CAC @DATA_REFERENCIA SMALLDATETIME = NULL

AS
SET NOCOUNT ON

	DECLARE @CMD VARCHAR(8000),@MSG VARCHAR(MAX)

	CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY,
								ERRO VARCHAR(8000) )	

	-- Carregar tabela baseado na Planilha do Google Drive 
	SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python G:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + '208' + '" "TMP_CAC" "1"'

	INSERT INTO #TMP_LOG_ERRO (ERRO)
	EXEC MASTER.DBO.XP_CMDSHELL @CMD

	-- Tratar erros ocorridos na rotina do Python	
	IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
	BEGIN 
		SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET : 181' 
		RAISERROR(@MSG , 16, 1) 
	END

	DROP TABLE #TMP_LOG_ERRO

	select * from vagas_dw.TMP_CAC

	CREATE TABLE VAGAS_DW.LTV_DETALHE_DESPESA (ANO_REFERENCIA SMALLDATETIME,TIPO VARCHAR(100),TIPO_ESTIMATIVA VARCHAR(20),
												VALOR_PLANEJADO_ANUAL MONEY,PERC_RATEIO_INDICA NUMERIC(4,2),
												PERC_RATEIO_SIMPLIFICA NUMERIC(4,2),PERC_RATEIO_SUPERA NUMERIC(4,2),
												TOTAL_CAC MONEY)

												mussarela e toscana
