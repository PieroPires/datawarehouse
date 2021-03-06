USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Candidatos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidatos
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimenta??o do DW
-- =============================================

-- =============================================
-- Altera??es
-- 05/02/2020 - Diego Gatto - Ajustado para utilizar as tabelas TMP na base de dados stage e n?o vagas_dw
-- =============================================


CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidatos
@DT_ATUALIZACAO_INICIO SMALLDATETIME = NULL,
@DT_ATUALIZACAO_FIM SMALLDATETIME = NULL 

AS
SET NOCOUNT ON

DELETE VAGAS_DW.CANDIDATOS 
FROM VAGAS_DW.CANDIDATOS A
WHERE EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
				WHERE COD_CAND = A.COD_CAND )

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CANDIDATOS
SELECT * FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]

DELETE VAGAS_DW.CANDIDATOS_AREA_INTERESSE 
FROM VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
WHERE EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
				WHERE COD_CAND = A.COD_CAND )

-- CARREGAR CUBO DE "AREAS DE INTERESSE"
INSERT INTO VAGAS_DW.CANDIDATOS_AREA_INTERESSE
SELECT Cod_Cand,AREA_INTERESSE_1 AS AREA_INTERESSE,1 AS ORDEM_AREA
FROM VAGAS_DW.CANDIDATOS A
WHERE AREA_INTERESSE_1 IS NOT NULL
AND EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
			 WHERE COD_CAND = A.COD_CAND )

UNION ALL

SELECT Cod_Cand,AREA_INTERESSE_2,2 AS ORDEM_AREA
FROM VAGAS_DW.CANDIDATOS A
WHERE AREA_INTERESSE_2 IS NOT NULL
AND EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
			 WHERE COD_CAND = A.COD_CAND )

UNION ALL

SELECT Cod_Cand,AREA_INTERESSE_3,3 AS ORDEM_AREA
FROM VAGAS_DW.CANDIDATOS A
WHERE AREA_INTERESSE_3 IS NOT NULL
AND EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
			 WHERE COD_CAND = A.COD_CAND )

UNION ALL

SELECT Cod_Cand,AREA_INTERESSE_4,4 AS ORDEM_AREA
FROM VAGAS_DW.CANDIDATOS A
WHERE AREA_INTERESSE_4 IS NOT NULL
AND EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
			 WHERE COD_CAND = A.COD_CAND )

UNION ALL

SELECT Cod_Cand,AREA_INTERESSE_5,5 AS ORDEM_AREA
FROM VAGAS_DW.CANDIDATOS A
WHERE AREA_INTERESSE_5 IS NOT NULL
AND EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
			 WHERE COD_CAND = A.COD_CAND )

-- Atualiza a FLAG REMOVIDO_CAND, no caso de CVs que foram removidos:
UPDATE	[VAGAS_DW].[VAGAS_DW].[CANDIDATOS]
SET		REMOVIDO_CAND = 1 ,
		DATA_REMOCAO = ( SELECT	A1.Data_candREM
						 FROM	[hrh-data].[dbo].[Cand-REM] AS A1
						 WHERE	A.COD_CAND = A1.CodCand_candREM )
FROM	[VAGAS_DW].[VAGAS_DW].[CANDIDATOS] AS A
WHERE	EXISTS (SELECT	1
				FROM	[hrh-data].[dbo].[Cand-REM] AS A1
				WHERE	A.COD_CAND = A1.CodCand_CandREM)
		AND ISNULL(A.REMOVIDO_CAND, 0) = 0 ;

-- Atualiza a FLAG REMOVIDO_CAND, para casos em que o CV n?o foi removido:
UPDATE	[VAGAS_DW].[VAGAS_DW].[CANDIDATOS]
SET		REMOVIDO_CAND = 0
FROM	[VAGAS_DW].[VAGAS_DW].[CANDIDATOS] AS A
WHERE	NOT EXISTS (SELECT	1
					FROM	[hrh-data].[dbo].[Cand-REM] AS A1
					WHERE	A.COD_CAND = A1.CodCand_CandREM)
		AND A.REMOVIDO_CAND IS NULL ;

-- Atualiza o CPF dos curr?culos removidos (Este dado ? removido da tabela de candidatos no processo de remo??o (via Manut)):
UPDATE	[VAGAS_DW].[VAGAS_DW].[CANDIDATOS]
SET		CPF = ( SELECT	A1.CPF_candREM
				FROM	[hrh-data].[dbo].[Cand-REM] AS A1
				WHERE	A.COD_CAND = A1.CodCand_candREM
						AND ISNULL(A1.CPF_candREM, '') <> '' )
