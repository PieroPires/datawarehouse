-- =============================================
-- Author: Fiama
-- Create date: 23/10/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;


IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Vagas_Etalent_Lancamentos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' )
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Vagas_Etalent_Lancamentos] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Vagas_Etalent_Lancamentos] 
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_VAGAS_ETALENT_LANCAMENTOS] ;

INSERT INTO [VAGAS_DW].[TMP_VAGAS_ETALENT_LANCAMENTOS] (COD_CLI,COD_VAGA,DATA_LANCAMENTO,TIPO_LANCAMENTO,TIPO_REL_COMP_REL,QTD_LANCAMENTOS)
SELECT	A.CodCli_VeTlanc AS COD_CLI ,
		A.CodVaga_VeTlanc AS COD_VAGA ,
		CONVERT(DATE, A.Data_VeTlanc) AS DATA_LANCAMENTO ,
		CASE
			WHEN A.Tipo_VeTlanc = 2
				THEN 'CORRELAÇÃO'
			WHEN A.Tipo_VeTlanc = 3
				THEN 'COMPRA RELATÓRIO'
		END AS TIPO_LANCAMENTO ,
		IIF(A.Tipo_VeTlanc = 3,
			CASE
				WHEN A.Creditos_vetlanc = -1
					THEN 'RELATÓRIO EXECUTIVO'
				WHEN A.Creditos_vetlanc = -3
					THEN 'RELATÓRIO DE SELEÇÃO'
				WHEN A.Creditos_vetlanc = -7
					THEN 'RELATÓRIO DE GESTÃO'
			END, NULL) AS TIPO_REL_COMP_REL ,
		COUNT(*) AS QTD_LANCAMENTOS
FROM	[hrh-data].[dbo].[Vagas_etalent_lancamentos] AS A
WHERE	A.Tipo_VetLanc IN (2, 3)
GROUP BY
		A.CodCli_VeTlanc ,
		A.CodVaga_VeTlanc ,
		CONVERT(DATE, A.Data_VeTlanc) ,
		CASE
			WHEN A.Tipo_VeTlanc = 2
				THEN 'CORRELAÇÃO'
			WHEN A.Tipo_VeTlanc = 3
				THEN 'COMPRA RELATÓRIO'
		END ,
		IIF(A.Tipo_VeTlanc = 3,
			CASE
				WHEN A.Creditos_vetlanc = -1
					THEN 'RELATÓRIO EXECUTIVO'
				WHEN A.Creditos_vetlanc = -3
					THEN 'RELATÓRIO DE SELEÇÃO'
				WHEN A.Creditos_vetlanc = -7
					THEN 'RELATÓRIO DE GESTÃO'
			END, NULL) ;