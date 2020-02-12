-- select * from vagas_dw.TMP_VAGAS
-- EXEC VAGAS_DW.SPR_Carga_Vagas
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Vagas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Vagas
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimenta��o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Vagas

AS
SET NOCOUNT ON

DECLARE @DT_CARGA_INICIO SMALLDATETIME,
		@DT_CARGA_FIM SMALLDATETIME

SELECT @DT_CARGA_INICIO = MIN(DATA_ATUALIZACAO),
	   @DT_CARGA_FIM = DATEADD(DAY,1,MAX(DATA_ATUALIZACAO))	
FROM VAGAS_DW.TMP_VAGAS

UPDATE VAGAS_DW.VAGAS 
SET  VAGAS_Cod_Vaga = B.VAGAS_Cod_Vaga
	,COD_CLI = B.COD_CLI
	,CLIENTE = B.CLIENTE
	,CARGO = B.CARGO
	,ESCOLARIDADE = B.ESCOLARIDADE
	,NIVEL = B.NIVEL
	,CIDADE = B.CIDADE
	,UF = B.UF
	,PREF_SEXO = B.PREF_SEXO
	,AREA_01 = B.AREA_01
	,AREA_02 = B.AREA_02
	,AREA_03 = B.AREA_03
	,ACEITA_CAND_OUTRA_REGIAO = B.ACEITA_CAND_OUTRA_REGIAO
	,VAGA_VALIDADA = B.VAGA_VALIDADA
	,DATA_CADASTRAMENTO_SOURCE = B.DATA_CADASTRAMENTO_SOURCE
	,DATA_CADASTRAMENTO = B.DATA_CADASTRAMENTO
	,DATA_VALIDACAO_SOURCE = B.DATA_VALIDACAO_SOURCE
	,DATA_VALIDACAO = B.DATA_VALIDACAO
	,DATA_PUBLICACAO_SOURCE = B.DATA_PUBLICACAO_SOURCE
	,DATA_PUBLICACAO = B.DATA_PUBLICACAO
	,ACEITA_CAND_OUTRO_NIVEL = B.ACEITA_CAND_OUTRO_NIVEL
	,ACEITA_CAND_OUTRA_AREA = B.ACEITA_CAND_OUTRA_AREA
	,DISPONIB_VIAGEM = B.DISPONIB_VIAGEM
	,DATA_EXPIRACAO_SOURCE = B.DATA_EXPIRACAO_SOURCE
	,DATA_EXPIRACAO = B.DATA_EXPIRACAO
	,DATA_ULT_TRIAGEM_SOURCE = B.DATA_ULT_TRIAGEM_SOURCE
	,DATA_ULT_TRIAGEM = B.DATA_ULT_TRIAGEM
	,SOLICITA_PREENCHIMENTO_FICHA = B.SOLICITA_PREENCHIMENTO_FICHA
	,PCD = B.PCD
	,ANUNCIO_IDENTIFICADO = B.ANUNCIO_IDENTIFICADO
	,SEGMENTO = B.SEGMENTO
	,GRUPO_SEGMENTO = B.GRUPO_SEGMENTO
	,QTD_POSICOES = B.QTD_POSICOES
	,QTD_DIAS_ALERTADO = B.QTD_DIAS_ALERTADO
	,QTD_ALERTA_DISPARADO = B.QTD_ALERTA_DISPARADO
	,PERC_RETORNO = B.PERC_RETORNO
	,QTD_PageViews = B.QTD_PageViews
	,PAIS = B.PAIS
	,DATA_ATUALIZACAO_SOURCE = B.DATA_ATUALIZACAO_SOURCE
	,DATA_ATUALIZACAO = B.DATA_ATUALIZACAO
	,VEICULACAO_SUSPENSA = B.VEICULACAO_SUSPENSA
	,CLIENTE_BLOQUEADO = B.CLIENTE_BLOQUEADO
	,ATINGIU_LIMITE_CANDIDATURAS = B.ATINGIU_LIMITE_CANDIDATURAS
	,NAV_EXC = B.NAV_EXC
	,CAPTACAO_CONTINUA = B.CAPTACAO_CONTINUA
	,EXIBE_VAGAS_COM = B.EXIBE_VAGAS_COM
	,INVISIVEL = B.INVISIVEL
	,TIPO_PROCESSO = B.TIPO_PROCESSO
	,FLAG_VAGA_TESTE = B.FLAG_VAGA_TESTE
	,REGIAO = B.REGIAO
	,COD_FUNC = B.COD_FUNC
	,DIVISAO = B.DIVISAO
	,SOLICITA_TESTE = B.SOLICITA_TESTE
	,TESTE_OBRIGATORIO = B.TESTE_OBRIGATORIO
	,VAGAS_ETALENT = B.VAGAS_ETALENT
	,INDICACAO_VAGA = B.INDICACAO_VAGA
	,POSSUI_TESTE_CUSTOMIZADO = B.POSSUI_TESTE_CUSTOMIZADO
	,POSSUI_FICHA_COMPLEMENTAR = B.POSSUI_FICHA_COMPLEMENTAR
	,NOME_FUNC = B.NOME_FUNC
	,ORIGEM_VAGA_MODELO = B.ORIGEM_VAGA_MODELO
	,QTD_FICHAS_VAGA = B.QTD_FICHAS_VAGA
	,QTD_FICHAS_COMPLEMENTAR = B.QTD_FICHAS_COMPLEMENTAR
FROM VAGAS_DW.VAGAS A
	JOIN VAGAS_DW.TMP_VAGAS AS B ON A.VAGAS_Cod_Vaga = B.VAGAS_Cod_Vaga
	
DELETE VAGAS_DW.TMP_VAGAS 
FROM VAGAS_DW.TMP_VAGAS A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.VAGAS 
				WHERE VAGAS_Cod_Vaga = A.VAGAS_Cod_Vaga )	

-- Enriquecendo campos de CNAES:
UPDATE [VAGAS_DW].[TMP_VAGAS]
SET CNAE_SECAO_ID	= B.CNAE_SECAO_ID ,
	CNAE_SECAO		= B.CNAE_SECAO ,
	CNAE_DIVISAO_ID = B.CNAE_DIVISAO_ID ,
	CNAE_DIVISAO	= B.CNAE_DIVISAO ,
	CNAE_CLASSE_ID	= B.CNAE_CLASSE_ID ,
	CNAE_CLASSE		= B.CNAE_CLASSE ,
	CNAE_FAIXA_FUNCIONARIOS = B.CNAE_FAIXA_FUNCIONARIOS ,
	CNAE_SUBCLASSE_ID_C = B.CNAE_SUBCLASSE_ID_C ,
	CNAE_SUBCLASSE_DESCR_C = B.CNAE_SUBCLASSE_DESCR_C
