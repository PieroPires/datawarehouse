USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Equipes_Solucoes_Personalizadas_Consultorias' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Equipes_Solucoes_Personalizadas_Consultorias
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 23/01/2017
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Equipes_Solucoes_Personalizadas_Consultorias

AS
SET NOCOUNT ON
	
	-- LIMPEZA DAS TABELAS TEMPORARIAS
	TRUNCATE TABLE VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE
	TRUNCATE TABLE VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS
	TRUNCATE TABLE VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_TALITA 
	TRUNCATE TABLE VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_MICHELE

	DECLARE @CMD VARCHAR(8000),@MSG VARCHAR(MAX)

	CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY,
								ERRO VARCHAR(8000) )	

	-- Carregar tabela baseado na Planilha do Google Drive 
	SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python G:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + '189' + '" "TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS" "1"'

	INSERT INTO #TMP_LOG_ERRO (ERRO)
	EXEC MASTER.DBO.XP_CMDSHELL @CMD

	-- Tratar erros ocorridos na rotina do Python	
	IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
	BEGIN 
		SET @MSG = 'ERRO ocorrido na importa��o dos dados no ID_CONTROLE_SPREADSHEET : 189' 
		RAISERROR(@MSG , 16, 1) 
	END

	TRUNCATE TABLE #TMP_LOG_ERRO

