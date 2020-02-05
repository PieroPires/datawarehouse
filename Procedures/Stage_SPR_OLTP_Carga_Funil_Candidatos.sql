USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Funil_Candidatos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Funil_Candidatos]
GO

-- =============================================
-- Author: Fiama Cristi
-- Create date: 06/02/2017
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

-- =============================================
-- Alterações
-- 05/02/2020 - Diego Gatto - Ajustado para utilizar as tabelas TMP na base de dados stage e não vagas_dw
-- =============================================


CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Funil_Candidatos] 

AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_FUNIL_CANDIDATOS]


-- AREA E NÍVEL:
-- DROP TABLE #Area_Nivel ;
SELECT	A.CodCand_cargo ,
		B.Descr_setor AS AREA ,
		C.Descr_hierarquia AS NIVEL ,
		ROW_NUMBER() OVER(PARTITION BY A.CodCand_cargo ORDER BY A.Cod_cargo ASC) AS CONTROLE_AREA_NIVEL
INTO	#Area_Nivel
FROM	[hrh-data].[dbo].[CandidatoxCargos] AS A	LEFT OUTER JOIN [hrh-data].[dbo].[Cad_setores] AS B ON A.CodSetor_cargo = B.Cod_setor
													LEFT OUTER JOIN [hrh-data].[dbo].[Cad_hierarquias] AS C ON A.CodHierarquia_cargo = C.Cod_hierarquia ;


-- Performance:
CREATE NONCLUSTERED INDEX IDX_#Area_Nivel ON #Area_Nivel (CodCand_cargo) ;


-- IDIOMA:
-- DROP TABLE #Idioma ;
SELECT	DISTINCT A.CodCand_idiomaCand
INTO	#Idioma
FROM	[hrh-data].[dbo].[Cand-Idiomas] AS A


-- Performance:
CREATE NONCLUSTERED INDEX IDX_#Idioma_CodCand_idiomaCand ON #Idioma (CodCand_idiomaCand) ;



-- EXPERIÊNCIA PROFISSIONAL:
-- DROP TABLE #Experiencia_profissional ;
SELECT	DISTINCT A.CodCand_exp
INTO	#Experiencia_profissional
FROM	[hrh-data].[dbo].[Cand-Experiencia] AS A


-- Performance:
CREATE NONCLUSTERED INDEX IDX_#Experiencia_profissional_Cod_cand_exp ON #Experiencia_profissional (CodCand_exp) ;


-- Base candidatos DW:
-- DROP TABLE #Base_candidatos_DW ;
SELECT	A.COD_CAND ,
		A.TIPO_CADASTRO ,
		A.LIBERACAO_CV_NOVO
INTO	#Base_candidatos_DW
FROM	[VAGAS_DW].[VAGAS_DW].[CANDIDATOS] AS A		LEFT OUTER JOIN [hrh-data].[dbo].[Candidatos] AS B ON A.COD_CAND = B.Cod_cand
WHERE	A.REMOVIDO_CAND = 0 -- Currículo não removido
		AND A.TIPO_CADASTRO IN ('Curriculo - BCC', 'Cadastro - BCC ') ;

-- Performance:
CREATE NONCLUSTERED INDEX IDX_#Base_candidatos_DW_Cod_cand ON #Base_candidatos_DW (Cod_cand) ;

-- Funil_candidatos :
-- DROP TABLE #Dados_Funil_candidatos ;
SELECT	A.COD_CAND ,
		A.LIBERACAO_CV_NOVO ,
		A1.DtCriacao_cand AS DATA_CADASTRO ,
		CASE WHEN (A1.Nome_cand IS NULL) THEN 0 ELSE 1 END AS NOME ,
		CASE WHEN (A1.Imagem_cand IS NULL) THEN 0 ELSE 1 END AS FOTO ,
		CASE WHEN (A1.DtNasc_cand IS NULL OR A1.CodEstadoCivil_cand IS NULL OR A1.CodNacion_cand IS NULL OR B.CodCand_candDoc IS NULL) THEN 0 ELSE 1 END AS DADOS_PESSOAIS ,
		CASE WHEN (A1.CodPais_cand IS NULL OR (A1.Cep_cand IS NULL AND A1.CodigoPostal_cand IS NULL) OR A1.CodUF_cand IS NULL OR A1.CodCidade_cand IS NULL OR A1.Endereco_cand IS NULL) THEN 0 ELSE 1 END AS ENDERECO ,
		CASE WHEN (A1.Email_cand IS NULL OR A1.Tel_cand IS NULL OR A1.Celular_cand IS NULL) THEN 0 ELSE 1 END AS CONTATO ,
		CASE WHEN (C.CodCand_candRedeSoc IS NULL) THEN 0 ELSE 1 END AS LINKS_REDES_SOCIAIS ,
		CASE WHEN ISNULL(A1.Objetivo_cand, '') = '' THEN 0 ELSE 1 END AS OBJETIVO ,
		CASE WHEN (D1.CodCand_cargo IS NULL AND D2.CodCand_cargo IS NULL AND D3.CodCand_cargo IS NULL AND D4.CodCand_cargo IS NULL AND D5.CodCand_cargo IS NULL) THEN 0 ELSE 1 END AS AREA_NIVEL_OBJETIVO ,
		CASE WHEN ISNULL(A1.ValSalPret_cand, 0) = 0 THEN 0 ELSE 1 END AS PRETENSAL_SALARIAL ,
		CASE WHEN E.CodCand_regCand IS NULL THEN 0 ELSE 1 END AS REGIAO_INTERESSE ,
		CASE WHEN A1.Perfil_cand IS NULL THEN 0 ELSE 1 END AS RESUMO_QUALIFIC ,
		CASE WHEN ISNULL(A1.CodFormMax_cand, -1) = -1 THEN 0 ELSE 1 END AS NIVEL_ESCOLARIDADE ,
		CASE WHEN H.CodCand_exp IS NULL THEN 0 ELSE 1 END AS EXPERIENCIA_PROFISSIONAL ,
		CASE WHEN G.CodCand_idiomaCand IS NULL THEN 0 ELSE 1 END AS IDIOMA ,
		CASE WHEN (A1.UltSal_cand IS NULL OR A1.UltBeneficios_cand IS NULL) THEN 0 ELSE 1 END AS ULTIMO_SALARIO ,
		CASE WHEN (A1.InfoCompl_cand IS NULL) THEN 0 ELSE 1 END AS INF_COMPLEMENTARES ,
		A.TIPO_CADASTRO
