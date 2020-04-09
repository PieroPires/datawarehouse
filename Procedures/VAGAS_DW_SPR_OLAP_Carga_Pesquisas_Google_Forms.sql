-- =============================================
-- Author: Fiama
-- Create date: 23/11/2017
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Pesquisas_Google_Forms' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Pesquisas_Google_Forms]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Pesquisas_Google_Forms]

AS
SET NOCOUNT ON

-- LIMPAR TABELA FATO:
TRUNCATE TABLE [VAGAS_DW].[PESQUISAS_GOOGLE_FORMS] ;

-- LIMPAR TABELA STAGE:
TRUNCATE TABLE [STAGE].[VAGAS_DW].[TMP_PESQUISAS_GOOGLE_FORMS] ;

DECLARE	@CMD VARCHAR(8000) ,
			@MSG VARCHAR(8000)

	CREATE TABLE #TMP_LOG_ERRO (ID_LOG_ERRO SMALLINT IDENTITY PRIMARY KEY ,
								ERRO VARCHAR(8000)) ;

	CREATE TABLE #TMP_AUXILIAR_PESQUISAS_GOOGLE_FORMS (
		[DATA_RECEBIMENTO] VARCHAR(MAX) NULL,
		[EMAIL] VARCHAR(MAX) NULL ,
		[SOLICITACAO_ATENDIDA] CHAR(3) NULL,
		[NIVEL_SATISFACAO] VARCHAR(MAX) NULL,
		[ATENDENTE] VARCHAR(MAX) NULL ,
		[PESQUISA] VARCHAR(100));


	DECLARE	@ID_CONTROLE_SPREADSHEET SMALLINT ,
		@SHEET_NAME VARCHAR(100) , 
		@NOME_CONTROLE VARCHAR(100) ;

	SET	@ID_CONTROLE_SPREADSHEET = (SELECT	MIN(ID_CONTROLE_SPREADSHEET)
									FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
									WHERE	NOME_CONTROLE = 'SUPORTE A EMPRESAS'
											AND SHEET_NAME = 'Respostas ao formul�rio 1') ;

	SET	@SHEET_NAME = (SELECT TOP 1 SHEET_NAME
					   FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
					   WHERE NOME_CONTROLE = 'SUPORTE A EMPRESAS'
							AND SHEET_NAME = 'Respostas ao formul�rio 1') 

	SET @NOME_CONTROLE = (SELECT TOP 1 NOME_CONTROLE
						  FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
						  WHERE	NOME_CONTROLE = 'Respostas ao formul�rio 1')

	WHILE @ID_CONTROLE_SPREADSHEET IN (SELECT ID_CONTROLE_SPREADSHEET FROM [VAGAS_DW].[CONTROLE_SPREADSHEET] WHERE NOME_CONTROLE = 'SUPORTE A EMPRESAS' AND SHEET_NAME = 'Respostas ao formul�rio 1')
	BEGIN
		
		-- Carregar tabela baseado na Planilha do Google Drive
		SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py ' + 
				' "' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) + '" "TMP_PESQUISAS_GOOGLE_FORMS" "1"'


		INSERT INTO #TMP_LOG_ERRO (ERRO)
		EXEC MASTER.DBO.XP_CMDSHELL @CMD
		print @CMD

		INSERT INTO #TMP_AUXILIAR_PESQUISAS_GOOGLE_FORMS
		SELECT	[0],[3],[4],[5],[8], @SHEET_NAME
		FROM	[STAGE].[VAGAS_DW].[TMP_PESQUISAS_GOOGLE_FORMS]
		WHERE	[index] > 0 ;

		-- Tratar erros ocorridos na rotina do Python	
		IF EXISTS ( SELECT * FROM #TMP_LOG_ERRO WHERE CHARINDEX('ERROR_MESSAGE',ERRO) > 0 ) 
		BEGIN 
			SET @MSG = 'ERRO ocorrido na importa��o dos dados no ID_CONTROLE_SPREADSHEET :' + ' ' + CONVERT(VARCHAR(3), @ID_CONTROLE_SPREADSHEET) 
			RAISERROR(@MSG , 16, 1) 
		END

		TRUNCATE TABLE #TMP_LOG_ERRO


		SET @ID_CONTROLE_SPREADSHEET +=	(SELECT TOP 1 (ID_CONTROLE_SPREADSHEET - @ID_CONTROLE_SPREADSHEET)
										 FROM	[VAGAS_DW].[CONTROLE_SPREADSHEET]
										 WHERE	NOME_CONTROLE = 'SUPORTE A EMPRESAS'
												AND SHEET_NAME = 'Respostas ao formul�rio 1'
												AND ID_CONTROLE_SPREADSHEET > @ID_CONTROLE_SPREADSHEET)

		SET @SHEET_NAME = (SELECT TOP 1 SHEET_NAME
						   FROM	  [VAGAS_DW].[CONTROLE_SPREADSHEET]
						   WHERE  NOME_CONTROLE = 'SUPORTE A EMPRESAS'
								  AND ID_CONTROLE_SPREADSHEET = @ID_CONTROLE_SPREADSHEET)
	END

		
	-- REMO��O DE LINHAS EM BRANCO:
	DELETE	FROM #TMP_AUXILIAR_PESQUISAS_GOOGLE_FORMS
	FROM	#TMP_AUXILIAR_PESQUISAS_GOOGLE_FORMS
	WHERE	ISNULL(DATA_RECEBIMENTO, '') = '' 
			AND ISNULL(EMAIL, '') = '' 
			AND ISNULL(SOLICITACAO_ATENDIDA, '') = '' 
			AND ISNULL(NIVEL_SATISFACAO, '') = '' 
			AND ISNULL(ATENDENTE, '') = '' ;

	-- FORMATO DATA_RECEBIMENTO:
	UPDATE	[STAGE].[VAGAS_DW].[TMP_PESQUISAS_GOOGLE_FORMS]
	SET		[0] = CONVERT(CHAR(10), [0]) ;


INSERT INTO [VAGAS_DW].[PESQUISAS_GOOGLE_FORMS] (DATA_RECEBIMENTO,EMAIL,SOLICITACAO_ATENDIDA,NIVEL_SATISFACAO,ATENDENTE,PESQUISA,CLIENTE_VAGAS,MERCADO,EX_CLIENTE,CLASSIFICACAO_NIVEL,TIPO,SUB_TIPO,ORIGEM)
SELECT	
		CASE WHEN LEN(LTRIM(RTRIM(REPLACE(REVERSE(SUBSTRING(REVERSE([0]), 1, CHARINDEX('/', REVERSE([0])))), '/', '')))) = 4 AND CONVERT(SMALLINT, LTRIM(RTRIM(REPLACE(REVERSE(SUBSTRING(REVERSE([0]), 1, CHARINDEX('/', REVERSE([0])))), '/', '')))) BETWEEN 2000 AND 2100 AND LEN(LTRIM(RTRIM(SUBSTRING([0], 4, 2))))= 2 AND CONVERT(SMALLINT, LTRIM(RTRIM(SUBSTRING([0], 4, 2)))) BETWEEN 1 AND 12 AND LEN(LTRIM(RTRIM(SUBSTRING([0], 1, 2)))) = 2 AND CONVERT(SMALLINT, LTRIM(RTRIM(SUBSTRING([0], 1, 2)))) BETWEEN 1 AND 31 THEN DATEFROMPARTS(CONVERT(SMALLINT, LTRIM(RTRIM(REPLACE(REVERSE(SUBSTRING(REVERSE([0]), 1, CHARINDEX('/', REVERSE([0])))), '/', '')))), CONVERT(SMALLINT, LTRIM(RTRIM(SUBSTRING([0], 4, 2)))), CONVERT(SMALLINT, LTRIM(RTRIM(SUBSTRING([0], 1, 2))))) END AS DATA_RECEBIMENTO ,
		[3] AS EMAIL ,
		[4] AS SOLICITACAO_ATENDIDA ,
		[5] AS NIVEL_SATISFACAO ,
		IIF([8] = 'Felipe Duarte Concei??o', 'Felipe Duarte Concei��o', [8]) AS ATENDENTE ,
		'Pesquisa de Satisfa��o - Suporte a Empresas' AS PESQUISA ,
		B.CLIENTE_VAGAS ,
		ISNULL(UPPER(B.MERCADO), 'EM BRANCO') AS MERCADO ,
		IIF(B.EX_CLIENTE = 1, 'SIM', 'N�O') AS EX_CLIENTE ,
		CASE
			WHEN [5] BETWEEN 0 AND 7
				THEN 'INSATISFEITO (0-7)'
			WHEN [5] BETWEEN 8 AND 9
				THEN 'SATISFEITO (8-9)'
			WHEN [5] = 10
				THEN 'TOTALMENTE SATISFEITO (10)'
		END AS CLASSIFICACAO_NIVEL ,
		C.TIPO ,
		C.SUB_TIPO ,
		C.ORIGEM
FROM	[STAGE].[VAGAS_DW].[TMP_PESQUISAS_GOOGLE_FORMS] AS A	
												LEFT OUTER JOIN [VAGAS_DW].[CLIENTES] AS B ON LTRIM(RTRIM(REPLACE(SUBSTRING(REPLACE(REVERSE(SUBSTRING(REVERSE(LTRIM(RTRIM([3]))), 1, CHARINDEX('@', REVERSE(LTRIM(RTRIM([3])))))), '@', ''), 1, CHARINDEX('.', REPLACE(REVERSE(SUBSTRING(REVERSE(LTRIM(RTRIM([3]))), 1, CHARINDEX('@', REVERSE(LTRIM(RTRIM([3])))))), '@', ''))), '.', ''))) COLLATE SQL_Latin1_General_CP1_CI_AS = B.CLIENTE_VAGAS COLLATE SQL_Latin1_General_CP1_CI_AS
												OUTER APPLY (SELECT	TOP 1 A1.TIPO ,
																		  A1.SUB_TIPO ,
																		  A1.ORIGEM
															 FROM	[VAGAS_DW].[CASOS] AS A1
															 WHERE	[1] = A1.EMAIL_CONTATO
															 ORDER BY
																	A1.DATA_FECHAMENTO DESC) AS C
WHERE	[index] > 0 ;


-- LIMPEZA DAS TABELAS TEMPOR�RIAS LOCAIS:
DROP TABLE #TMP_LOG_ERRO ;
DROP TABLE #TMP_AUXILIAR_PESQUISAS_GOOGLE_FORMS ;



-- N�o exibir na interface:
DELETE	FROM [VAGAS_DW].[PESQUISAS_GOOGLE_FORMS]
FROM	[VAGAS_DW].[PESQUISAS_GOOGLE_FORMS] AS A
WHERE	A.EMAIL = 'jucineia.rodrigues@kroton.com.br'
		AND A.DATA_RECEBIMENTO = '2019-01-16 00:00:00' ;