FROM	[VAGAS_DW].[VAGAS_DW].[CANDIDATOS] AS A
WHERE	A.REMOVIDO_CAND = 1
		AND A.CPF IS NULL ;
		

-- Atualiza a FLAG CV_REMOVIDO_RETORNOU, e o TEMPO_PERMANENCIA_MESES:
UPDATE	[VAGAS_DW].[CANDIDATOS]
SET		CV_REMOVIDO_RETORNOU = IIF(A.CPF IN (	SELECT	A1.CPF
												FROM	[VAGAS_DW].[CANDIDATOS] AS A1
												WHERE	A.COD_CAND <> A1.COD_CAND
														AND A1.DATA_CADASTRO_SOURCE >= A.DATA_REMOCAO ), 'SIM', 'N?O') ,
		TEMPO_PERMANENCIA_MESES = CASE
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) = 0
										THEN 'MENOS DE 1 M?S'
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) BETWEEN 1 AND 6
										THEN '1 A 6 MESES'
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) BETWEEN 7 AND 12
										THEN '7 A 12 MESES'
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) BETWEEN 13 AND 18
										THEN '13 A 18 MESES'
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) BETWEEN 19 AND 24
										THEN '19 A 24 MESES'
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) BETWEEN 25 AND 30
										THEN '25 A 30 MESES'
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) BETWEEN 31 AND 36
										THEN '31 A 36 MESES'
									WHEN DATEDIFF(MONTH, A.DATA_CADASTRO_SOURCE, A.DATA_REMOCAO) > 36
										THEN 'MAIS DE 36 MESES'
									ELSE  NULL
								END
FROM	[VAGAS_DW].[CANDIDATOS] AS A
WHERE	A.REMOVIDO_CAND = 1 ;



-- ATUALIZA??O DO HASH (QUE ? ENVIADO ? TAIL)
UPDATE VAGAS_DW.CANDIDATOS SET HASH = LOWER(CONVERT(VARCHAR(MAX), HASHBYTES('SHA2_256',LOWER(CONVERT(VARCHAR,EMAIL))), 2))
WHERE FEZ_ACESSO_IRRESTRITO = 1
AND HASH IS NULL
AND EMAIL IS NOT NULL 


-- Agrupamento dos cargos para a Equipe do FLIX:

-- TESTA SE ? ATUALIZA??O DE CARGA FULL
IF @DT_ATUALIZACAO_INICIO IS NOT NULL
	UPDATE	[VAGAS_DW].[CANDIDATOS]
	SET		GRUPO_ULTIMO_CARGO = CASE
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Vendedor%'
										THEN 'Vendedor'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Repositor%'
										THEN 'Repositor'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Auxiliar%limpeza%'
										THEN 'Auxiliar de limpeza'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Operador%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Caixa%Loja%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Balconista%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Operadora%Comercial%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE 'Vendedor%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Chefe%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Operador%Supermercado%'
										THEN 'Operador de caixa'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%recep%'
										THEN 'Recepcionista'
									ELSE 'OUTRO'
								END
	FROM	[VAGAS_DW].[CANDIDATOS] AS A
	WHERE	(A.DATA_ULT_ATUALIZACAO_SOURCE >= @DT_ATUALIZACAO_INICIO
			 AND A.DATA_ULT_ATUALIZACAO_SOURCE < @DT_ATUALIZACAO_FIM)
			OR A.GRUPO_ULTIMO_CARGO IS NULL 

ELSE
	UPDATE	[VAGAS_DW].[CANDIDATOS]
	SET		GRUPO_ULTIMO_CARGO =  CASE
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Vendedor%'
										THEN 'Vendedor'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Repositor%'
										THEN 'Repositor'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Auxiliar%limpeza%'
										THEN 'Auxiliar de limpeza'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Operador%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Caixa%Loja%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Balconista%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Operadora%Comercial%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE 'Vendedor%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Chefe%Caixa%' OR LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%Operador%Supermercado%'
										THEN 'Operador de caixa'
									WHEN LTRIM(RTRIM(A.ULTIMO_CARGO)) LIKE '%recep%'
										THEN 'Recepcionista'
									ELSE 'OUTRO'
								END
	FROM	[VAGAS_DW].[CANDIDATOS] AS A ;


-- Atualiza a data de ?ltimo login:
CREATE TABLE #TMP_CANDIDATO_LOGIN (CodCand_logCand INT,Data_logCand DATETIME) ;