FROM [VAGAS_DW].[TMP_VAGAS]	AS A	OUTER APPLY ( SELECT TOP 1 A1.CNAE_SECAO_ID ,
															   A1.CNAE_SECAO ,
															   A1.CNAE_DIVISAO_ID ,
															   A1.CNAE_DIVISAO ,
															   A1.CNAE_CLASSE_ID ,
															   A1.CNAE_CLASSE ,
															   A1.CNAE_FAIXA_FUNCIONARIOS ,
															   A1.CNAE_SUBCLASSE_ID_C ,
															   A1.CNAE_SUBCLASSE_DESCR_C
												  FROM [VAGAS_DW].[CLIENTES] AS A1
												  WHERE A.CLIENTE = A1.CLIENTE_VAGAS
														AND A1.DATA_REFERENCIA = (SELECT MAX(DATA_REFERENCIA) FROM [VAGAS_DW].[VAGAS_DW].[CLIENTES])) AS B
				
-- CARREGAR CUBO
INSERT INTO VAGAS_DW.VAGAS (VAGAS_Cod_Vaga,COD_CLI,CLIENTE,CARGO,ESCOLARIDADE,NIVEL,CIDADE,UF,PREF_SEXO,AREA_01,AREA_02,AREA_03,ACEITA_CAND_OUTRA_REGIAO,
VAGA_VALIDADA,DATA_CADASTRAMENTO_SOURCE,DATA_CADASTRAMENTO,DATA_VALIDACAO_SOURCE,DATA_VALIDACAO,DATA_PUBLICACAO_SOURCE,DATA_PUBLICACAO,
ACEITA_CAND_OUTRO_NIVEL,ACEITA_CAND_OUTRA_AREA,DISPONIB_VIAGEM,DATA_EXPIRACAO_SOURCE,DATA_EXPIRACAO,DATA_ULT_TRIAGEM_SOURCE,
DATA_ULT_TRIAGEM,SOLICITA_PREENCHIMENTO_FICHA,PCD,ANUNCIO_IDENTIFICADO,SEGMENTO,GRUPO_SEGMENTO,QTD_POSICOES,QTD_DIAS_ALERTADO,
QTD_ALERTA_DISPARADO,PERC_RETORNO,QTD_PageViews,PAIS,DATA_ATUALIZACAO_SOURCE,DATA_ATUALIZACAO,VEICULACAO_SUSPENSA,CLIENTE_BLOQUEADO,
ATINGIU_LIMITE_CANDIDATURAS,NAV_EXC,CAPTACAO_CONTINUA,EXIBE_VAGAS_COM,INVISIVEL,TIPO_PROCESSO,FLAG_VAGA_TESTE, CNAE_SECAO_ID, CNAE_SECAO, CNAE_DIVISAO_ID, CNAE_DIVISAO, CNAE_CLASSE_ID, CNAE_CLASSE, CNAE_FAIXA_FUNCIONARIOS,CNAE_SUBCLASSE_ID_C, CNAE_SUBCLASSE_DESCR_C,REGIAO, COD_FUNC, DIVISAO, SOLICITA_TESTE, TESTE_OBRIGATORIO, VAGAS_ETALENT, INDICACAO_VAGA,POSSUI_TESTE_CUSTOMIZADO, POSSUI_FICHA_COMPLEMENTAR,ORIGEM_VAGA_MODELO,QTD_FICHAS_VAGA,QTD_FICHAS_COMPLEMENTAR)
SELECT VAGAS_Cod_Vaga,COD_CLI,CLIENTE,CARGO,ESCOLARIDADE,NIVEL,CIDADE,UF,PREF_SEXO,AREA_01,AREA_02,AREA_03,ACEITA_CAND_OUTRA_REGIAO,
VAGA_VALIDADA,DATA_CADASTRAMENTO_SOURCE,DATA_CADASTRAMENTO,DATA_VALIDACAO_SOURCE,DATA_VALIDACAO,DATA_PUBLICACAO_SOURCE,DATA_PUBLICACAO,
ACEITA_CAND_OUTRO_NIVEL,ACEITA_CAND_OUTRA_AREA,DISPONIB_VIAGEM,DATA_EXPIRACAO_SOURCE,DATA_EXPIRACAO,DATA_ULT_TRIAGEM_SOURCE,
DATA_ULT_TRIAGEM,SOLICITA_PREENCHIMENTO_FICHA,PCD,ANUNCIO_IDENTIFICADO,SEGMENTO,GRUPO_SEGMENTO,QTD_POSICOES,QTD_DIAS_ALERTADO,
QTD_ALERTA_DISPARADO,PERC_RETORNO,QTD_PageViews,PAIS,DATA_ATUALIZACAO_SOURCE,DATA_ATUALIZACAO,VEICULACAO_SUSPENSA,CLIENTE_BLOQUEADO,
ATINGIU_LIMITE_CANDIDATURAS,NAV_EXC,CAPTACAO_CONTINUA,EXIBE_VAGAS_COM,INVISIVEL,TIPO_PROCESSO,FLAG_VAGA_TESTE, CNAE_SECAO_ID, CNAE_SECAO, CNAE_DIVISAO_ID, CNAE_DIVISAO, CNAE_CLASSE_ID, CNAE_CLASSE, CNAE_FAIXA_FUNCIONARIOS,CNAE_SUBCLASSE_ID_C, CNAE_SUBCLASSE_DESCR_C,REGIAO, COD_FUNC, DIVISAO, SOLICITA_TESTE, TESTE_OBRIGATORIO, VAGAS_ETALENT, INDICACAO_VAGA,POSSUI_TESTE_CUSTOMIZADO, POSSUI_FICHA_COMPLEMENTAR,ORIGEM_VAGA_MODELO,QTD_FICHAS_VAGA,QTD_FICHAS_COMPLEMENTAR
FROM VAGAS_DW.TMP_VAGAS

-- MARCAR VAGAS INATIVAS / ATIVAS
UPDATE VAGAS_DW.VAGAS SET VAGA_ATIVA = 'N�O'
FROM VAGAS_DW.VAGAS 
WHERE DATA_EXPIRACAO < CONVERT(SMALLDATETIME,CONVERT(VARCHAR,CASE WHEN DATEPART(WEEKDAY,GETDATE()) = 2 /* SEGUNDA */ 
																  THEN DATEADD(DAY,-3,GETDATE()) 
																  ELSE DATEADD(DAY,-1,GETDATE()) END,112))
AND ( VAGA_ATIVA IS NULL OR VAGA_ATIVA = 'SIM' )

