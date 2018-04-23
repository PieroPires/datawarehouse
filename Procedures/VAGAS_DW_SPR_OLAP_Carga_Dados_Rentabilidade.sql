-- EXEC VAGAS_DW.SPR_OLAP_Carga_Dados_Rentabilidade
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Dados_Rentabilidade' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Dados_Rentabilidade
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 18/04/2017
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Dados_Rentabilidade 

AS
SET NOCOUNT ON

DECLARE @CMD VARCHAR(8000),@MSG VARCHAR(MAX)

CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY,
							ERRO VARCHAR(8000) )	

-- Carregar tabela baseado na Planilha do Google Drive 
SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python G:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
			' "' + '193' + '" "TMP_PLANILHA_RENTABILIDADE" "1"'

INSERT INTO #TMP_LOG_ERRO (ERRO)
EXEC MASTER.DBO.XP_CMDSHELL @CMD

-- Tratar erros ocorridos na rotina do Python	
IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
BEGIN 
	SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET : 193' 
	RAISERROR(@MSG , 16, 1) 
END

TRUNCATE TABLE #TMP_LOG_ERRO			

SELECT CONVERT(SMALLDATETIME,RIGHT([0],4) + LEFT([0],2) + '01') AS DATA,
	   CONVERT(NUMERIC(5,2),REPLACE(REPLACE([1],'%',''),',','.')) / 100  AS CDI 
INTO #TMP_PLANILHA_RENTABILIDADE
FROM VAGAS_DW.TMP_PLANILHA_RENTABILIDADE
WHERE [index] > 0
	AND [1] != '' ;

-- ATUALIZAR INDICADOR CDI
UPDATE VAGAS_DW.INDICADORES_ECONOMICOS_MENSAL SET CDI_APLICACAO_VAGAS = B.CDI
FROM VAGAS_DW.INDICADORES_ECONOMICOS_MENSAL A
INNER JOIN #TMP_PLANILHA_RENTABILIDADE B ON B.DATA = A.DATA
