-- =============================================
-- Author: Fiama Cristi
-- Create date: 03/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Extracoes_Relatorios' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Extracoes_Relatorios]
GO


CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Extracoes_Relatorios]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_EXTRACOES_RELATORIOS_VEP] ;

INSERT INTO [VAGAS_DW].[TMP_EXTRACOES_RELATORIOS_VEP](DATA_EXTRACAO,COD_CLI,CONTEXTO_EXTRACAO,TIPO_RELATORIO,FONTE_EXTRACAO,COD_FUNC,QTD_EXTRACOES_RELATORIOS,RELATORIO_PADRAO)
SELECT	CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.Dt_email, 112)) AS DATA_EXTRACAO ,
		B.CodCli_func AS COD_CLI ,
		IIF(A.CodVaga_email > 0, 'VAGA', 'OUTRO') AS CONTEXTO_EXTRACAO ,
		CASE
			WHEN C.GeralVagas_rel = 1
				THEN 'GERAL'
			WHEN C.GeralVaga_rel = 1
				THEN 'VAGA'
			WHEN C.Marcados_rel = 1
				THEN 'SERVIÇOS SOBRE MARCADOS'
			ELSE NULL
		END AS TIPO_RELATORIO ,
		'E-MAIL' AS FONTE_EXTRACAO ,
		B.Cod_func AS COD_FUNC ,
		COUNT(*) AS QTD_EXTRACOES_RELATORIOS ,
		IIF(C.IdFmt_rel IN ('Padrão', 'Padrão-confidencial', 'Padrão-programável'), 'SIM', 'NÃO') AS RELATORIO_PADRAO
FROM	[hrh-data].[dbo].[Email] AS A		INNER JOIN [hrh-data].[dbo].[Funcionarios] AS B	ON A.CodFunc_email = B.Cod_func
											INNER JOIN [hrh-data].[dbo].[Clientes-Relatorios] AS C	ON A.AnexoFmt_email = C.CodFmt_rel
																									   AND B.CodCli_func = C.CodCli_rel
GROUP BY
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.Dt_email, 112)) ,
		B.CodCli_func ,
		IIF(A.CodVaga_email > 0, 'VAGA', 'OUTRO') ,
		CASE
			WHEN C.GeralVagas_rel = 1
				THEN 'GERAL'
			WHEN C.GeralVaga_rel = 1
				THEN 'VAGA'
			WHEN C.Marcados_rel = 1
				THEN 'SERVIÇOS SOBRE MARCADOS'
			ELSE NULL
		END ,
		B.Cod_func ,
		IIF(C.IdFmt_rel IN ('Padrão', 'Padrão-confidencial', 'Padrão-programável'), 'SIM', 'NÃO')
UNION ALL
SELECT	CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.Data_pedXls, 112)) AS DATA_EXTRACAO ,
		B.CodCli_func AS COD_CLI ,
		IIF(A.CodVaga_pedXls > 0, 'VAGA', 'OUTRO') AS CONTEXTO_EXTRACAO ,
				CASE
					WHEN C.GeralVagas_rel = 1
						THEN 'GERAL'
					WHEN C.GeralVaga_rel = 1
						THEN 'VAGA'
					WHEN C.Marcados_rel = 1
						THEN 'SERVIÇOS SOBRE MARCADOS'
					ELSE NULL
				END AS TIPO_RELATORIO ,
		'ON-LINE' AS FONTE_EXTRACAO ,
		B.Cod_func AS COD_FUNC ,
		COUNT(*) AS QTD_EXTRACOES_RELATORIOS ,
		IIF(C.IdFmt_rel IN ('Padrão', 'Padrão-confidencial', 'Padrão-programável'), 'SIM', 'NÃO') AS RELATORIO_PADRAO
FROM [hrh-data].[dbo].[Pedidos_Excel] AS A		INNER JOIN [hrh-data].[dbo].[Funcionarios] AS B ON A.CodFunc_pedXls = B.Cod_func
												INNER JOIN [hrh-data].[dbo].[Clientes-Relatorios] AS C ON A.CodFmt_pedXls = C.CodFmt_rel
																											AND B.CodCli_func = C.CodCli_rel
												
GROUP BY
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.Data_pedXls, 112)) ,
		B.CodCli_func ,
		IIF(A.CodVaga_pedXls > 0, 'VAGA', 'OUTRO') ,
				CASE
					WHEN C.GeralVagas_rel = 1
						THEN 'GERAL'
					WHEN C.GeralVaga_rel = 1
						THEN 'VAGA'
					WHEN C.Marcados_rel = 1
						THEN 'SERVIÇOS SOBRE MARCADOS'
					ELSE NULL
				END ,
		B.Cod_func ,
		IIF(C.IdFmt_rel IN ('Padrão', 'Padrão-confidencial', 'Padrão-programável'), 'SIM', 'NÃO') ;