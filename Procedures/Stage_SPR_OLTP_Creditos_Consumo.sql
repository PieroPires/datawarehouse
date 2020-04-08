USE STAGE
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Creditos_Consumo' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Creditos_Consumo]
GO

-- =============================================
-- Author:      Fiama dos Santos Cristi
-- Create date: 17/08/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Creditos_Consumo]			

AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_CREDITOS_CONSUMO]								  


SELECT Cod_cli AS COD_CLI ,	
	Ident_cli AS CLIENTE_VAGAS ,
	Data_CredVlanc AS DATA_CREDITO_CONSUMO ,
	IdContaCRM_cli AS CONTAID ,
	Descr_CredVtipoLanc	AS TIPO_CONSUMO ,
	SUM(Creditos_CredVlanc) *-1 AS CREDITOS_CONSUMO
INTO #TMP_CREDITOS_CONSUMO
FROM [hrh-data].[dbo].[Creditos_VAGAS_lancamentos] INNER JOIN [hrh-data].[dbo].[Creditos_VAGAS_tipoLanc] ON Cod_CredVtipoLanc = Tipo_CredVlanc 
												   INNER JOIN [hrh-data].[dbo].[Clientes] ON CodCli_CredVlanc = Cod_cli
WHERE Creditos_CredVlanc < 0 
	AND Cod_CredVtipoLanc IN (100, 110, 120)
	AND Ident_cli NOT IN ('teste 01', 'teste01')
GROUP BY Cod_cli ,
	Ident_cli ,
	Data_CredVlanc ,
	IdContaCRM_cli ,
	Descr_CredVtipoLanc ;


INSERT INTO [VAGAS_DW].[TMP_CREDITOS_CONSUMO](DATA_REFERENCIA, COD_CLI, CLIENTE_VAGAS, DATA_CREDITO_CONSUMO, CONTAID, TIPO_CONSUMO, CREDITOS_CONSUMO)
SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)) AS DATA_REFERENCIA ,
	COD_CLI ,
	CLIENTE_VAGAS ,
	DATA_CREDITO_CONSUMO ,
	CONTAID ,
	TIPO_CONSUMO ,
	CREDITOS_CONSUMO 
FROM #TMP_CREDITOS_CONSUMO ;


DROP TABLE #TMP_CREDITOS_CONSUMO 
GO