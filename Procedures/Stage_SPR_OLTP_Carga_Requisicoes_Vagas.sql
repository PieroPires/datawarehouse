-- =============================================
-- Author: Fiama
-- Create date: 12/07/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'Stage_SPR_OLTP_Carga_Requisicoes_Vagas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.Stage_SPR_OLTP_Carga_Requisicoes_Vagas
GO

CREATE PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Requisicoes_Vagas] 
@DATA_PREENCH_FICHA_REQ SMALLDATETIME

AS
SET NOCOUNT ON

-- Limpeza da tabela:
TRUNCATE TABLE [VAGAS_DW].[TMP_REQUISICOES_VAGAS] ;

-----------------------------------------
-- Levantamento das requisições de vagas:
-----------------------------------------
SELECT	A.Cod_rvw AS COD_REQUISICAO ,
		 CASE 
			WHEN (A.Status_rvw = 1000) THEN 'Aprovada'
		    WHEN (A.Status_rvw > 0 and Status_rvw < 1000) then 'Aguardando aprovação'
		    WHEN (A.Status_rvw = 0) THEN 'Aguardando envio para cadeia de aprovação'
		    WHEN (A.Status_rvw > -1000 and Status_rvw < 0) then 'Reprovada'
		    WHEN (A.Status_rvw = -1000) THEN 'Cancelada'
		    WHEN (A.Status_rvw = -1100) THEN 'Aguardando definição de sequência de aprovações pelo CP'
		    WHEN (A.Status_rvw = -1125) THEN 'Reprovada na pré-aprovação'
		    WHEN (A.Status_rvw = -1150) THEN 'Aguardando pré-aprovação'
		    WHEN (A.Status_rvw = -1200) THEN 'Aguardando envio ao RH'
			ELSE NULL 
		 END AS STATUS_REQUISICAO ,
		CONVERT(SMALLDATETIME, CONVERT(VARCHAR, A.Data_rvw, 112)) AS DATA_REQUISICAO ,
		J.Cod_cli AS COD_CLI ,
		J.Ident_cli AS ID_VAGAS ,
		E.Ident_fic AS FICHA_REQUISICAO ,
		CONVERT(SMALLDATETIME, CONVERT(VARCHAR, I.Data_respCab, 112)) AS DATA_PREENCH_FICHA_REQ , 
		H.Nome_func AS RESPONSAVEL ,
		B.Cod_vaga AS COD_VAGA ,
		F.Area_rv AS AREA_REQUISITANTE ,
		A.NomeRef_rvw AS NOME_CARGO_REQUISICAO ,
		CASE 
			WHEN F.CodFuncGestor_rv IS NULL THEN F.NomeGestor_rv 
			ELSE G.Nome_func 
		END AS NOME_REQUISITANTE ,
		DATA_PUBLICACAO --,
		--CASE
		--	WHEN L.CodNavEx_div = 300 THEN 'RI' -- RECRUTAMENTO INTERNO
		--	WHEN ISNULL(B.QtdeRespCand_vaga, 0) = 0 AND ISNULL(B.tipoprocesso_vaga, 0) <> 4 THEN 'GESTÃO' -- VAGAS DE GESTÃO SÃO AQUELAS ONDE NÃO HÁ CANDIDATURAS (20161227 - NÃO CONSIDERAR VAGAS REDES)
		--	WHEN ISNULL(B.tipoprocesso_vaga, 0) = 0 THEN 'RE'
		--	WHEN ISNULL(B.tipoprocesso_vaga, 0) = 1 THEN 'PET'
		--	WHEN ISNULL(B.tipoprocesso_vaga, 0) = 2 THEN 'PRC'
		--	WHEN ISNULL(B.tipoprocesso_vaga, 0) = 4 THEN 'REDES'
		-- ELSE 'NÃO CLASSIFICADO' 
		--END AS TIPO_PROCESSO
INTO	#TMP_REQUISICOES_VAGAS
FROM	[hrh-data].[dbo].[ReqVaga-Workflow] AS A		LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS B ON A.CodVaga_rvw = B.Cod_vaga
														LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Controle] AS D ON D.Cod_rvc = A.CodRVC_rvw
														LEFT OUTER JOIN [hrh-data].[dbo].[Fichas-DescrGeral] AS E ON D.CodFichaReqVaga_rvc = E.Cod_fic
														LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Gestores] AS F ON F.Cod_rv = D.CodRV_rvc 
														LEFT OUTER JOIN [hrh-data].[dbo].[Funcionarios] AS G ON G.Cod_func = F.CodFuncGestor_rv
														LEFT OUTER JOIN [hrh-data].[dbo].[Funcionarios] AS H ON H.Cod_func = A.CodFuncResp_rvw
														LEFT OUTER JOIN [hrh-data].[dbo].[Fichas-RespCab] AS I ON E.Cod_fic = I.CodFicha_respCab 
																												  AND B.Cod_vaga = I.CodVaga_respCab
																												  AND I.CandPreencheu_respCab = 0
														LEFT OUTER JOIN [hrh-data].[dbo].[Clientes] AS J ON F.CodCli_rv = J.Cod_cli
														LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[VAGAS] AS K ON A.CodVaga_rvw = K.VAGAS_Cod_vaga
														--LEFT JOIN [hrh-data].dbo.Divisoes L ON L.Cod_div = B.CodDivVeic_vaga 
WHERE	E.ReqVaga_fic = 1 -- Ficha do tipo requisição
		AND I.Data_respCab >= @DATA_PREENCH_FICHA_REQ ;


INSERT INTO [VAGAS_DW].[TMP_REQUISICOES_VAGAS] (COD_REQUISICAO, STATUS_REQUISICAO, DATA_REQUISICAO, COD_CLI, ID_VAGAS, FICHA_REQUISICAO, DATA_PREENCH_FICHA_REQ, RESPONSAVEL, COD_VAGA, AREA_REQUISITANTE, NOME_CARGO_REQUISICAO, NOME_REQUISITANTE, DATA_PUBLICACAO)
SELECT	*
FROM	#TMP_REQUISICOES_VAGAS ;