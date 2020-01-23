USE [VAGAS_DW] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Implantacao_Necessidades' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Implantacao_Necessidades
GO

-- =============================================
-- Author: Diego Gatto
-- Create date: 15/01/2020
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Implantacao_Necessidades

AS
SET NOCOUNT ON

	-- LIMPEZA DA TABELA:
		-- LIMPEZA DA TABELA:
	TRUNCATE TABLE [VAGAS_DW].[TMP_IMPLANTACAO_NECESSIDADES] ;

	DECLARE	@CMD VARCHAR(8000) ,
			@MSG VARCHAR(8000)

	DROP TABLE IF EXISTS #TMP_LOG_ERRO;

	CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY ,
								ERRO VARCHAR(8000)) 
	
	DROP TABLE IF EXISTS #TMP_AUXILIAR_IMPLANTACAO_NECESSIDADES;

	CREATE TABLE #TMP_AUXILIAR_IMPLANTACAO_NECESSIDADES (
		[ID] INT NOT NULL PRIMARY KEY,
		[DATA_RECEBIMENTO] VARCHAR(255) NULL,
		[EMAIL] VARCHAR(255) NULL,
		[NOME] VARCHAR(255) NULL ,
		[EMPRESA] VARCHAR (50) NULL ,
		[UNIDADE] VARCHAR(255) NULL ,
		[UF] VARCHAR(255) NULL,
		[POSSUI_USUARIO] VARCHAR(25) NULL,
		[CRIAR_VAGAS] VARCHAR(25) NULL,
		[TRIAGEM_CVS_VAGAS] VARCHAR(25) NULL,
		[TRIAGEM_CVS_BCE] VARCHAR(25) NULL,
		[TRIAGEM_CVS_BCC] VARCHAR(25) NULL,
		[GESTAO_PROCESSO] VARCHAR(25) NULL,
		[FASES] VARCHAR(25) NULL,
		[VAGAS_MODELO] VARCHAR(25) NULL,
		[MENSAGENS_PADRONIZADAS] VARCHAR(25) NULL,
		[FEEDBACK_MANUAL] VARCHAR(25) NULL,
		[FEEDBACK_AUTOMATICO] VARCHAR(25) NULL,
		[CONTROLE_SLA] VARCHAR(25) NULL,
		[RELATORIOS] VARCHAR(25) NULL,
		[EVENTOS_PRESENCIAIS] VARCHAR(25) NULL,
		[ENVIO_TESTES_FICHAS] VARCHAR(25) NULL,
		[DISC] VARCHAR(25) NULL,
		[VIDEO_ENTREVISTA] VARCHAR(25) NULL,
		[SUGESTOES_COMENTARIOS] VARCHAR(255) NULL,
		[O_QUE_E_SUCESSO] VARCHAR(255) NULL )


	DECLARE	@ID_CONTROLE_SPREADSHEET SMALLINT = 230;

	-- Carregar tabela baseado na Planilha do Google Drive
	SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
			' "' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) + '" "TMP_IMPLANTACAO_NECESSIDADES" "1"'

	INSERT INTO #TMP_LOG_ERRO (ERRO)
	EXEC MASTER.DBO.XP_CMDSHELL @CMD
	print @CMD

	INSERT INTO #TMP_AUXILIAR_IMPLANTACAO_NECESSIDADES
	SELECT	[index],
			NULLIF([0], ''),
			NULLIF([1], ''),
			NULLIF([2], ''),
			NULLIF([3], ''),
			NULLIF([4], ''),
			NULLIF([5], ''),
			NULLIF([6], ''),
			NULLIF([7], ''),
			NULLIF([8], ''),
			NULLIF([9], ''),
			NULLIF([10], ''),
			NULLIF([11], ''),
			NULLIF([12], ''),
			NULLIF([13], ''),
			NULLIF([14], ''),
			NULLIF([15], ''),
			NULLIF([16], ''),
			NULLIF([17], ''),
			NULLIF([18], ''),
			NULLIF([19], ''),
			NULLIF([20], ''),
			NULLIF([21], ''),
			NULLIF([22], ''),
			NULLIF([23], ''),
			NULLIF([24], '')
	FROM	[VAGAS_DW].[TMP_IMPLANTACAO_NECESSIDADES]
	WHERE	[index] > 0 ;

	-- Tratar erros ocorridos na rotina do Python	
	IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
	BEGIN 
		SET @MSG = 'ERRO ocorrido na importação dos dados no ID_CONTROLE_SPREADSHEET :' + ' ' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) 
		RAISERROR(@MSG , 16, 1) 
	END

	TRUNCATE TABLE #TMP_LOG_ERRO


	-- REMOÇÃO DE LINHAS EM BRANCO:
	DELETE	
	FROM	#TMP_AUXILIAR_IMPLANTACAO_NECESSIDADES
	WHERE	[DATA_RECEBIMENTO] IS NULL
			AND [EMAIL] IS NULL
			AND [NOME] IS NULL
			AND [EMPRESA] IS NULL
			AND [UNIDADE] IS NULL
			AND [UF] IS NULL
			AND [POSSUI_USUARIO] IS NULL
			AND [CRIAR_VAGAS] IS NULL
			AND [TRIAGEM_CVS_VAGAS] IS NULL
			AND [TRIAGEM_CVS_BCE] IS NULL
			AND [TRIAGEM_CVS_BCC] IS NULL
			AND [GESTAO_PROCESSO] IS NULL
			AND [FASES] IS NULL
			AND [VAGAS_MODELO] IS NULL
			AND [MENSAGENS_PADRONIZADAS] IS NULL
			AND [FEEDBACK_MANUAL] IS NULL
			AND [FEEDBACK_AUTOMATICO] IS NULL
			AND [CONTROLE_SLA] IS NULL
			AND [RELATORIOS] IS NULL
			AND [EVENTOS_PRESENCIAIS] IS NULL
			AND [ENVIO_TESTES_FICHAS] IS NULL
			AND [DISC] IS NULL
			AND [VIDEO_ENTREVISTA] IS NULL
			AND [SUGESTOES_COMENTARIOS] IS NULL
			AND [O_QUE_E_SUCESSO] IS NULL ;

	TRUNCATE TABLE [VAGAS_DW].[IMPLANTACAO_NECESSIDADES];

	INSERT INTO [VAGAS_DW].[IMPLANTACAO_NECESSIDADES]
	SELECT	ID,
			ISNULL([DATA_RECEBIMENTO], 'Não respondeu') AS [DATA_RECEBIMENTO],
			ISNULL([EMAIL], 'Não respondeu') AS [EMAIL],
			ISNULL([NOME], 'Não respondeu') AS [NOME],
			ISNULL([EMPRESA], 'Não respondeu') AS [EMPRESA],
			ISNULL([UNIDADE], 'Não respondeu') AS [UNIDADE],
			ISNULL([UF], 'Não respondeu') AS [UF],
			ISNULL([POSSUI_USUARIO], 'Não respondeu') AS [POSSUI_USUARIO],
			ISNULL([CRIAR_VAGAS], 'Não respondeu') AS [CRIAR_VAGAS],
			ISNULL([TRIAGEM_CVS_VAGAS], 'Não respondeu') AS [TRIAGEM_CVS_VAGAS],
			ISNULL([TRIAGEM_CVS_BCE], 'Não respondeu') AS [TRIAGEM_CVS_BCE],
			ISNULL([TRIAGEM_CVS_BCC], 'Não respondeu') AS [TRIAGEM_CVS_BCC],
			ISNULL([GESTAO_PROCESSO], 'Não respondeu') AS [GESTAO_PROCESSO],
			ISNULL([FASES], 'Não respondeu') AS [FASES],
			ISNULL([VAGAS_MODELO], 'Não respondeu') AS [VAGAS_MODELO],
			ISNULL([MENSAGENS_PADRONIZADAS], 'Não respondeu') AS [MENSAGENS_PADRONIZADAS],
			ISNULL([FEEDBACK_MANUAL], 'Não respondeu') AS [FEEDBACK_MANUAL],
			ISNULL([FEEDBACK_AUTOMATICO], 'Não respondeu') AS [FEEDBACK_AUTOMATICO],
			ISNULL([CONTROLE_SLA], 'Não respondeu') AS [CONTROLE_SLA],
			ISNULL([RELATORIOS], 'Não respondeu') AS [RELATORIOS],
			ISNULL([EVENTOS_PRESENCIAIS], 'Não respondeu') AS [EVENTOS_PRESENCIAIS],
			ISNULL([ENVIO_TESTES_FICHAS], 'Não respondeu') AS [ENVIO_TESTES_FICHAS],
			ISNULL([DISC], 'Não respondeu') AS [DISC],
			ISNULL([VIDEO_ENTREVISTA], 'Não respondeu') AS [VIDEO_ENTREVISTA],
			ISNULL([SUGESTOES_COMENTARIOS], 'Não respondeu') AS [SUGESTOES_COMENTARIOS],
			ISNULL([O_QUE_E_SUCESSO], 'Não respondeu') AS [O_QUE_E_SUCESSO]
	FROM	#TMP_AUXILIAR_IMPLANTACAO_NECESSIDADES AS A
	ORDER BY
			DATA_RECEBIMENTO ASC;


	-- LIMPEZA DAS TABELAS TEMPORÁRIAS LOCAIS:
	DROP TABLE #TMP_LOG_ERRO ;
	DROP TABLE #TMP_AUXILIAR_IMPLANTACAO_NECESSIDADES ;