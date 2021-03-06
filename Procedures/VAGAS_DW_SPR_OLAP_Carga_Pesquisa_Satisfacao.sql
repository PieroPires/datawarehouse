-- =============================================
-- Author: Diego Gatto
-- Create date: 09/10/2019
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Pesquisa_Satisfacao' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Pesquisa_Satisfacao]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Pesquisa_Satisfacao]

AS
SET NOCOUNT ON

-- LIMPAR TABELA FATO:
TRUNCATE TABLE [VAGAS_DW].[PESQUISA_SATISFACAO] ;

-- LIMPAR TABELA STAGE:
TRUNCATE TABLE [STAGE].[VAGAS_DW].[TMP_PESQUISA_SATISFACAO] ;


DECLARE	@CMD VARCHAR(8000) ,
		@MSG VARCHAR(8000)

CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY ,	ERRO VARCHAR(8000)) ;

-- Carregar tabela baseado na Planilha do Google Drive 
SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + ' "' + '229' + '" "TMP_PESQUISA_SATISFACAO" "1"'

INSERT INTO #TMP_LOG_ERRO (ERRO)
EXEC MASTER.DBO.XP_CMDSHELL @CMD	

-- Tratar erros ocorridos na rotina do Python	
IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
BEGIN 
	SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET : 229' 
	RAISERROR(@MSG , 16, 1) 
END

TRUNCATE TABLE #TMP_LOG_ERRO	

INSERT INTO VAGAS_DW.PESQUISA_SATISFACAO (DATA_PESQUISA, EMAIL, SOLUCIONOU_TODAS_QUESTOES, NOTA_ATENDIMENTO, NIVEL_SATISFACAO_VEP, NOME_ATENDENTE)
SELECT
	 [0] AS DATA_PESQUISA
	,[3] AS EMAIL
	,[4] AS SOLUCIONOU_TODAS_QUESTOES
	,[5] AS NOTA_ATENDIMENTO
	,[7] AS NIVEL_SATISFACAO_VEP
	,[10] AS NOME_ATENDENTE
FROM [STAGE].VAGAS_DW.TMP_PESQUISA_SATISFACAO
WHERE [index] > 0
	
-- REMOÇÃO DE LINHAS EM BRANCO:
DELETE	FROM VAGAS_DW.PESQUISA_SATISFACAO
WHERE	ISNULL(DATA_PESQUISA, '') = '' 
		AND ISNULL(EMAIL, '') = '' 
		AND ISNULL(SOLUCIONOU_TODAS_QUESTOES, '') = '' 
		AND ISNULL(NOTA_ATENDIMENTO, '') = '' 
		AND ISNULL(NOME_ATENDENTE, '') = '' ;

-- LIMPEZA DAS TABELAS TEMPORÁRIAS LOCAIS:
DROP TABLE [STAGE].VAGAS_DW.TMP_PESQUISA_SATISFACAO;