INSERT INTO #TMP_CANDIDATO_LOGIN 
SELECT	A.CodCand_logCand ,
		MAX(A.Data_logCand) AS Data_logCand
FROM	[hrh-data].dbo.[Candidatos-Login] A
GROUP BY CodCand_logCand ;

-- ?ndice:
CREATE NONCLUSTERED INDEX IDX_#TMP_CANDIDATO_LOGIN_COD_CAND ON #TMP_CANDIDATO_LOGIN (CodCand_logCand) ;

-- Atualiza a data de ?ltimo login do candidato:
UPDATE	[VAGAS_DW].[CANDIDATOS]
SET		DATA_ULT_LOGIN_SOURCE = ISNULL(B.Data_logCand, '19000101') ,
		DATA_ULT_LOGIN = ISNULL(CONVERT(DATE, B.Data_logCand), '19000101')
FROM	[VAGAS_DW].[CANDIDATOS] AS A		INNER JOIN #TMP_CANDIDATO_LOGIN AS B ON A.COD_CAND = B.CodCand_logCand ;

-- CARREGAR CUBO DE IDIOMAS

DELETE VAGAS_DW.CANDIDATOS_IDIOMA 
FROM VAGAS_DW.CANDIDATOS_IDIOMA A
WHERE EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
				WHERE COD_CAND = A.COD_CAND )
			 
INSERT INTO VAGAS_DW.CANDIDATOS_IDIOMA
SELECT a.cod_cand, z.descr_idioma as idioma, c.Nivel_fluencia as nivel, c.cod_fluencia as nivel_ordem
FROM VAGAS_DW.CANDIDATOS AS A
	LEFT OUTER JOIN [hrh-data].[dbo].[Cand-idiomas] AS B ON A.Cod_cand = B.CodCand_idiomaCand
	LEFT OUTER JOIN [hrh-data].[dbo].[Cad_fluencias] AS C ON B.Nconv_idiomaCand = C.Cod_fluencia
	LEFT OUTER JOIN [hrh-data].[dbo].[Cad_idiomas] AS Z on z.cod_idioma = b.cod_idiomacand
WHERE descr_idioma IS NOT NULL
	AND cod_fluencia > 1
	AND EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS]
				 WHERE COD_CAND = A.COD_CAND )



-- Popula a tabela que alimenta o Cubo Candidatos_Defici?ncias:
DELETE FROM [VAGAS_DW].[CANDIDATOS_DEFICIENCIAS]
FROM	[VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] AS A
WHERE	EXISTS ( SELECT 1
				 FROM	[STAGE].[VAGAS_DW].[TMP_CANDIDATOS] AS A1
				 WHERE	A.Cod_cand = A1.COD_CAND ) ;


INSERT INTO [VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] (Cod_cand, TipoDeficiencia)
SELECT	A.CodCand_necEsp AS Cod_cand ,
		'Auditiva' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Auditiva_necEsp > -1
		AND EXISTS ( SELECT 1
					 FROM	[STAGE].[VAGAS_DW].[TMP_CANDIDATOS] AS A1
					 WHERE	A.CodCand_necEsp = A1.Cod_cand )
UNION ALL
SELECT	A.CodCand_necEsp ,
		'Fala' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Fala_necEsp > -1
		AND EXISTS ( SELECT 1
					 FROM	[STAGE].[VAGAS_DW].[TMP_CANDIDATOS] AS A1
					 WHERE	A.CodCand_necEsp = A1.Cod_cand )	
UNION ALL
SELECT	A.CodCand_necEsp ,
		'F?sica' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Fisica_necEsp > -1
		AND EXISTS ( SELECT 1
					 FROM	[STAGE].[VAGAS_DW].[TMP_CANDIDATOS] AS A1
					 WHERE	A.CodCand_necEsp = A1.Cod_cand )
UNION ALL
SELECT	A.CodCand_necEsp ,
		'Mental' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Mental_necEsp > -1
		AND EXISTS ( SELECT 1
					 FROM	[STAGE].[VAGAS_DW].[TMP_CANDIDATOS] AS A1
					 WHERE	A.CodCand_necEsp = A1.Cod_cand )
UNION ALL
SELECT	A.CodCand_necEsp ,
		'Visual' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Visual_necEsp > -1
		AND EXISTS ( SELECT 1
					 FROM	[STAGE].[VAGAS_DW].[TMP_CANDIDATOS] AS A1
					 WHERE	A.CodCand_necEsp = A1.Cod_cand ) ;