UPDATE VAGAS_DW.VAGAS SET VAGA_ATIVA = 'N�O' 
FROM VAGAS_DW.VAGAS
WHERE VEICULACAO_SUSPENSA = 'SIM'
OR CLIENTE_BLOQUEADO = 'SIM'
OR ATINGIU_LIMITE_CANDIDATURAS = 'SIM'
OR INVISIVEL = 'SIM' 

UPDATE VAGAS_DW.VAGAS SET VAGA_ATIVA = 'SIM'
FROM VAGAS_DW.VAGAS 
WHERE VAGA_ATIVA IS NULL 

-- Limpeza dos campos referentes ao VAGAS FLIX:
UPDATE	[VAGAS_DW].[VAGAS]
SET		FLAG_EMPRESA_VAGAS_FLIX = NULL ,
		COD_CLI_VAGAS_FLIX = NULL ,
		ULT_DT_RF_VAGASFLIX = NULL ;


-- Atualiza��o da FLAG_EMPRES_VAGAS_FLIX:
UPDATE	[VAGAS_DW].[VAGAS]
SET		FLAG_EMPRESA_VAGAS_FLIX = (SELECT	1
								   FROM		[hrh-data].[dbo].[FranqueadorxFranqueado] AS A1		INNER JOIN [hrh-data].[dbo].[Clientes] AS A2 ON A1.codclifranqueado_fcf = A2.Cod_cli
																								INNER JOIN [hrh-data].[dbo].[Divisoes] AS A3 ON A1.coddivfranqueador_fcf = A3.Cod_div
								   WHERE	A1.cod_fcf = A.codfranqueado_vaga
											AND A1.codclifranqueador_fcf = 65561)
FROM	[hrh-data].[dbo].[Vagas] AS A	INNER JOIN [VAGAS_DW].[VAGAS] AS B ON A.Cod_vaga = B.VAGAS_COD_VAGA ;

UPDATE	[VAGAS_DW].[VAGAS]
SET		FLAG_EMPRESA_VAGAS_FLIX = 0
FROM	[VAGAS_DW].[VAGAS] AS A
WHERE	A.FLAG_EMPRESA_VAGAS_FLIX IS NULL ;



-- Atualiza��o do COD_CLI_VAGAS_FLIX:
UPDATE	[VAGAS_DW].[VAGAS]
SET		COD_CLI_VAGAS_FLIX = (SELECT	A3.Cod_cli AS COD_CLI_VAGAS_FLIX
							  FROM		[hrh-data].[dbo].[Vagas] AS A1	INNER JOIN [hrh-data].[dbo].[FranqueadorxFranqueado] AS A2 ON A1.codfranqueado_vaga = A2.cod_fcf
																		INNER JOIN [hrh-data].[dbo].[Clientes] AS A3 ON A2.codclifranqueado_fcf = A3.cod_cli
																		INNER JOIN [hrh-data].[dbo].[Divisoes] AS A4 ON A2.coddivfranqueador_fcf = A4.Cod_div
							  WHERE	A2.codclifranqueador_fcf = 65561
									AND A1.Cod_vaga = A.Cod_vaga)
FROM	[hrh-data].[dbo].[Vagas] AS A	INNER JOIN [VAGAS_DW].[VAGAS] AS B ON A.Cod_vaga = B.VAGAS_Cod_Vaga ;


-- Atualiza��o do campo ULT_DT_RF_VAGASFLIX:
DECLARE	@MAIOR_DATA_REF_CARGA_FLIX SMALLDATETIME ;
SET		@MAIOR_DATA_REF_CARGA_FLIX = (SELECT MAX(A1.DATA_REFERENCIA) FROM [VAGAS_DW].[BASE_EMPRESAS_VAGAS_FLIX] AS A1) ;

UPDATE	[VAGAS_DW].[VAGAS]
SET		ULT_DT_RF_VAGASFLIX = IIF(DATEPART(YEAR, A.DATA_CADASTRAMENTO) = DATEPART(YEAR, @MAIOR_DATA_REF_CARGA_FLIX)
								  AND DATEPART(MONTH, A.DATA_CADASTRAMENTO) = DATEPART(MONTH, @MAIOR_DATA_REF_CARGA_FLIX), 1, 0)
FROM	[VAGAS_DW].[VAGAS] AS A
WHERE	A.FLAG_EMPRESA_VAGAS_FLIX = 1 ;

UPDATE	[VAGAS_DW].[VAGAS]
SET		ULT_DT_RF_VAGASFLIX = 0
FROM	[VAGAS_DW].[VAGAS] AS A
WHERE	A.ULT_DT_RF_VAGASFLIX IS NULL ;

-- Atualiza��o do CNPJ dos clientes VAGAS FLIX:
UPDATE	[VAGAS_DW].[VAGAS]
SET		CNPJ_VAGAS_FLIX = (SELECT	A3.CGC_cli AS CNPJ_VAGAS_FLIX
						   FROM		[hrh-data].[dbo].[Vagas] AS A1	INNER JOIN [hrh-data].[dbo].[FranqueadorxFranqueado] AS A2 ON A1.codfranqueado_vaga = A2.cod_fcf
																	INNER JOIN [hrh-data].[dbo].[Clientes] AS A3 ON A2.codclifranqueado_fcf = A3.cod_cli
																	INNER JOIN [hrh-data].[dbo].[Divisoes] AS A4 ON A2.coddivfranqueador_fcf = A4.Cod_div
				  		   WHERE	A2.codclifranqueador_fcf = 65561
									AND A1.Cod_vaga = A.Cod_vaga)
FROM	[hrh-data].[dbo].[Vagas] AS A	INNER JOIN [VAGAS_DW].[VAGAS] AS B ON A.Cod_vaga = B.VAGAS_Cod_Vaga
WHERE	B.COD_CLI_VAGAS_FLIX IS NOT NULL ;


-- Atualiza��o do NOME_FANTASIA dos clientes VAGAS FLIX:
UPDATE	[VAGAS_DW].[VAGAS]
SET		NOME_FANTASIA_VAGASFLIX = B.NOME_FANTASIA
FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN [VAGAS_DW].[BASE_EMPRESAS_VAGAS_FLIX] AS B ON A.COD_CLI_VAGAS_FLIX = B.COD_CLI_VAGAS_EPARTNER ;

