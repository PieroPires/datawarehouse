-- =============================================
-- Author: Fiama
-- Create date: 23/10/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;


IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Envio_CV_Email' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' )
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Envio_CV_Email] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Envio_CV_Email] 
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_ENVIO_CV_EMAIL] ;

INSERT INTO [VAGAS_DW].[TMP_ENVIO_CV_EMAIL](COD_CLI,FORMATO_ENVIO_CV,COD_VAGA,DATA_ENVIO,QTD_ENVIOS_CVs,QTD_CVS_ENVIADO)
SELECT	B.CodCli_func AS COD_CLI ,
		CASE
			WHEN A.AnexoFmt_email = 0
				THEN 'Padrão'
			WHEN A.AnexoFmt_email = 1
				THEN 'Padrão-confidencial'
			WHEN A.AnexoFmt_email = 999
				THEN 'Padrão-programável'
		END AS FORMATO_ENVIO_CV ,
		A.CodVaga_email AS COD_VAGA ,
		CONVERT(DATE, A.Dt_email) AS DATA_ENVIO ,
		COUNT(*) AS QTD_ENVIOS_CVs ,
		SUM(CONVERT(INT, SUBSTRING(LTRIM(RTRIM(AnexoLista_email)), 1, CHARINDEX(' ', LTRIM(RTRIM(AnexoLista_email))) -1))) AS QTD_CVS_ENVIADO
FROM	[hrh-data].[dbo].[Email] AS A		LEFT OUTER JOIN [hrh-data].[dbo].[Funcionarios] AS B ON A.CodFunc_email = B.Cod_func
											LEFT OUTER JOIN	[hrh-data].[dbo].[Clientes-Relatorios] AS C ON A.AnexoFmt_email = C.CodFmt_rel 
																										   AND B.CodCli_func = C.CodCli_rel
WHERE	A.EnvioOK_email = 1 -- E-mail enviado
		AND A.AnexoFmt_email IN (0, 1, 999) -- 0 = Padrão, 1 = Padrão-confidencial, 999 = Padrão-programável.
GROUP BY
		B.CodCli_func ,
		CASE
			WHEN A.AnexoFmt_email = 0
				THEN 'Padrão'
			WHEN A.AnexoFmt_email = 1
				THEN 'Padrão-confidencial'
			WHEN A.AnexoFmt_email = 999
				THEN 'Padrão-programável'
		END ,
		A.CodVaga_email ,
		CONVERT(DATE, A.Dt_email) ;