-- Insere candidatos na Candidatos_deficiencias que deveriam existir:
INSERT INTO [VAGAS_DW].[CANDIDATOS_DEFICIENCIAS]
SELECT	A.CodCand_necEsp AS Cod_cand ,
		'Auditiva' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Auditiva_necEsp > -1
		AND EXISTS (SELECT *
					FROM	[VAGAS_DW].[CANDIDATOS] AS CandDW
					WHERE	A.CodCand_NecEsp = CandDW.COD_CAND
							AND CandDW.POSSUI_DEFIC = 'SIM')
		AND NOT EXISTS (SELECT *
						FROM	[VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] AS CandDef
						WHERE	A.CodCand_NecEsp = CandDef.COD_CAND
								AND CandDef.TipoDeficiencia = 'Auditiva')
UNION ALL
SELECT	A.CodCand_necEsp AS Cod_cand ,
		'Fala' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Fala_necEsp > -1
		AND EXISTS (SELECT *
					FROM	[VAGAS_DW].[CANDIDATOS] AS CandDW
					WHERE	A.CodCand_NecEsp = CandDW.COD_CAND
							AND CandDW.POSSUI_DEFIC = 'SIM')
		AND NOT EXISTS (SELECT *
						FROM	[VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] AS CandDef
						WHERE	A.CodCand_NecEsp = CandDef.COD_CAND
								AND CandDef.TipoDeficiencia = 'Fala')
UNION ALL
SELECT	A.CodCand_necEsp AS Cod_cand ,
		'F?sica' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Fisica_necEsp > -1
		AND EXISTS (SELECT *
					FROM	[VAGAS_DW].[CANDIDATOS] AS CandDW
					WHERE	A.CodCand_NecEsp = CandDW.COD_CAND
							AND CandDW.POSSUI_DEFIC = 'SIM')
		AND NOT EXISTS (SELECT *
						FROM	[VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] AS CandDef
						WHERE	A.CodCand_NecEsp = CandDef.COD_CAND
								AND CandDef.TipoDeficiencia = 'F?sica')
UNION ALL
SELECT	A.CodCand_necEsp AS Cod_cand ,
		'Mental' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Mental_necEsp > -1
		AND EXISTS (SELECT *
					FROM	[VAGAS_DW].[CANDIDATOS] AS CandDW
					WHERE	A.CodCand_NecEsp = CandDW.COD_CAND
							AND CandDW.POSSUI_DEFIC = 'SIM')
		AND NOT EXISTS (SELECT *
						FROM	[VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] AS CandDef
						WHERE	A.CodCand_NecEsp = CandDef.COD_CAND
								AND CandDef.TipoDeficiencia = 'Mental')
UNION ALL
SELECT	A.CodCand_necEsp AS Cod_cand ,
		'Visual' AS TipoDeficiencia
FROM	[hrh-data].[dbo].[Cand-NecEsp] AS A
WHERE	A.Visual_necEsp > -1
		AND EXISTS (SELECT *
					FROM	[VAGAS_DW].[CANDIDATOS] AS CandDW
					WHERE	A.CodCand_NecEsp = CandDW.COD_CAND
							AND CandDW.POSSUI_DEFIC = 'SIM')
		AND NOT EXISTS (SELECT *
						FROM	[VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] AS CandDef
						WHERE	A.CodCand_NecEsp = CandDef.COD_CAND
								AND CandDef.TipoDeficiencia = 'Visual') ;




-- Remove candidatos da tabela CANDIDATOS_DEFICIENCIAS que deixaram de existir na tabela dom?nio:
DELETE FROM [VAGAS_DW].[CANDIDATOS_DEFICIENCIAS]
FROM	[VAGAS_DW].[CANDIDATOS_DEFICIENCIAS] AS CandDefDW
WHERE	NOT EXISTS (SELECT *
					FROM	[hrh-data].[dbo].[Cand-NecEsp] AS CandNecEsp
					WHERE	CandDefDW.COD_CAND = CandNecEsp.CodCand_NecEsp) ;


-- Ajusta o campo POSSUI_DEFIC, conforme a tabela dom?nio:
UPDATE	[VAGAS_DW].[CANDIDATOS]
SET		POSSUI_DEFIC = 'N?O'
FROM	[VAGAS_DW].[CANDIDATOS] AS CandDW
WHERE	NOT EXISTS (SELECT *
					FROM	[hrh-data].[dbo].[Cand-NecEsp] AS CandNecEsp
					WHERE	CandDW.COD_CAND = CandNecEsp.CodCand_NecEsp)
		AND CandDW.POSSUI_DEFIC = 'SIM' ;