-- 13/10/2017: Tratamento de vagas da MagazineLuiza que excedem o volume de posi��es normalmente publicado pelas empresas:
UPDATE	[VAGAS_DW].[VAGAS]
SET		QTD_POSICOES = 1
FROM	[VAGAS_DW].[VAGAS] AS A
WHERE	A.VAGAS_Cod_Vaga IN (1462564, 1585461, 1506684, 1505748, 1483950, 1453337, 1517694, 1528982, 1518892, 1564768, 1458374, 1524462, 1539953, 1528189, 1532546, 1523707
, 1508158, 1535731, 1474097, 1470753, 1516049, 1523346, 1536257, 1518882, 1458563, 1518029, 1485367, 1462761, 1489707, 1538869, 1453781, 1456994, 1577664, 1470437, 1518712, 1506764, 1548150) ;

-- 14/11/2018: 
--------------------------------------------------------------
-- Ajuste pontual --> Vagas que est�o com o CodPais_vaga = -1:
--------------------------------------------------------------
UPDATE	[VAGAS_DW].[VAGAS]
SET		PAIS = 'Brasil'
FROM	[VAGAS_DW].[VAGAS] AS A
WHERE	 (A.VAGAS_COD_VAGA = 853804
			OR A.VAGAS_COD_VAGA =856261
			OR A.VAGAS_COD_VAGA = 853802
			OR A.VAGAS_COD_VAGA = 853803
			OR A.VAGAS_COD_VAGA = 853805
			OR A.VAGAS_COD_VAGA = 856258
			OR A.VAGAS_COD_VAGA = 856259
			OR A.VAGAS_COD_VAGA = 856260 )
		AND ISNULL(A.PAIS, '') = '' ;

	-------------------------------------------------------------------------------------------------------------------------
	-- Atualiza o TEMPO_DIAS_PUBL_CANDID (Intervalo em dias desde a data de publica��o da vaga at� a data da 1� candidatura):
	-------------------------------------------------------------------------------------------------------------------------
	-- DROP TABLE #TMP_PRM_CANDIDATURA ;
	CREATE TABLE #TMP_PRM_CANDIDATURA (
		COD_VAGA INT ,
		DATA_PRM_CANDIDATURA SMALLDATETIME ) ;

	INSERT INTO #TMP_PRM_CANDIDATURA (COD_VAGA, DATA_PRM_CANDIDATURA)
	SELECT	A.VAGAS_Cod_Vaga AS COD_VAGA ,
			MIN(B.DATA_CANDIDATURA) AS DATA_PRM_CANDIDATURA
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN [VAGAS_DW].[CANDIDATURAS] AS B ON A.VAGAS_Cod_Vaga = B.CodVaga_HistCand
	WHERE	A.DATA_PUBLICACAO >= '20140101'
			AND A.TEMPO_DIAS_PUBL_CANDID IS NULL
	GROUP BY
			A.VAGAS_Cod_vaga ;

	CREATE NONCLUSTERED INDEX IDX_#TMP_PRM_CANDIDATURA_COD_VAGA ON #TMP_PRM_CANDIDATURA (COD_VAGA) ;	

	DECLARE	@CONTROLE_UPDATE INT ;
	SET	@CONTROLE_UPDATE = ( SELECT	IIF((SELECT COUNT(*)
										 FROM	[VAGAS_DW].[VAGAS] AS A
										 WHERE	A.DATA_PUBLICACAO >= '20140101'
												AND A.TEMPO_DIAS_PUBL_CANDID IS NULL) > 100000, 100000, 10000)) ;

	DECLARE	@CONTROLE_DELAY CHAR(8) ;
	SET	@CONTROLE_DELAY = ( SELECT	IIF((SELECT COUNT(*)
										 FROM	[VAGAS_DW].[VAGAS] AS A
										 WHERE	A.DATA_PUBLICACAO >= '20140101'
												AND A.TEMPO_DIAS_PUBL_CANDID IS NULL) > 100000, '00:30:00', '00:00:10')) ;

	WHILE ( SELECT	TOP 1 1
			FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_PRM_CANDIDATURA AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
			WHERE	A.TEMPO_DIAS_PUBL_CANDID IS NULL ) = 1

	BEGIN
		UPDATE	TOP (@CONTROLE_UPDATE) [VAGAS_DW].[VAGAS]
		SET		TEMPO_DIAS_PUBL_CANDID = IIF(DATEDIFF(DAY, A.DATA_PUBLICACAO, B.DATA_PRM_CANDIDATURA) < 0,
												DATEDIFF(DAY, A.DATA_CADASTRAMENTO, B.DATA_PRM_CANDIDATURA),
												DATEDIFF(DAY, A.DATA_PUBLICACAO, B.DATA_PRM_CANDIDATURA))
		FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_PRM_CANDIDATURA AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
		WHERE	A.DATA_PUBLICACAO >= '20140101'
				AND A.TEMPO_DIAS_PUBL_CANDID IS NULL

		WAITFOR DELAY @CONTROLE_DELAY
	END ;

	-----------------------------------------------------------------------------------------------
	-- Atualiza o QTD_CAND_DESIST (Volume de candidatos que desistiram de confirmar a candidatura):
	-----------------------------------------------------------------------------------------------
	-- DROP TABLE #TMP_CANDIDATOS_DESISTENTES ;
	CREATE TABLE #TMP_CANDIDATOS_DESISTENTES (
		COD_VAGA INT ,
		QTD_CAND_DESIST_VAGAS INT ,
		QTD_CAND_DESIST_VAGAS_LOG INT ) ;


	INSERT INTO #TMP_CANDIDATOS_DESISTENTES(COD_VAGA, QTD_CAND_DESIST_VAGAS, QTD_CAND_DESIST_VAGAS_LOG)
	SELECT	A.CodVaga_cvlog AS COD_VAGA ,
			ISNULL(B.QTD_CAND_DESIST, 0) AS QTD_CAND_DESIST_VAGAS ,
			COUNT(*) AS QTD_CAND_DESIST_VAGAS_LOG
	FROM	[hrh-data].[dbo].[CandidatoxVagas_log] AS A		INNER JOIN [VAGAS_DW].[VAGAS] AS B ON A.CodVaga_cvlog = B.VAGAS_Cod_Vaga
	WHERE	A.DataCandFim_cvlog IS NULL
	GROUP BY
			A.CodVaga_cvlog ,
			ISNULL(B.QTD_CAND_DESIST, 0)
	HAVING COUNT(*) > ISNULL(B.QTD_CAND_DESIST, 0) ;
											
	CREATE NONCLUSTERED INDEX IDX_#TMP_CANDIDATOS_DESISTENTES_COD_VAGA ON #TMP_CANDIDATOS_DESISTENTES (COD_VAGA) ;

	DECLARE	@CONTROLE_UPDATE_QTD_CAND_DESIST INT ;
	SET	@CONTROLE_UPDATE_QTD_CAND_DESIST = ( SELECT	IIF((SELECT	COUNT(*)
														 FROM	#TMP_CANDIDATOS_DESISTENTES AS A) > 100000, 100000, 10000)) ;

	DECLARE	@CONTROLE_DELAY_QTD_CAND_DESIST CHAR(8) ;
	SET	@CONTROLE_DELAY_QTD_CAND_DESIST = ( SELECT	IIF((SELECT	COUNT(*)
														 FROM	#TMP_CANDIDATOS_DESISTENTES AS A) > 100000, '00:00:30', '00:00:10')) ;
	WHILE ( SELECT	TOP 1 1
			FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_CANDIDATOS_DESISTENTES AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
			WHERE	ISNULL(A.QTD_CAND_DESIST, 0) < B.QTD_CAND_DESIST_VAGAS_LOG) = 1

	BEGIN
		UPDATE	TOP (@CONTROLE_UPDATE_QTD_CAND_DESIST) [VAGAS_DW].[VAGAS]
		SET		QTD_CAND_DESIST = B.QTD_CAND_DESIST_VAGAS_LOG
		FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_CANDIDATOS_DESISTENTES AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
		WHERE	ISNULL(A.QTD_CAND_DESIST, 0) < B.QTD_CAND_DESIST_VAGAS_LOG

		WAITFOR DELAY @CONTROLE_DELAY_QTD_CAND_DESIST
	END ;

	------------------------------------
	-- Atualiza QTD_EMAILS_RECOMENDACAO:
	------------------------------------
	-- Identifica se � carga FULL ou incremental:
	IF ((SELECT COUNT(*)
		 FROM  [VAGAS_DW].[VAGAS] AS A
		 WHERE A.QTD_EMAILS_RECOMENDACAO IS NULL) = (SELECT COUNT(*)
													 FROM	[VAGAS_DW].[VAGAS]))
	TRUNCATE TABLE [VAGAS_DW].[CONTROLE_EMAILS_RECOMENDACAO] ;
	
	-- Levanta o �ltimo cruzamento da recomenda��o de vagas:
	DECLARE	@COD_ULT_CRUZAMENTO INT ;
	SET	@COD_ULT_CRUZAMENTO = ( SELECT	MAX(A.COD_ULT_CRUZAMENTO)
								FROM	[VAGAS_DW].[CONTROLE_EMAILS_RECOMENDACAO] AS A) ;

	-- C�digo m�ximo para ser processado, evitando de pegar um processamento em andamento bem como um c�digo maior do que um em andamento
	DECLARE	@COD_MAX_CRUZAMENTO INT ;
	SET	@COD_MAX_CRUZAMENTO = ( SELECT MIN(Cod_CzMonit) FROM [Recomendacao-Data].[dbo].[cruzamentoMonit] 
								WHERE Cod_CzMonit NOT IN (SELECT Cod_CzMonit FROM [Recomendacao-Data].[dbo].[cruzamentoMonit] WHERE datediff(day, cast(dataini_czmonit as date), cast(getdate() as date)) > 2 and DataFim_czMonit is null)
									AND DataFim_czMonit IS NULL AND Cod_CzMonit > @COD_ULT_CRUZAMENTO  ) ;										

	SELECT	CodCzMonit_czMonitVagaCand ,
			CodVaga_czMonitVagaCand
	INTO	#TMP_EMAILS_RECOMENDACAO
	FROM	[Recomendacao-Data].[dbo].[cruzamentoMonitxVagaXCand] AS A		INNER JOIN [Recomendacao-Data].[dbo].[cruzamentoMonit] AS B 
																			ON A.CodCzMonit_czMonitVagaCand = B.Cod_CzMonit
	WHERE	A.CodCzMonit_czMonitVagaCand > ISNULL(@COD_ULT_CRUZAMENTO, 0) 
			AND A.CodCzMonit_czMonitVagaCand < ISNULL(@COD_MAX_CRUZAMENTO,2147483647);


	CREATE NONCLUSTERED INDEX IDX_#TMP_EMAILS_RECOMENDACAO_CodVaga_czMonitVagaCand ON #TMP_EMAILS_RECOMENDACAO (CodVaga_czMonitVagaCand) ;
	CREATE NONCLUSTERED INDEX IDX_#TMP_EMAILS_RECOMENDACAO_CodCzMonit_czMonitVagaCand ON #TMP_EMAILS_RECOMENDACAO (CodCzMonit_czMonitVagaCand) ;

	SELECT	A.CodVaga_czMonitVagaCand AS COD_VAGA ,
			COUNT(*) AS QTD_EMAILS_RECOMENDACAO
	INTO	#TMP_EMAILS_RECOMENDACAO_VAGA
	FROM	#TMP_EMAILS_RECOMENDACAO AS A
	GROUP BY
			A.CodVaga_czMonitVagaCand ;

	CREATE NONCLUSTERED INDEX IDX_#TMP_EMAILS_RECOMENDACAO_VAGA_COD_VAGA ON #TMP_EMAILS_RECOMENDACAO_VAGA (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS_DW].[VAGAS]
	SET		QTD_EMAILS_RECOMENDACAO = ISNULL(A.QTD_EMAILS_RECOMENDACAO, 0) + B.QTD_EMAILS_RECOMENDACAO
	FROM	[VAGAS_DW].[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_EMAILS_RECOMENDACAO_VAGA AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA ;

	-- Insere o c�digo do �ltimo cruzamento pro e-mail de recomenda��o de vagas:
	IF (SELECT	COUNT(*)
		FROM	#TMP_EMAILS_RECOMENDACAO) <> 0
			
	INSERT INTO [VAGAS_DW].[CONTROLE_EMAILS_RECOMENDACAO] (COD_ULT_CRUZAMENTO)
	SELECT	MAX(A.CodCzMonit_czMonitVagaCand) AS COD_ULT_CRUZAMENTO
	FROM	#TMP_EMAILS_RECOMENDACAO AS A ;

	----------------------------------
	-- Atualiza QTD_VISUALIZACOES_CVS:
	----------------------------------
	SELECT	A.CodVaga_cvVisto AS COD_VAGA ,
			COUNT(*) AS QTD_VISUALIZACOES_CVs
	INTO	#TMP_VISUALIZACOES_CVs
	FROM	[hrh-data].[dbo].[Curriculo_Visto] AS A
	GROUP BY
			A.CodVaga_cvVisto ;

	CREATE NONCLUSTERED INDEX IDX_#TMP_VISUALIZACOES_CVs_COD_VAGA ON #TMP_VISUALIZACOES_CVs (COD_VAGA) ;


	DECLARE	@CONTROLE_UPDATE_QTD_VISUALIZACOES_CVS INT ;
	SET	@CONTROLE_UPDATE_QTD_VISUALIZACOES_CVS = IIF((SELECT COUNT(*)
													  FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_VISUALIZACOES_CVs AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
													  WHERE	ISNULL(A.QTD_VISUALIZACOES_CVS, 0) <> B.QTD_VISUALIZACOES_CVS) > 100000, 100000, 10000)

	DECLARE	@CONTROLE_DELAY_QTD_VISUALIZACOES_CVS CHAR(8) ;
	SET	@CONTROLE_DELAY_QTD_VISUALIZACOES_CVS = IIF((SELECT COUNT(*)
													  FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_VISUALIZACOES_CVs AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
													  WHERE	ISNULL(A.QTD_VISUALIZACOES_CVS, 0) <> B.QTD_VISUALIZACOES_CVS) > 100000, '00:00:30', '00:00:10')


	WHILE ( SELECT	TOP 1 1
			FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_VISUALIZACOES_CVs AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
			WHERE	ISNULL(A.QTD_VISUALIZACOES_CVs, 0) <> B.QTD_VISUALIZACOES_CVs ) = 1

	BEGIN
		UPDATE	TOP (@CONTROLE_UPDATE_QTD_VISUALIZACOES_CVS) [VAGAS_DW].[VAGAS]
		SET		QTD_VISUALIZACOES_CVs = B.QTD_VISUALIZACOES_CVs
		FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_VISUALIZACOES_CVs AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
		WHERE	ISNULL(A.QTD_VISUALIZACOES_CVs, 0) <> B.QTD_VISUALIZACOES_CVs
	
	WAITFOR DELAY @CONTROLE_DELAY_QTD_VISUALIZACOES_CVS
	END

	--------------------------------
	-- Atualiza QTD_ENVIO_CVs_EMAIL:
	--------------------------------
	-- DROP TABLE #TMP_ENVIO_CVs_EMAIL ;
	SELECT	B.CodVaga_email AS COD_VAGA ,
			COUNT(*) AS QTD_ENVIO_CVs_EMAIL
	INTO	#TMP_ENVIO_CVs_EMAIL
	FROM	[hrh-data].[dbo].[Clientes-Relatorios] AS A		INNER JOIN [hrh-data].[dbo].[Email] AS B ON A.Cod_rel = B.AnexoFmt_email
	WHERE	(A.IdFmt_rel = 'padr�o-program�vel'
			  OR A.IdFmt_rel = 'padr�o-confidencial'
			  OR A.IdFmt_rel = 'padr�o' )
	GROUP BY
			B.CodVaga_email ;

	CREATE NONCLUSTERED INDEX IDX_#TMP_ENVIO_CVs_EMAIL_COD_VAGA ON #TMP_ENVIO_CVs_EMAIL (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS]
	SET		QTD_ENVIO_CVs_EMAIL = B.QTD_ENVIO_CVs_EMAIL
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_ENVIO_CVs_EMAIL AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
	WHERE	ISNULL(A.QTD_ENVIO_CVs_EMAIL, 0) <> B.QTD_ENVIO_CVs_EMAIL ;

	------------------------------------
	-- Atualiza QTD_ANOTACOES_CAND_VAGA:
	------------------------------------
	-- DROP TABLE #TMP_ANOTACOES_CAND_VAGA ;
	SELECT	A.CodVaga_respCab AS COD_VAGA ,
			COUNT(*) AS QTD_ANOTACOES_CAND_VAGA 
	INTO	#TMP_ANOTACOES_CAND_VAGA
	FROM	[hrh-data].[dbo].[Fichas-RespCab] AS A		INNER JOIN [hrh-data].[dbo].[Fichas-DescrGeral] AS B ON A.CodFicha_RespCab = B.Cod_fic
	WHERE	B.Ident_fic = 'Anota��es candidato x vaga'
	GROUP BY
			A.CodVaga_respCab ;


	CREATE NONCLUSTERED INDEX IDX_#TMP_ANOTACOES_CAND_VAGA_COD_VAGA ON #TMP_ANOTACOES_CAND_VAGA (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS]
	SET		QTD_ANOTACOES_CAND_VAGA = B.QTD_ANOTACOES_CAND_VAGA
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_ANOTACOES_CAND_VAGA AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
	WHERE	ISNULL(A.QTD_ANOTACOES_CAND_VAGA, 0) <> B.QTD_ANOTACOES_CAND_VAGA ;


	-----------------------------------
	-- Atualiza��o do FEEDBACK_ENVIADO:
	-----------------------------------
	SELECT	A.CodVaga_vagAtrib AS COD_VAGA
	INTO	#TMP_FEEDBACK_ENVIADO_VAGA
	FROM	[hrh-data].[dbo].[Vagas_Atributos] AS A
	WHERE	A.CodAtrib_vagAtrib = 3 -- Feedback enviado

	CREATE NONCLUSTERED INDEX IDX_#TMP_FEEDBACK_ENVIADO_VAGA_COD_VAGA ON #TMP_FEEDBACK_ENVIADO_VAGA (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS]
	SET		FEEDBACK_ENVIADO = IIF(B.COD_VAGA IS NULL, 'N�O', 'SIM')
	FROM	[VAGAS_DW].[VAGAS] AS A		LEFT OUTER JOIN #TMP_FEEDBACK_ENVIADO_VAGA AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA ;


	------------------------------------------
	-- Atualiza��o do QTD_CANDIDATOS_FEEDBACK:
	------------------------------------------
	SELECT	A.CodVaga_hist AS COD_VAGA ,
			COUNT(DISTINCT A.CodCand_hist) AS QTD_CANDIDATOS_FEEDBACK
	INTO	#TMP_CANDIDATOS_FEEDBACK
	FROM	[hrh-data].[dbo].[Historico] AS A		INNER JOIN [hrh-data].[dbo].[Vagas] AS B ON A.CodVaga_hist = B.Cod_vaga
	WHERE	A.Tipo_hist  = -107 -- Mensagem enviada ao candidato
			AND A.Dt_hist > B.DtFechamento_vaga -- Data de envio da mensagem ao candidato posterior a data de fechamento da vaga.
			AND EXISTS ( SELECT	1
						 FROM	[hrh-data].[dbo].[Vagas_Atributos] AS A1
						 WHERE	A.CodVaga_hist = A1.Codvaga_vagAtrib
								AND A1.CodAtrib_vagAtrib = 3 )
	GROUP BY
			A.CodVaga_hist ;


	CREATE NONCLUSTERED INDEX IDX_#TMP_CANDIDATOS_FEEDBACK_COD_VAGA ON #TMP_CANDIDATOS_FEEDBACK (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS]
	SET		QTD_CANDIDATOS_FEEDBACK = B.QTD_CANDIDATOS_FEEDBACK
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_CANDIDATOS_FEEDBACK AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
	WHERE	ISNULL(A.QTD_CANDIDATOS_FEEDBACK, 0) <> B.QTD_CANDIDATOS_FEEDBACK ;

	--------------------------------------
	-- Atualiza VAGA_CANDIDATO_CONTRATADO:
	--------------------------------------
	SELECT	A.CodVaga_vagAtrib AS COD_VAGA
	INTO	#TMP_VAGA_CANDIDATO_CONTRATADO
	FROM	[hrh-data].[dbo].[Vagas_Atributos] AS A
	WHERE	A.CodAtrib_vagAtrib IN (1,2) ;

	CREATE NONCLUSTERED INDEX #TMP_VAGA_CANDIDATO_CONTRATADO_COD_VAGA ON #TMP_VAGA_CANDIDATO_CONTRATADO (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS]
	SET		VAGA_CANDIDATO_CONTRATADO = 'SIM'
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_VAGA_CANDIDATO_CONTRATADO AS B ON A.VAGAS_Cod_vaga = B.COD_VAGA ;

	------------------------------
	-- Atualiza FECHADA_CANDIDATO:
	------------------------------
	SELECT	DISTINCT A.CodVaga_vagAtrib AS COD_VAGA ,
		IIF ( (	  SELECT	COUNT(*)
							FROM		[hrh-data].[dbo].[Vagas_atributos] AS A1
							WHERE		A.CodVaga_vagAtrib = A1.CodVaga_vagAtrib
									AND A1.CodAtrib_vagAtrib IN (1, 2) ) > 1, 'INTERNO/EXTERNO',
									(	SELECT	IIF(CONVERT(VARCHAR, AA1.CodAtrib_vagAtrib) = 1, 'INTERNO', 'EXTERNO')
										FROM	[hrh-data].[dbo].[Vagas_atributos] AS AA1
										WHERE	A.CodVaga_vagAtrib = AA1.CodVaga_vagAtrib
												AND AA1.CodAtrib_vagAtrib IN (1,2) ) ) AS FECHADA_CANDIDATO
	INTO	#TMP_VAGA_FECHADA_CANDIDATO				  
	FROM	[hrh-data].[dbo].[Vagas_atributos] AS A
	WHERE	A.CodAtrib_vagAtrib IN (1, 2) ;


	CREATE NONCLUSTERED INDEX IDX_#TMP_VAGA_FECHADA_CANDIDATO_COD_VAGA ON #TMP_VAGA_FECHADA_CANDIDATO (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS]
	SET		FECHADA_CANDIDATO = B.FECHADA_CANDIDATO
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_VAGA_FECHADA_CANDIDATO AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA ;

	---------------------------------
	-- Atualiza QTD_CAND_CONTRATADOS:
	---------------------------------
	SELECT	A.CodVaga_CandCon AS COD_VAGA ,
			COUNT(*) AS QTD_CAND_CONTRATADOS
	INTO	#TMP_CANDIDATOS_CONTRATADOS
	FROM	[hrh-data].[dbo].[Candidatos_contratados] AS A
	GROUP BY
			A.CodVaga_CandCon ;

	CREATE NONCLUSTERED INDEX IDX_#TMP_CANDIDATOS_CONTRATADOS_COD_VAGA ON #TMP_CANDIDATOS_CONTRATADOS (COD_VAGA) ;

	UPDATE	[VAGAS_DW].[VAGAS]
	SET		QTD_CAND_CONTRATADOS = B.QTD_CAND_CONTRATADOS
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_CANDIDATOS_CONTRATADOS AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
	WHERE	ISNULL(A.QTD_CAND_CONTRATADOS, 0) <> B.QTD_CAND_CONTRATADOS ;


	-----------------------------------
	-- Atualiza TEMPO_DIAS_CONTRATACAO:
	-----------------------------------
	SELECT	A.CodVaga_CandCon AS COD_VAGA ,
			DATEDIFF(DAY,  ISNULL(B.DtPrimInicioWeb_vaga, B.DtInicioWeb_vaga) ,
							( SELECT	TOP 1 CONVERT(DATE, A1.Data_CandCon)
							  FROM		[hrh-data].[dbo].[Candidatos_contratados] AS A1
							  WHERE		A.CodVaga_CandCon = A1.CodVaga_CandCon
							  ORDER BY
										A1.Data_CandCon ASC )) AS TEMPO_DIAS_CONTRATACAO
	INTO	#TMP_TEMPO_DIAS_CONTRATACAO
	FROM	[hrh-data].[dbo].[Candidatos_contratados] AS A			INNER JOIN [hrh-data].[dbo].[Vagas] AS B ON A.CodVaga_CandCon = B.Cod_vaga ;

	CREATE NONCLUSTERED INDEX IDX_#TMP_TEMPO_DIAS_CONTRATACAO_COD_VAGA ON #TMP_TEMPO_DIAS_CONTRATACAO (COD_VAGA) ;


	UPDATE	[VAGAS_DW].[VAGAS]
	SET		TEMPO_DIAS_CONTRATACAO = B.TEMPO_DIAS_CONTRATACAO
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_TEMPO_DIAS_CONTRATACAO AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
	WHERE	ISNULL(A.TEMPO_DIAS_CONTRATACAO, 0) <> B.TEMPO_DIAS_CONTRATACAO ;
	
	
	-----------------------------------
	-- Atualiza QTD_PAGEVIEWS:
	-----------------------------------	
	
	UPDATE VAGAS_DW.VAGAS
	SET QTD_PAGEVIEWS = b.PageViews_vaga
	FROM [hrh-data].dbo.Vagas as b
	WHERE VAGAS_DW.VAGAS.VAGAS_Cod_Vaga = b.Cod_vaga
		AND VAGAS_DW.VAGAS.QTD_PageViews <> b.PageViews_vaga ;


-----------------------------------------------------------------------
-- Atualiza campos constru�dos a partir da tabela [HistoricoFasesCand]:
-----------------------------------------------------------------------
-- Identifica se � carga FULL ou incremental:
	IF ((SELECT	COUNT(*)
		 FROM	[VAGAS_DW].[VAGAS] AS A
		 WHERE	(A.QTD_AVALIACAO_CANDIDATOS IS NULL
				 AND A.AVALIOU_CANDIDATOS IS NULL
				 AND A.QTD_VAGAS_ELIMINOU_CAND IS NULL
				 AND A.ELIMINOU_CANDIDATOS IS NULL
				 AND A.QTD_CANDIDATOS_ELIMINADOS IS NULL
				 AND A.QTD_FASES_PROCESSO IS NULL
				 AND A.FASES_PROCESSO IS NULL)) = (SELECT COUNT(*)
												   FROM   [VAGAS_DW].[VAGAS]))
	TRUNCATE TABLE [VAGAS_DW].[CONTROLE_HISTORICO_FASES_CAND] ;


	-- Levanta o �ltimo c�digo de hist�rico de fases:
	DECLARE	@COD_ULT_HISTORICO_FASE INT ;
	SET	@COD_ULT_HISTORICO_FASE = ( SELECT	MAX(A.Cod_faseCand)
									FROM	[VAGAS_DW].[CONTROLE_HISTORICO_FASES_CAND] AS A) ;
									
	-- Levanta todos os registros das vagas com hist�rico posterior ao �ltimo c�digo de hist�rico de fases:
	SELECT	A.Cod_faseCand ,
			A.CodVaga_faseCand ,
			A.CodAval_faseCand ,
			A.Eliminado_faseCand ,
			A.CodFase_faseCand ,
			A.CodCand_faseCand
	INTO	#TMP_FASES_HISTORICO
	FROM	[hrh-data].[dbo].[HistoricoFasesCand] AS A
	--WHERE	A.Cod_faseCand > ISNULL(@COD_ULT_HISTORICO_FASE, 0) ;
	WHERE A.CodVaga_faseCand IN 	(SELECT DISTINCT A.CodVaga_faseCand
									FROM	[hrh-data].[dbo].[HistoricoFasesCand] AS A	
									WHERE	A.Cod_faseCand > ISNULL(@COD_ULT_HISTORICO_FASE, 0))

	CREATE NONCLUSTERED INDEX IDX_#TMP_FASES_HISTORICO_Cod_faseCand ON #TMP_FASES_HISTORICO (Cod_faseCand) ;
	CREATE NONCLUSTERED INDEX IDX_#TMP_FASES_HISTORICO_CodVaga_faseCand ON #TMP_FASES_HISTORICO (CodVaga_faseCand) ;
	CREATE NONCLUSTERED INDEX IDX_#TMP_FASES_HISTORICO_CodAval_faseCand ON #TMP_FASES_HISTORICO (CodAval_faseCand) ;
	CREATE NONCLUSTERED INDEX IDX_#TMP_FASES_HISTORICO_CodFase_faseCand ON #TMP_FASES_HISTORICO (CodFase_faseCand) ;

	-- Levanta os registros:
	-- DROP TABLE #TMP_FASES_HISTORICO_VAGA ;
	SELECT	A.CodVaga_faseCand AS COD_VAGA ,
			COUNT(CASE WHEN A.CodAval_faseCand > 0 OR A.CodAval_faseCand < 0 THEN A.CodVaga_faseCand ELSE NULL END) AS QTD_AVALIACAO_CANDIDATOS ,
			COUNT(DISTINCT CASE WHEN A.Eliminado_faseCand = 1 THEN A.CodCand_faseCand ELSE NULL END) AS QTD_CANDIDATOS_ELIMINADOS ,
			COUNT(DISTINCT A.CodFase_faseCand) AS QTD_FASES_PROCESSO ,
			CASE 
				 WHEN COUNT(DISTINCT A.CodFase_faseCand) = 1 THEN 'UMA (N�O MOVIMENTOU)'
				 WHEN COUNT(DISTINCT A.CodFase_faseCand) = 2 THEN 'DUAS (MOVIMENTOU)'
				 WHEN COUNT(DISTINCT A.CodFase_faseCand) >= 3 THEN 'MAIS DE DUAS (MOVIMENTOU)'
				 ELSE NULL
			END AS FASES_PROCESSO
	INTO	#TMP_FASES_HISTORICO_VAGA
	FROM	#TMP_FASES_HISTORICO AS A
	GROUP BY
			A.CodVaga_faseCand ;


	CREATE NONCLUSTERED INDEX IDX_#TMP_FASES_HISTORICO_VAGA_COD_VAGA ON #TMP_FASES_HISTORICO_VAGA (COD_VAGA) ;
	CREATE NONCLUSTERED INDEX IDX_#TMP_FASES_HISTORICO_VAGA_Cod_faseCand ON #TMP_FASES_HISTORICO (Cod_faseCand) ;


	UPDATE	[VAGAS_DW].[VAGAS]
	SET		QTD_AVALIACAO_CANDIDATOS = ISNULL(B.QTD_AVALIACAO_CANDIDATOS, 0),
			AVALIOU_CANDIDATOS = IIF(ISNULL(B.QTD_AVALIACAO_CANDIDATOS, 0) > 0, 'SIM', 'N�O') ,
			QTD_VAGAS_ELIMINOU_CAND = IIF(ISNULL(B.QTD_CANDIDATOS_ELIMINADOS, 0) > 0, 1, 0) ,
			ELIMINOU_CANDIDATOS = IIF(ISNULL(B.QTD_CANDIDATOS_ELIMINADOS, 0) > 0, 'SIM', 'N�O') ,
			QTD_CANDIDATOS_ELIMINADOS = ISNULL(B.QTD_CANDIDATOS_ELIMINADOS, 0),
			QTD_FASES_PROCESSO = ISNULL(B.QTD_FASES_PROCESSO, 0) ,
			FASES_PROCESSO = B.FASES_PROCESSO
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN #TMP_FASES_HISTORICO_VAGA AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA

	-- Insere o c�digo do �ltimo Cod_faseCand levantado anteriormente:
	IF (SELECT	COUNT(*)
		FROM	#TMP_FASES_HISTORICO_VAGA) <> 0

	INSERT INTO [VAGAS_DW].[CONTROLE_HISTORICO_FASES_CAND] (Cod_faseCand)
	SELECT	MAX(A.Cod_faseCand) AS Cod_faseCand
	FROM	#TMP_FASES_HISTORICO AS A ;


	-- Carga dos dados do Alerta Enviado na vaga:
	EXEC [VAGAS_DW].[SPR_OLTP_Carga_Controle_Alerta_de_Vagas] ;

	-- Atualiza os campos de envio do Alerta de Vagas:
	UPDATE	[VAGAS_DW].[VAGAS]
	SET		QTD_ALERTA_DISPARADO = B.QTD_ENVIO
	FROM	[VAGAS_DW].[VAGAS] AS A		INNER JOIN [VAGAS_DW].[CONTROLE_DISPAROS_ALERTA] AS B ON A.VAGAS_Cod_Vaga = B.COD_VAGA
	WHERE	ISNULL(A.QTD_ALERTA_DISPARADO, 0) < B.QTD_ENVIO ;