INTO	#Dados_Funil_candidatos
FROM	#Base_candidatos_DW AS A	LEFT OUTER JOIN [hrh-data].[dbo].[Candidatos] AS A1 ON A.COD_CAND = A1.Cod_cand
									LEFT OUTER JOIN [hrh-data].[dbo].[Cand-Doc] AS B ON A.Cod_cand = B.CodCand_candDoc
									LEFT OUTER JOIN [hrh-data].[dbo].[Cand-RedesSociais] AS C ON A.Cod_cand = C.CodCand_candRedeSoc
									LEFT OUTER JOIN #Area_Nivel AS D1 ON A.Cod_cand = D1.CodCand_cargo AND D1.CONTROLE_AREA_NIVEL = 1
									LEFT OUTER JOIN #Area_Nivel AS D2 ON A.Cod_cand = D2.CodCand_cargo AND D2.CONTROLE_AREA_NIVEL = 2
									LEFT OUTER JOIN #Area_Nivel AS D3 ON A.Cod_cand = D3.CodCand_cargo AND D3.CONTROLE_AREA_NIVEL = 3
									LEFT OUTER JOIN #Area_Nivel AS D4 ON A.Cod_cand = D4.CodCand_cargo AND D4.CONTROLE_AREA_NIVEL = 4
									LEFT OUTER JOIN #Area_Nivel AS D5 ON A.Cod_cand = D5.CodCand_cargo AND D5.CONTROLE_AREA_NIVEL = 5
									LEFT OUTER JOIN [hrh-data].[dbo].[Cand-Regioes] AS E ON A.Cod_cand = E.CodCand_regCand
									LEFT OUTER JOIN [hrh-data].[dbo].[Cad_formacaoMax] AS F ON A1.CodFormMax_cand = F.Cod_formMax
									LEFT OUTER JOIN #Idioma AS G ON A.Cod_cand = G.CodCand_idiomaCand
									LEFT OUTER JOIN #Experiencia_profissional AS H ON A.Cod_Cand = H.CodCand_exp


-- Base CVs únicos:
-- DROP TABLE #Base_CVs_unicos ;
SELECT	DISTINCT COD_CAND ,
		DATA_CADASTRO ,
		LIBERACAO_CV_NOVO AS CURRICULO_NOVO ,
		NOME ,
		FOTO ,
		DADOS_PESSOAIS ,
		ENDERECO ,
		CONTATO ,
		LINKS_REDES_SOCIAIS ,
		OBJETIVO ,
		AREA_NIVEL_OBJETIVO ,
		PRETENSAL_SALARIAL AS PRETENSAO_SALARIAL ,
		REGIAO_INTERESSE ,
		RESUMO_QUALIFIC ,
		NIVEL_ESCOLARIDADE ,
		EXPERIENCIA_PROFISSIONAL ,
		IDIOMA ,
		ULTIMO_SALARIO ,
		INF_COMPLEMENTARES ,
		TIPO_CADASTRO
INTO	#Base_CVs_unicos
FROM	#Dados_Funil_candidatos ;


-- Currículo completo:
-- DROP TABLE #Curriculo_completo ;
SELECT	A.COD_CAND ,
		A.DATA_CADASTRO ,
		'Currículo - completo' AS TIPO_CADASTRO ,
		CURRICULO_NOVO ,
		NOME ,
		FOTO ,
		DADOS_PESSOAIS ,
		ENDERECO ,
		CONTATO ,
		LINKS_REDES_SOCIAIS ,
		OBJETIVO ,
		AREA_NIVEL_OBJETIVO ,
		PRETENSAO_SALARIAL ,
		REGIAO_INTERESSE ,
		RESUMO_QUALIFIC ,
		NIVEL_ESCOLARIDADE ,
		EXPERIENCIA_PROFISSIONAL ,
		IDIOMA ,
		ULTIMO_SALARIO ,
		INF_COMPLEMENTARES
