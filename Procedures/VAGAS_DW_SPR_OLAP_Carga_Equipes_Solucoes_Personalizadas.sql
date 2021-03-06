USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Equipes_Solucoes_Personalizadas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Equipes_Solucoes_Personalizadas
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 05/07/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Equipes_Solucoes_Personalizadas

AS
SET NOCOUNT ON
	
	-- LIMPEZA DAS TABELAS TEMPORARIAS
	TRUNCATE TABLE STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE
	TRUNCATE TABLE STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS
	TRUNCATE TABLE STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_KARINA 
	TRUNCATE TABLE STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_TATIANE
	TRUNCATE TABLE STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_DANIELA
	--TRUNCATE TABLE STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_MICHELE

	DECLARE @CMD VARCHAR(8000),@MSG VARCHAR(MAX)

	CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY,
								ERRO VARCHAR(8000) )	

	-- Carregar tabela baseado na Planilha do Google Drive 
	SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + '181' + '" "TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS" "1"'

	INSERT INTO #TMP_LOG_ERRO (ERRO)
	EXEC MASTER.DBO.XP_CMDSHELL @CMD

	-- Tratar erros ocorridos na rotina do Python	
	IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
	BEGIN 
		SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET : 181' 
		RAISERROR(@MSG , 16, 1) 
	END

	TRUNCATE TABLE #TMP_LOG_ERRO