--SELECT * FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS

	DECLARE @ID_CONTROLE_SPREADSHEET SMALLINT,@SHEET_NAME VARCHAR(100)

	SELECT TOP 1 @ID_CONTROLE_SPREADSHEET = ID_CONTROLE_SPREADSHEET,
				 @SHEET_NAME = SHEET_NAME
	FROM VAGAS_DW.CONTROLE_SPREADSHEET 
	WHERE NOME_CONTROLE = 'SOLU��ES PERSONALIZADAS - CONSULTORIAS' 
	AND SHEET_NAME <> 'DEMANDAS'
	ORDER BY 1

	WHILE @@ROWCOUNT > 0
	BEGIN
		
		-- Carregar tabela baseado na Planilha do Google Drive
		SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python G:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + CONVERT(VARCHAR,@ID_CONTROLE_SPREADSHEET) + '" "TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_' + @SHEET_NAME + '" "1"'

		INSERT INTO #TMP_LOG_ERRO (ERRO)
		EXEC MASTER.DBO.XP_CMDSHELL @CMD

		-- Tratar erros ocorridos na rotina do Python	
		IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
		BEGIN 
			SET @MSG = 'ERRO ocorrido na importa��o dos dados no ID_CONTROLE_SPREADSHEET : ' + CONVERT(VARCHAR,@ID_CONTROLE_SPREADSHEET)  
			RAISERROR(@MSG , 16, 1) 
		END

		SELECT TOP 1 @ID_CONTROLE_SPREADSHEET = ID_CONTROLE_SPREADSHEET,
					 @SHEET_NAME = SHEET_NAME
		FROM VAGAS_DW.CONTROLE_SPREADSHEET 
		WHERE NOME_CONTROLE = 'SOLU��ES PERSONALIZADAS - CONSULTORIAS' 
		AND SHEET_NAME <> 'DEMANDAS'
		AND ID_CONTROLE_SPREADSHEET > @ID_CONTROLE_SPREADSHEET
		ORDER BY 1

	END

	-- LIMPAR LINHAS EM BRANCO
	DELETE FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_TALITA WHERE [0] = '' OR [0] IS NULL
	DELETE FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_MICHELE WHERE [0] = '' OR [0] IS NULL

	---------------------------------------------------------------------------------------------------------------------------
	-- INSER��O DAS TAREFAS POR "ABA" (PESSOA) DO GOOGLE DOCS
	---------------------------------------------------------------------------------------------------------------------------
	INSERT INTO VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE (RESPONSAVEL_PROJETO,DATA_RECEBIMENTO,COD_DEMANDA,CLIENTE,CATEGORIA,
																			   FUNCIONALIDADE,ATIVIDADE,TEMPO_GASTO,FLAG_DEMANDA)
	SELECT [0] AS RESPONSAVEL_PROJETO,
		   CASE WHEN [1] IS NOT NULL AND [1] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([1],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([1],CHARINDEX('/',[1])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([1],1,CHARINDEX('/',[1])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_RECEBIMENTO, 
		   [2] AS COD_DEMANDA,
		   [3] AS CLIENTE,
		   [4] AS CATEGORIA,
		   [5] AS FUNCIONALIDADE,
		   [6] AS ATIVIDADE,
		   ( CONVERT(FLOAT,REPLACE(SUBSTRING([9],1,CHARINDEX(':',[9])),':','')) * 60 * 60  + -- AS HORA,
		     CONVERT(FLOAT,REPLACE(SUBSTRING([9],CHARINDEX(':',[9]),3),':','')) * 60 + -- AS MINUTOS,
		     CONVERT(FLOAT,REPLACE(REVERSE(SUBSTRING(REVERSE([9]),1,CHARINDEX(':',REVERSE([9])))),':','') ) 
		   ) / 60 / 60 AS TEMPO_GASTO, -- AS SEGUNDOS,
		   0 AS FLAG_DEMANDA
	FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_TALITA
	WHERE [index] <> 0

	UNION ALL
	
		SELECT [0] AS RESPONSAVEL_PROJETO,
		   CASE WHEN [1] IS NOT NULL AND [1] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([1],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([1],CHARINDEX('/',[1])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([1],1,CHARINDEX('/',[1])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_RECEBIMENTO, 
		   [2] AS COD_DEMANDA,
		   [3] AS CLIENTE,
		   [4] AS CATEGORIA,
		   [5] AS FUNCIONALIDADE,
		   [6] AS ATIVIDADE,
		   ( CONVERT(FLOAT,REPLACE(SUBSTRING([9],1,CHARINDEX(':',[9])),':','')) * 60 * 60  + -- AS HORA,
		     CONVERT(FLOAT,REPLACE(SUBSTRING([9],CHARINDEX(':',[9]),3),':','')) * 60 + -- AS MINUTOS,
		     CONVERT(FLOAT,REPLACE(REVERSE(SUBSTRING(REVERSE([9]),1,CHARINDEX(':',REVERSE([9])))),':','') ) 
		   ) / 60 / 60 AS TEMPO_GASTO, -- AS SEGUNDOS,
		   0 AS FLAG_DEMANDA
	FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_MICHELE
	WHERE [index] <> 0

	-- CONSOLIDADO DEMANDAS 
	--INSERT INTO VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE (RESPONSAVEL_PROJETO,DATA_RECEBIMENTO,COD_DEMANDA,CLIENTE,CATEGORIA,
	--																		   FUNCIONALIDADE,ATIVIDADE,TEMPO_GASTO,RESPONSAVEL_NEGOCIO,STATUS,DATA_CONCLUSAO,
	--																		   FLAG_DEMANDA)

	--SELECT [4] AS RESPONSAVEL_PROJETO,
	--	   CASE WHEN [0] IS NOT NULL AND [0] <> '' 
	--			THEN CONVERT(SMALLDATETIME,RIGHT([0],4) + -- ANO
	--			     RIGHT('00' + REPLACE(SUBSTRING([0],CHARINDEX('/',[0])+1,2),'/',''),2) + -- MES
	--			     RIGHT('00' + REPLACE(SUBSTRING([0],1,CHARINDEX('/',[0])),'/',''),2) ) -- DIA
	--			ELSE NULL END AS DATA_RECEBIMENTO,
	--	   [2] AS COD_DEMANDA,
	--	   [3] AS CLIENTE,
	--	   NULL AS CATEGORIA,
	--	   [5] AS FUNCIONALIDADE,
	--	   NULL AS ATIVIDADE,
	--	   ( CONVERT(FLOAT,REPLACE(SUBSTRING([8],1,CHARINDEX(':',[8])),':','')) * 60 * 60  + -- AS HORA,
	--	     CONVERT(FLOAT,REPLACE(SUBSTRING([8],CHARINDEX(':',[8]),3),':','')) * 60 + -- AS MINUTOS,
	--	     CONVERT(FLOAT,REPLACE(REVERSE(SUBSTRING(REVERSE([8]),1,CHARINDEX(':',REVERSE([9])))),':','') ) 
	--	   ) / 60 / 60 AS TEMPO_GASTO,
	--	   [6] AS RESPONSAVEL_NEGOCIO,
	--	   [7] AS STATUS,
	--	   CASE WHEN [1] IS NOT NULL AND [1] <> '' 
	--			THEN CONVERT(SMALLDATETIME,RIGHT([1],4) + -- ANO
	--			     RIGHT('00' + REPLACE(SUBSTRING([1],CHARINDEX('/',[1])+1,2),'/',''),2) + -- MES
	--			     RIGHT('00' + REPLACE(SUBSTRING([1],1,CHARINDEX('/',[1])),'/',''),2) ) -- DIA
	--			ELSE NULL END AS DATA_CONCLUSAO,
	--	   1 AS FLAG_DEMANDA
	--FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS
	--WHERE [index] <> 0

	---------------------------------------------------------------------------------------------------------------------------
	-- FIM DA INSER��O DAS TAREFAS POR "ABA" (PESSOA) DO GOOGLE DOCS
	---------------------------------------------------------------------------------------------------------------------------

	--TIPO_DEMANDA -> CATEGORIA
	--TIPO_SUB_TAREFA -> ATIVIDADE
	--FERRAMENTA -> FUNCIONALIDADE
	
	-- LIMPEZA DOS DADOS DA TABELA PRINCIPAL
	DELETE VAGAS_DW.DEMANDAS_EQUIPES 
	FROM VAGAS_DW.DEMANDAS_EQUIPES 
	WHERE NOME_PROJETO = 'Consultorias de RH' 
	AND EQUIPE_PROJETO = 'Solu��es Personalizadas'
	
	-- INSER��O DAS TAREFAS FILHO
	INSERT INTO VAGAS_DW.DEMANDAS_EQUIPES (ID_DEMANDA,NUMERO_DEMANDA,NOME_DEMANDA,NOME_PROJETO,RESPONSAVEL,CRIADOR,TIPO_DEMANDA,PRIORIDADE,STATUS_DEMANDA,DATA_CADASTRAMENTO,
									   DATA_ALTERACAO,DATA_EXPECTATIVA_CONCLUSAO,DATA_CONCLUSAO,STATUS_RESOLUCAO,TEMPO_ESTIMATIVA,TEMPO_GASTO,FLAG_ATRELADO_MARCO,
									   NOME_DEMANDA_ROOT,NOME_RELEASE,EQUIPE_SOLICITANTE,TIPO_SUB_TAREFA,FLAG_ROOT,CICLO,GRAVIDADE,URGENCIA,ESFORCO,SCORE,MEDIA_DIAS_ENTREGA,
									   DATA_ULT_ENTREGA,DIAS_CONCLUSAO,TIPO_CLIENTE,FATURAVEL,EQUIPE_PROJETO,DATA_PRM_ASSIGNED,FERRAMENTA,SINTOMA,INDICE_SATISFACAO,
									   CLIENTE)

	SELECT CASE WHEN COD_DEMANDA = '' THEN 999999
				WHEN COD_DEMANDA = 'PI0001' THEN 1 
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(COD_DEMANDA),CHARINDEX('-',REVERSE(COD_DEMANDA))),'-',''),CHAR(160),''))) END AS ID_DEMANDA,
		   CASE WHEN COD_DEMANDA = '' THEN 999999
				WHEN COD_DEMANDA = 'PI0001' THEN 1
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(COD_DEMANDA),CHARINDEX('-',REVERSE(COD_DEMANDA))),'-',''),CHAR(160),''))) END AS NUMERO_DEMANDA,
		   COD_DEMANDA AS NOME_DEMANDA,
		   'Consultorias de RH' AS NOME_PROJETO,
		   RESPONSAVEL_PROJETO AS RESPONSAVEL,
		   RESPONSAVEL_PROJETO AS CRIADOR,
		   CATEGORIA AS TIPO_DEMANDA,
		   NULL AS PRIORIDADE,
		   NULL AS STATUS_DEMANDA,
		   DATA_RECEBIMENTO AS DATA_CADASTRAMENTO,
		   NULL AS DATA_ALTERACAO,
		   NULL AS DATA_EXPECTATIVA_CONCLUSAO,
		   DATA_RECEBIMENTO AS DATA_CONCLUSAO,
		   NULL AS STATUS_RESOLUCAO,
		   NULL AS TEMPO_ESTIMATIVA,
		   TEMPO_GASTO AS TEMPO_GASTO,
		   NULL AS FLAG_ATRELADO_MARCO,
		   COD_DEMANDA AS NOME_DEMANDA_ROOT,
		   NULL AS NOME_RELEASE,
		   NULL AS EQUIPE_SOLICITANTE,
		   ATIVIDADE AS TIPO_SUB_TAREFA,
		   0 AS FLAG_ROOT,
		   NULL AS CICLO,
		   NULL AS GRAVIDADE,
		   NULL AS URGENCIA,
		   NULL AS ESFORCO,
		   NULL AS SCORE,
		   NULL AS MEDIA_DIAS_ENTREGA,
		   NULL AS DATA_ULT_ENTREGA,
		   NULL AS DIAS_CONCLUSAO,
		   NULL AS TIPO_CLIENTE,
		   NULL AS FATURAVEL,
		   'Solu��es Personalizadas' AS EQUIPE_PROJETO,
		   NULL AS DATA_PRM_ASSIGNED,
		   FUNCIONALIDADE AS FERRAMENTA,
		   NULL AS SINTOMA,
		   NULL AS INDICE_SATISFACAO,
		   CLIENTE AS CLIENTE
	FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE
	WHERE FLAG_DEMANDA = 0
	
	-- INSER��O DAS TAREFAS M�E (BASEADA NA ABA "DEMANDAS")
	INSERT INTO VAGAS_DW.DEMANDAS_EQUIPES (ID_DEMANDA,NUMERO_DEMANDA,NOME_DEMANDA,NOME_PROJETO,RESPONSAVEL,CRIADOR,TIPO_DEMANDA,PRIORIDADE,STATUS_DEMANDA,DATA_CADASTRAMENTO,
									   DATA_ALTERACAO,DATA_EXPECTATIVA_CONCLUSAO,DATA_CONCLUSAO,STATUS_RESOLUCAO,TEMPO_ESTIMATIVA,TEMPO_GASTO,FLAG_ATRELADO_MARCO,
									   NOME_DEMANDA_ROOT,NOME_RELEASE,EQUIPE_SOLICITANTE,TIPO_SUB_TAREFA,FLAG_ROOT,CICLO,GRAVIDADE,URGENCIA,ESFORCO,SCORE,MEDIA_DIAS_ENTREGA,
									   DATA_ULT_ENTREGA,DIAS_CONCLUSAO,TIPO_CLIENTE,FATURAVEL,EQUIPE_PROJETO,DATA_PRM_ASSIGNED,FERRAMENTA,SINTOMA,INDICE_SATISFACAO,
									   CLIENTE)

	SELECT CASE WHEN COD_DEMANDA = '' THEN 999999
				WHEN COD_DEMANDA = 'PI0001' THEN 1 
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(COD_DEMANDA),CHARINDEX('-',REVERSE(COD_DEMANDA))),'-',''),CHAR(160),''))) END AS ID_DEMANDA,
		   CASE WHEN COD_DEMANDA = '' THEN 999999
				WHEN COD_DEMANDA = 'PI0001' THEN 1
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(COD_DEMANDA),CHARINDEX('-',REVERSE(COD_DEMANDA))),'-',''),CHAR(160),''))) END AS NUMERO_DEMANDA,
		   COD_DEMANDA AS NOME_DEMANDA,
		   'Consultorias de RH' AS NOME_PROJETO,
		   RESPONSAVEL_PROJETO AS RESPONSAVEL,
		   RESPONSAVEL_PROJETO AS CRIADOR,
		   CATEGORIA AS TIPO_DEMANDA,
		   NULL AS PRIORIDADE,
		   STATUS AS STATUS_DEMANDA,
		   DATA_RECEBIMENTO AS DATA_CADASTRAMENTO,
		   NULL AS DATA_ALTERACAO,
		   NULL AS DATA_EXPECTATIVA_CONCLUSAO,
		   DATA_CONCLUSAO AS DATA_CONCLUSAO,
		   NULL AS STATUS_RESOLUCAO,
		   NULL AS TEMPO_ESTIMATIVA,
		   A.TEMPO_GASTO AS TEMPO_GASTO,
		   NULL AS FLAG_ATRELADO_MARCO,
		   COD_DEMANDA AS NOME_DEMANDA_ROOT,
		   NULL AS NOME_RELEASE,
		   NULL AS EQUIPE_SOLICITANTE,
		   ATIVIDADE AS TIPO_SUB_TAREFA,
		   1 AS FLAG_ROOT,
		   NULL AS CICLO,
		   NULL AS GRAVIDADE,
		   NULL AS URGENCIA,
		   NULL AS ESFORCO,
		   NULL AS SCORE,
		   NULL AS MEDIA_DIAS_ENTREGA,
		   NULL AS DATA_ULT_ENTREGA,
		   NULL AS DIAS_CONCLUSAO,
		   NULL AS TIPO_CLIENTE,
		   NULL AS FATURAVEL,
		   'Solu��es Personalizadas' AS EQUIPE_PROJETO,
		   NULL AS DATA_PRM_ASSIGNED,
		   FUNCIONALIDADE AS FERRAMENTA,
		   NULL AS SINTOMA,
		   NULL AS INDICE_SATISFACAO,
		   CLIENTE AS CLIENTE
	FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE A
	--OUTER APPLY ( SELECT SUM(TEMPO_GASTO) AS TEMPO_GASTO
	--			  FROM VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE 
	--			  WHERE COD_DEMANDA = A.COD_DEMANDA ) B
	WHERE FLAG_DEMANDA = 1
	
	-- APAGAR DEMANDAS INCONSISTENTES DE SOLU��ES PERSONALIZADAS
	DELETE VAGAS_DW.DEMANDAS_EQUIPES 
	FROM VAGAS_DW.DEMANDAS_EQUIPES  
	WHERE EQUIPE_PROJETO = 'Solu��es Personalizadas' 
	AND NOME_PROJETO = 'Consultorias de RH'
	AND NOME_DEMANDA = ''
	AND ( TIPO_DEMANDA IS NULL OR TIPO_DEMANDA  = '' )

DROP TABLE #TMP_LOG_ERRO
	
	
	