INTO	#Curriculo_completo
FROM	#Base_CVs_unicos AS A
WHERE	NOME = 1
		AND DADOS_PESSOAIS = 1
		AND ENDERECO = 1
		AND CONTATO = 1
		AND OBJETIVO = 1
		AND AREA_NIVEL_OBJETIVO = 1
		AND PRETENSAO_SALARIAL = 1
		AND REGIAO_INTERESSE = 1
		AND RESUMO_QUALIFIC = 1
		AND NIVEL_ESCOLARIDADE = 1
		AND EXPERIENCIA_PROFISSIONAL = 1
		AND IDIOMA = 1
		AND ULTIMO_SALARIO = 1
		AND INF_COMPLEMENTARES = 1


-- PRÉ-CADASTRO e Currículo Apto:
-- DROP TABLE #Pre_Cadastro_CV_Apto ;
SELECT	COD_CAND ,
		DATA_CADASTRO ,
		CASE WHEN TIPO_CADASTRO = 'Cadastro - BCC ' THEN 'PRÉ - CADASTRO'
			 WHEN TIPO_CADASTRO = 'Curriculo - BCC' THEN 'Currículo Apto' END AS TIPO_CADASTRO ,
		CURRICULO_NOVO ,
		NOME ,
		FOTO ,
		DADOS_PESSOAIS ,
		ENDERECO ,
		CONTATO ,
		LINKS_REDES_SOCIAIS ,
		OBJETIVO ,
		AREA_NIVEL_OBJETIVO ,
		PRETENSAO_SALARIAL ,
		REGIAO_INTERESSE ,
		RESUMO_QUALIFIC ,
		NIVEL_ESCOLARIDADE ,
		EXPERIENCIA_PROFISSIONAL ,
		IDIOMA ,
		ULTIMO_SALARIO ,
		INF_COMPLEMENTARES
INTO	#Pre_Cadastro_CV_Apto
FROM	#Base_CVs_unicos AS A
WHERE	NOT EXISTS (SELECT	1
					FROM	#Curriculo_completo AS A1
					WHERE	A.COD_CAND = A1.COD_CAND)


INSERT INTO [VAGAS_DW].[TMP_FUNIL_CANDIDATOS] (COD_CAND, DATA_CADASTRO, TIPO_CADASTRO, CURRICULO_NOVO, NOME, FOTO, DADOS_PESSOAIS, ENDERECO, CONTATO, LINKS_REDES_SOCIAIS, OBJETIVO, AREA_NIVEL_OBJETIVO, PRETENSAO_SALARIAL, REGIAO_INTERESSE, RESUMO_QUALIFIC, NIVEL_ESCOLARIDADE, EXPERIENCIA_PROFISSIONAL, IDIOMA, ULTIMO_SALARIO, INF_COMPLEMENTARES)
SELECT	A.COD_CAND ,
		A.DATA_CADASTRO ,
		A.TIPO_CADASTRO COLLATE SQL_Latin1_General_CP1_CI_AI AS TIPO_CADASTRO ,
		A.CURRICULO_NOVO ,
		NOME ,
		FOTO ,
		DADOS_PESSOAIS ,
		ENDERECO ,
		CONTATO ,
		LINKS_REDES_SOCIAIS ,
		OBJETIVO ,
		AREA_NIVEL_OBJETIVO ,
		PRETENSAO_SALARIAL ,
		REGIAO_INTERESSE ,
		RESUMO_QUALIFIC ,
		NIVEL_ESCOLARIDADE ,
		EXPERIENCIA_PROFISSIONAL ,
		IDIOMA ,
		ULTIMO_SALARIO ,
		INF_COMPLEMENTARES
FROM	#Curriculo_completo AS A
UNION ALL
SELECT	A.COD_CAND ,
		A.DATA_CADASTRO ,
		A.TIPO_CADASTRO COLLATE SQL_Latin1_General_CP1_CI_AI ,
		A.CURRICULO_NOVO ,
		NOME ,
		FOTO ,
		DADOS_PESSOAIS ,
		ENDERECO ,
		CONTATO ,
		LINKS_REDES_SOCIAIS ,
		OBJETIVO ,
		AREA_NIVEL_OBJETIVO ,
		PRETENSAO_SALARIAL ,
		REGIAO_INTERESSE ,
		RESUMO_QUALIFIC ,
		NIVEL_ESCOLARIDADE ,
		EXPERIENCIA_PROFISSIONAL ,
		IDIOMA ,
		ULTIMO_SALARIO ,
		INF_COMPLEMENTARES
FROM	#Pre_Cadastro_CV_Apto AS A;