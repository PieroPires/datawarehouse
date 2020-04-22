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
	SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + '220' + '" "TMP_CAC" "1"'

	INSERT INTO #TMP_LOG_ERRO (ERRO)
	EXEC MASTER.DBO.XP_CMDSHELL @CMD

	-- Tratar erros ocorridos na rotina do Python	
	IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
	BEGIN 
		SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET : 220' 
		RAISERROR(@MSG , 16, 1) 
	END

	DROP TABLE #TMP_LOG_ERRO

	-- LIMPAR TABELA COM OS DETALHES DAS DESPESAS
	TRUNCATE TABLE VAGAS_DW.CAC_DETALHE_DESPESA
	
	INSERT INTO VAGAS_DW.CAC_DETALHE_DESPESA(ANO_REFERENCIA,TIPO,DESCRICAO,TIPO_ESTIMATIVA,VALOR_PLANEJADO_ANUAL,
											 PERC_RATEIO_INDICA,PERC_RATEIO_SIMPLIFICA,PERC_RATEIO_SUPERA,
											 TOTAL_CAC_SUPERA,TOTAL_CAC_SIMPLIFICA,TOTAL_CAC)
	SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,[0]) + '0101') AS ANO_REFERENCIA,
		   [1] AS TIPO,
		   [2] AS DESCRICAO,
		   [3] AS TIPO_ESTIMATIVA,
		   CONVERT(MONEY,REPLACE(SUBSTRING(REPLACE([4],'R$',''),1,LEN(RTRIM(LTRIM(REPLACE([4],'R$',''))))-2),'.','')) AS VALOR_PLANEJADO_ANUAL,
		   CONVERT(NUMERIC(5,2),REPLACE(REPLACE([5],'%',''),',','.')) / 100 AS PERC_RATEIO_INDICA,
		   CONVERT(NUMERIC(5,2),REPLACE(REPLACE([6],'%',''),',','.')) / 100 AS PERC_RATEIO_SIMPLIFICA,
		   CONVERT(NUMERIC(5,2),REPLACE(REPLACE([7],'%',''),',','.')) / 100 AS PERC_RATEIO_SUPERA,
		   CONVERT(MONEY,REPLACE(SUBSTRING(REPLACE([8],'R$',''),1,LEN(RTRIM(LTRIM(REPLACE([8],'R$',''))))-2),'.','')) AS TOTAL_CAC_SUPERA,
		   CONVERT(MONEY,REPLACE(SUBSTRING(REPLACE([9],'R$',''),1,LEN(RTRIM(LTRIM(REPLACE([9],'R$',''))))-2),'.','')) AS TOTAL_CAC_SIMPLIFICA,
		   CONVERT(MONEY,REPLACE(SUBSTRING(REPLACE([10],'R$',''),1,LEN(RTRIM(LTRIM(REPLACE([10],'R$',''))))-2),'.','')) AS TOTAL_CAC
	FROM STAGE.VAGAS_DW.TMP_CAC												
	WHERE [index] <> 0 AND [0] <> ''

	
	