--SELECT * FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS

	DECLARE @ID_CONTROLE_SPREADSHEET SMALLINT,@SHEET_NAME VARCHAR(100)

	SELECT TOP 1 @ID_CONTROLE_SPREADSHEET = ID_CONTROLE_SPREADSHEET,
				 @SHEET_NAME = SHEET_NAME
	FROM VAGAS_DW.CONTROLE_SPREADSHEET 
	WHERE NOME_CONTROLE = 'SOLUÇÕES PERSONALIZADAS' 
	AND SHEET_NAME <> 'DEMANDAS'
	ORDER BY 1

	WHILE @@ROWCOUNT > 0
	BEGIN
		
		-- Carregar tabela baseado na Planilha do Google Drive
		SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + CONVERT(VARCHAR,@ID_CONTROLE_SPREADSHEET) + '" "TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_' + @SHEET_NAME + '" "1"'

		INSERT INTO #TMP_LOG_ERRO (ERRO)
		EXEC MASTER.DBO.XP_CMDSHELL @CMD

		-- Tratar erros ocorridos na rotina do Python	
		IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
		BEGIN 
			SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET : ' + CONVERT(VARCHAR,@ID_CONTROLE_SPREADSHEET)  
			RAISERROR(@MSG , 16, 1) 
		END

		SELECT TOP 1 @ID_CONTROLE_SPREADSHEET = ID_CONTROLE_SPREADSHEET,
					 @SHEET_NAME = SHEET_NAME
		FROM VAGAS_DW.CONTROLE_SPREADSHEET 
		WHERE NOME_CONTROLE = 'SOLUÇÕES PERSONALIZADAS' 
		AND SHEET_NAME <> 'DEMANDAS'
		AND ID_CONTROLE_SPREADSHEET > @ID_CONTROLE_SPREADSHEET
		ORDER BY 1

	END

	-- LIMPAR LINHAS EM BRANCO
	DELETE FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_KARINA WHERE [0] = '' OR [0] IS NULL OR ([1] = '' OR [1] IS NULL)
	DELETE FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_TATIANE WHERE [0] = '' OR [0] IS NULL OR ([1] = '' OR [1] IS NULL)
	DELETE FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_DANIELA WHERE [0] = '' OR [0] IS NULL OR ([1] = '' OR [1] IS NULL)
	DELETE FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_ALLANA WHERE ([0] = '' OR [0] IS NULL) OR ([1] = '' OR [1] IS NULL)
	DELETE FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_MICHELE WHERE ([0] = '' OR [0] IS NULL) OR ([1] = '' OR [1] IS NULL)

	-- Tratamento de campos no CUBO:
	UPDATE	[VAGAS_DW].[DEMANDAS_EQUIPES]
	SET		NOME_DEMANDA = LTRIM(RTRIM(REPLACE(A.NOME_DEMANDA, CHAR(9), ' '))) ,
			NOME_DEMANDA_ROOT = LTRIM(RTRIM(REPLACE(A.NOME_DEMANDA_ROOT, CHAR(9), ' '))) 
	FROM	[VAGAS_DW].[DEMANDAS_EQUIPES] AS A
	WHERE	EQUIPE_PROJETO = 'Soluções Personalizadas' ;

	---------------------------------------------------------------------------------------------------------------------------
	-- INSERÇÃO DAS TAREFAS POR "ABA" (PESSOA) DO GOOGLE DOCS
	---------------------------------------------------------------------------------------------------------------------------
	INSERT INTO STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE (RESPONSAVEL_PROJETO,DATA_RECEBIMENTO,COD_DEMANDA,CLIENTE,CATEGORIA,
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
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_KARINA
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
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_TATIANE
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
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_DANIELA
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
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_ALLANA
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
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_MICHELE
	WHERE [index] <> 0

	-- CONSOLIDADO DEMANDAS 
	INSERT INTO STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE (RESPONSAVEL_PROJETO,DATA_RECEBIMENTO,COD_DEMANDA,CLIENTE,CATEGORIA,
																			   FUNCIONALIDADE,ATIVIDADE,TEMPO_GASTO,RESPONSAVEL_NEGOCIO,STATUS,DATA_CONCLUSAO,
																			   FLAG_DEMANDA,TEMPO_GASTO_DSM,VALOR_HORA,VALOR_ADICIONAL,VALOR_PROPOSTA,
																			   TEMPO_ORCADO,PRAZO_ORCADO,
																			   DATA_REC_VIAB,DATA_CON_CAN_VIAB,DATA_REC_ORC,DATA_CON_ORC,COM_VIABILIDADE,DATA_CAN_ORC)

	SELECT [2] AS RESPONSAVEL_PROJETO,
		   CASE WHEN [14] IS NOT NULL AND [14] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([14],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([14],CHARINDEX('/',[14])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([14],1,CHARINDEX('/',[14])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_RECEBIMENTO,
		   [0] AS COD_DEMANDA,
		   [1] AS CLIENTE,
		   NULL AS CATEGORIA,
		   [3] AS FUNCIONALIDADE,
		   NULL AS ATIVIDADE,
		   NULL AS TEMPO_GASTO,
		   [4] AS RESPONSAVEL_NEGOCIO,
		   [5] AS STATUS,
		   CASE WHEN [15] IS NOT NULL AND [15] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([15],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([15],CHARINDEX('/',[15])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([15],1,CHARINDEX('/',[15])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_CONCLUSAO,
		   1 AS FLAG_DEMANDA,
		   ( CONVERT(FLOAT,REPLACE(SUBSTRING([16],1,CHARINDEX(':',[16])),':','')) * 60 * 60  + -- AS HORA,
		     CONVERT(FLOAT,REPLACE(SUBSTRING([16],CHARINDEX(':',[16]),3),':','')) * 60 + -- AS MINUTOS,
		     CONVERT(FLOAT,REPLACE(REVERSE(SUBSTRING(REVERSE([16]),1,CHARINDEX(':',REVERSE([16])))),':','') ) 
		   ) / 60 / 60 AS TEMPO_GASTO_DSM,
		   CASE WHEN [20] <> '' THEN CONVERT(FLOAT,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE([20],'R$ ',''),'.',''),',','.'))))
				ELSE NULL END AS VALOR_HORA,
		   CASE WHEN [17] <> '' THEN CONVERT(FLOAT,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE([17],'R$ ',''),'.',''),',','.'))))
				ELSE NULL END AS VALOR_ADICIONAL,
		   CASE WHEN [21] <> '' THEN CONVERT(FLOAT,LTRIM(RTRIM(REPLACE(REPLACE(REPLACE([21],'R$ ',''),'.',''),',','.'))))
				ELSE NULL END AS VALOR_PROPOSTA,
		   ( CONVERT(FLOAT,REPLACE(SUBSTRING([11],1,CHARINDEX(':',[11])),':','')) * 60 * 60  + -- AS HORA,
		     CONVERT(FLOAT,REPLACE(SUBSTRING([11],CHARINDEX(':',[11]),3),':','')) * 60 + -- AS MINUTOS,
		     CONVERT(FLOAT,REPLACE(REVERSE(SUBSTRING(REVERSE([11]),1,CHARINDEX(':',REVERSE([9])))),':','') ) 
		   ) / 60 / 60 AS TEMPO_ORCADO,
		   [12] AS PRAZO_ORCADO,
		   CASE WHEN [6] IS NOT NULL AND [6] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([6],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([6],CHARINDEX('/',[6])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([6],1,CHARINDEX('/',[6])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_REC_VIAB,
		  CASE WHEN [7] IS NOT NULL AND [7] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([7],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([7],CHARINDEX('/',[7])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([7],1,CHARINDEX('/',[7])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_CON_CAN_VIAB, 
		  CASE WHEN [9] IS NOT NULL AND [9] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([9],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([9],CHARINDEX('/',[9])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([9],1,CHARINDEX('/',[9])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_REC_ORC, 
		  CASE WHEN [10] IS NOT NULL AND [10] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([10],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([10],CHARINDEX('/',[10])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([10],1,CHARINDEX('/',[10])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_CON_ORC,	
		[8] AS COM_VIABILIDADE,
		CASE WHEN [13] IS NOT NULL AND [13] <> '' 
				THEN CONVERT(SMALLDATETIME,RIGHT([13],4) + -- ANO
				     RIGHT('00' + REPLACE(SUBSTRING([13],CHARINDEX('/',[13])+1,2),'/',''),2) + -- MES
				     RIGHT('00' + REPLACE(SUBSTRING([13],1,CHARINDEX('/',[13])),'/',''),2) ) -- DIA
				ELSE NULL END AS DATA_CAN_ORC
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS
	WHERE [index] <> 0
	
	---------------------------------------------------------------------------------------------------------------------------
	-- FIM DA INSERÇÃO DAS TAREFAS POR "ABA" (PESSOA) DO GOOGLE DOCS
	---------------------------------------------------------------------------------------------------------------------------

	--TIPO_DEMANDA -> CATEGORIA
	--TIPO_SUB_TAREFA -> ATIVIDADE
	--FERRAMENTA -> FUNCIONALIDADE
	
	-- LIMPEZA DOS DADOS DA TABELA PRINCIPAL
	DELETE VAGAS_DW.DEMANDAS_EQUIPES 
	FROM VAGAS_DW.DEMANDAS_EQUIPES A
	WHERE NOME_PROJETO = 'Empresas' 
	AND EQUIPE_PROJETO = 'Soluções Personalizadas'
	AND EXISTS ( SELECT * 
				 FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE
				 WHERE FLAG_DEMANDA = A.FLAG_ROOT
				 AND COD_DEMANDA = A.NOME_DEMANDA  )

	--DELETE VAGAS_DW.DEMANDAS_EQUIPES 
	--FROM VAGAS_DW.DEMANDAS_EQUIPES A
	--WHERE NOME_PROJETO = 'Empresas' 
	--AND EQUIPE_PROJETO = 'Soluções Personalizadas'
	--AND DATA_CADASTRAMENTO >= '20170101'
	--AND NOT EXISTS ( SELECT * 
	--			 FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE
	--			 WHERE FLAG_DEMANDA = A.FLAG_ROOT
	--			 AND COD_DEMANDA = A.NOME_DEMANDA 
	--			 AND DATA_RECEBIMENTO = A.DATA_CADASTRAMENTO 
	--			 AND RESPONSAVEL_PROJETO = A.CRIADOR
	--			 AND ATIVIDADE = A.TIPO_SUB_TAREFA 
	--			 AND FUNCIONALIDADE = A.FERRAMENTA )
	
	-- INSERÇÃO DAS TAREFAS FILHO
	INSERT INTO VAGAS_DW.DEMANDAS_EQUIPES (ID_DEMANDA,NUMERO_DEMANDA,NOME_DEMANDA,NOME_PROJETO,RESPONSAVEL,CRIADOR,TIPO_DEMANDA,PRIORIDADE,STATUS_DEMANDA,DATA_CADASTRAMENTO,
									   DATA_ALTERACAO,DATA_EXPECTATIVA_CONCLUSAO,DATA_CONCLUSAO,STATUS_RESOLUCAO,TEMPO_ESTIMATIVA,TEMPO_GASTO,FLAG_ATRELADO_MARCO,
									   NOME_DEMANDA_ROOT,NOME_RELEASE,EQUIPE_SOLICITANTE,TIPO_SUB_TAREFA,FLAG_ROOT,CICLO,GRAVIDADE,URGENCIA,ESFORCO,SCORE,MEDIA_DIAS_ENTREGA,
									   DATA_ULT_ENTREGA,DIAS_CONCLUSAO,TIPO_CLIENTE,FATURAVEL,EQUIPE_PROJETO,DATA_PRM_ASSIGNED,FERRAMENTA,SINTOMA,INDICE_SATISFACAO,
									   CLIENTE)

	SELECT CASE WHEN COD_DEMANDA = '' THEN 999999
				WHEN COD_DEMANDA = 'PI0001' THEN 1 
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')),CHARINDEX('-',REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')))),'-',''),CHAR(160),''))) END AS ID_DEMANDA,
		   CASE WHEN REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'') = '' THEN 999999
				WHEN REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'') = 'PI0001' THEN 1
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')),CHARINDEX('-',REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')))),'-',''),CHAR(160),''))) END AS NUMERO_DEMANDA,
		   COD_DEMANDA AS NOME_DEMANDA,
		   'Empresas' AS NOME_PROJETO,
		   RESPONSAVEL_PROJETO AS RESPONSAVEL,
		   RESPONSAVEL_PROJETO AS CRIADOR,
		   UPPER(CATEGORIA) AS TIPO_DEMANDA,
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
		   'Soluções Personalizadas' AS EQUIPE_PROJETO,
		   NULL AS DATA_PRM_ASSIGNED,
		   FUNCIONALIDADE AS FERRAMENTA,
		   NULL AS SINTOMA,
		   NULL AS INDICE_SATISFACAO,
		   CLIENTE AS CLIENTE
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE
	WHERE FLAG_DEMANDA = 0
	
	-- INSERÇÃO DAS TAREFAS MÃE (BASEADA NA ABA "DEMANDAS")
	INSERT INTO VAGAS_DW.DEMANDAS_EQUIPES (ID_DEMANDA,NUMERO_DEMANDA,NOME_DEMANDA,NOME_PROJETO,RESPONSAVEL,CRIADOR,TIPO_DEMANDA,PRIORIDADE,STATUS_DEMANDA,DATA_CADASTRAMENTO,
									   DATA_ALTERACAO,DATA_EXPECTATIVA_CONCLUSAO,DATA_CONCLUSAO,STATUS_RESOLUCAO,TEMPO_ESTIMATIVA,TEMPO_GASTO,FLAG_ATRELADO_MARCO,
									   NOME_DEMANDA_ROOT,NOME_RELEASE,EQUIPE_SOLICITANTE,TIPO_SUB_TAREFA,FLAG_ROOT,CICLO,GRAVIDADE,URGENCIA,ESFORCO,SCORE,MEDIA_DIAS_ENTREGA,
									   DATA_ULT_ENTREGA,DIAS_CONCLUSAO,TIPO_CLIENTE,FATURAVEL,EQUIPE_PROJETO,DATA_PRM_ASSIGNED,FERRAMENTA,SINTOMA,INDICE_SATISFACAO,
									   CLIENTE,VALOR_HORA,TEMPO_GASTO_AUXILIAR,VALOR_ADICIONAL,VALOR_PROPOSTA,VALOR_PROJETO,TEMPO_ORCADO,PRAZO_ORCADO,
									   VALOR_ORCADO,DATA_REC_VIAB,DATA_CON_CAN_VIAB,DATA_REC_ORC,DATA_CON_ORC,COM_VIABILIDADE,DATA_CAN_ORC)

	SELECT CASE WHEN REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'') = '' THEN 999999
				WHEN REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'') = 'PI0001' THEN 1 
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')),CHARINDEX('-',REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')))),'-',''),CHAR(160),''))) END AS ID_DEMANDA,
		   CASE WHEN COD_DEMANDA = '' THEN 999999
				WHEN COD_DEMANDA = 'PI0001' THEN 1
				ELSE CONVERT(INT,REVERSE(REPLACE(REPLACE(LEFT(REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')),CHARINDEX('-',REVERSE(REPLACE(REPLACE(COD_DEMANDA,CHAR(9),''),CHAR(32),'')))),'-',''),CHAR(160),''))) END AS NUMERO_DEMANDA,
		   COD_DEMANDA AS NOME_DEMANDA,
		   'Empresas' AS NOME_PROJETO,
		   RESPONSAVEL_PROJETO AS RESPONSAVEL,
		   RESPONSAVEL_PROJETO AS CRIADOR,
		   UPPER(CATEGORIA) AS TIPO_DEMANDA,
		   NULL AS PRIORIDADE,
		   STATUS AS STATUS_DEMANDA,
		   DATA_RECEBIMENTO AS DATA_CADASTRAMENTO,
		   NULL AS DATA_ALTERACAO,
		   NULL AS DATA_EXPECTATIVA_CONCLUSAO,
		   DATA_CONCLUSAO AS DATA_CONCLUSAO,
		   NULL AS STATUS_RESOLUCAO,
		   NULL AS TEMPO_ESTIMATIVA,
		   B.TEMPO_GASTO AS TEMPO_GASTO,
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
		   'Soluções Personalizadas' AS EQUIPE_PROJETO,
		   NULL AS DATA_PRM_ASSIGNED,
		   FUNCIONALIDADE AS FERRAMENTA,
		   NULL AS SINTOMA,
		   NULL AS INDICE_SATISFACAO,
		   CLIENTE AS CLIENTE,
		   VALOR_HORA,
		   TEMPO_GASTO_DSM,
		   VALOR_ADICIONAL,
		   VALOR_PROPOSTA,
		   ISNULL((B.TEMPO_GASTO * A.VALOR_HORA),0) + -- VALOR SOLUÇÕES PERSONALIZADAS
		   ISNULL((A.TEMPO_GASTO_DSM * A.VALOR_HORA),0) + -- VALOR DSM
		   ISNULL(VALOR_ADICIONAL,0) /* TAXI, VOOS, HOTEL,ETC */ AS VALOR_PROJETO,
		   A.TEMPO_ORCADO,
		   PRAZO_ORCADO,
		   ISNULL((A.TEMPO_ORCADO * A.VALOR_HORA),0) AS VALOR_ORCADO,
		   DATA_REC_VIAB,
		   DATA_CON_CAN_VIAB,
		   DATA_REC_ORC,
		   DATA_CON_ORC,
		   COM_VIABILIDADE,
		   DATA_CAN_ORC
	FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE A
	OUTER APPLY ( SELECT SUM(TEMPO_GASTO) AS TEMPO_GASTO
				  FROM STAGE.VAGAS_DW.TMP_DEMANDAS_SOLUCOES_PERSONALIZADAS_DEMANDAS_EQUIPE 
				  WHERE COD_DEMANDA = A.COD_DEMANDA ) B
	WHERE FLAG_DEMANDA = 1
	
	-- CONGELAR PARA ANALISAR PROBLEMA DE "PERDA DO FILTRO" DO TIPO DEMANDA
	--INSERT INTO VAGAS_DW.DEMANDAS_EQUIPES_SOLUCOES_PERSONALIZADAS_CONGELADO_20170320
	--SELECT ID_DEMANDA,NUMERO_DEMANDA,NOME_DEMANDA,NOME_PROJETO,RESPONSAVEL,CRIADOR,TIPO_DEMANDA,PRIORIDADE,STATUS_DEMANDA,
	--	   DATA_CADASTRAMENTO,DATA_ALTERACAO,DATA_EXPECTATIVA_CONCLUSAO,DATA_CONCLUSAO,STATUS_RESOLUCAO,
	--	   TEMPO_ESTIMATIVA,TEMPO_GASTO,FLAG_ATRELADO_MARCO,NOME_DEMANDA_ROOT,NOME_RELEASE,EQUIPE_SOLICITANTE,
	--	   TIPO_SUB_TAREFA,FLAG_ROOT,CICLO,GRAVIDADE,URGENCIA,ESFORCO,SCORE,MEDIA_DIAS_ENTREGA,DATA_ULT_ENTREGA,
	--	   DIAS_CONCLUSAO,TIPO_CLIENTE,FATURAVEL,EQUIPE_PROJETO,DATA_PRM_ASSIGNED,FERRAMENTA,SINTOMA,INDICE_SATISFACAO,
	--	   CLIENTE,LABEL,SPRINT,VALOR_HORA,TEMPO_GASTO_AUXILIAR,VALOR_ADICIONAL,VALOR_PROPOSTA,VALOR_PROJETO
	--FROM VAGAS_DW.DEMANDAS_EQUIPES 
	--WHERE EQUIPE_PROJETO = 'Soluções Personalizadas' 

	-- APAGAR DEMANDAS INCONSISTENTES DE SOLUÇÕES PERSONALIZADAS
	DELETE VAGAS_DW.DEMANDAS_EQUIPES 
	FROM VAGAS_DW.DEMANDAS_EQUIPES  
	WHERE EQUIPE_PROJETO = 'Soluções Personalizadas' 
	AND NOME_DEMANDA = ''
	AND FLAG_ROOT = 1
	AND TIPO_DEMANDA IS NULL

	-- ATUALIZAR TIPO DE DEMANDA PARA MAISCULAS (BUG EXCEL)	
	UPDATE VAGAS_DW.DEMANDAS_EQUIPES SET TIPO_DEMANDA = UPPER(TIPO_DEMANDA)
	FROM VAGAS_DW.DEMANDAS_EQUIPES A
	WHERE TIPO_DEMANDA IN ('Projeto','ProjetoInterno')

DROP TABLE #TMP_LOG_ERRO


-- Atualização do CONTA_ID para o campo CLIENTE:
UPDATE	[VAGAS_DW].[DEMANDAS_EQUIPES]
SET		CONTA_ID = B.CONTA_ID
FROM	[VAGAS_DW].[DEMANDAS_EQUIPES] AS A		INNER JOIN [VAGAS_DW].[CLIENTES] AS B ON A.CLIENTE COLLATE SQL_Latin1_General_CP1_CI_AI = B.CLIENTE_VAGAS COLLATE SQL_Latin1_General_CP1_CI_AI
WHERE	A.EQUIPE_PROJETO = 'Soluções Personalizadas' ;


UPDATE	[VAGAS_DW].[DEMANDAS_EQUIPES]
SET		CONTA_ID = B.CONTA_ID
FROM	[VAGAS_DW].[DEMANDAS_EQUIPES] AS A		INNER JOIN [VAGAS_DW].[CLIENTES] AS B ON A.CLIENTE COLLATE SQL_Latin1_General_CP1_CI_AI = B.CLIENTE_CRM COLLATE SQL_Latin1_General_CP1_CI_AI 
WHERE	A.CONTA_ID IS NULL
		AND A.EQUIPE_PROJETO = 'Soluções Personalizadas' ; 


-- Atualização do TEMPO_DIAS_ANALISE_VIAB e ORCAMENTOS_PROJETOS:
UPDATE	[VAGAS_DW].[DEMANDAS_EQUIPES]
SET		TEMPO_DIAS_ANALISE_VIAB = IIF(COM_VIABILIDADE = 'SIM', IIF(DATEDIFF(DAY, DATA_REC_VIAB, ISNULL(DATA_CON_CAN_VIAB, DATA_CADASTRAMENTO)) < 0, 0, DATEDIFF(DAY, DATA_REC_VIAB, ISNULL(DATA_CON_CAN_VIAB, DATA_CADASTRAMENTO))), NULL) ,
		ORCAMENTOS_PROJETOS = IIF(DATA_REC_ORC IS NOT NULL AND DATA_CADASTRAMENTO IS NOT NULL, 'SIM', 'NÃO')
FROM	[VAGAS_DW].[DEMANDAS_EQUIPES] AS A
WHERE	A.EQUIPE_PROJETO = 'Soluções Personalizadas'
		AND A.FLAG_ROOT = 1 ;