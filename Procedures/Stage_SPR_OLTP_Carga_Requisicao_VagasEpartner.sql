-- =============================================
-- Author: Fiama
-- Create date: 12/08/2019
-- Description: Script com a rotina de carga OLAP do Cubo de Requisicao_VagasEpartner.
-- =============================================

USE [STAGE] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLTP_Carga_Requisicao_VagasEpartner')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Requisicao_VagasEpartner]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Requisicao_VagasEpartner]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_Requisicao_VagasEpartner] ;

INSERT INTO [VAGAS_DW].[TMP_Requisicao_VagasEpartner] (Cod_requisicao,Status_requisicao,Data_requisicao,Cod_cli,Cod_func,Cod_vaga,IdConta_CRM)
SELECT	A.Cod_rvw AS Cod_requisicao ,
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
		END AS Status_requisicao ,
		CONVERT(DATE, A.Data_rvw) AS Data_requisicao ,
		G.Cod_cli ,
		A.CodFuncResp_rvw AS Cod_func ,
		A.CodVaga_rvw AS Cod_vaga ,
		G.IdContaCRM_cli AS IdConta_CRM
FROM	[hrh-data].[dbo].[ReqVaga-Workflow] AS A		LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS B ON A.CodVaga_rvw = B.Cod_vaga
														LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Controle] AS D ON D.Cod_rvc = A.CodRVC_rvw
														LEFT OUTER JOIN [hrh-data].[dbo].[Fichas-DescrGeral] AS E ON D.CodFichaReqVaga_rvc = E.Cod_fic
														LEFT OUTER JOIN [hrh-data].[dbo].[ReqVaga-Gestores] AS F ON F.Cod_rv = D.CodRV_rvc
														LEFT OUTER JOIN [hrh-data].[dbo].[Clientes] AS G ON F.CodCli_rv = G.Cod_cli
WHERE	E.ReqVaga_fic = 1 -- Ficha do tipo requisição