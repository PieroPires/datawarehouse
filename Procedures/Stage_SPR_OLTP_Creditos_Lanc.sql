USE STAGE
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Creditos_Lanc' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Creditos_Lanc]
GO

-- =============================================
-- Author:      Fiama dos Santos Cristi
-- Create date: 16/08/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Creditos_Lanc]

AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_CREDITOS_LANC] 


SELECT A.Cod_cli AS COD_CLI ,
	A.Ident_cli AS CLIENTE_VAGAS ,
	A1.Data_CredV AS DATA_COMPRA ,
	A.IDContaCRM_cli AS CONTAID ,
	A1.Credito_CredV AS CREDITOS_COMPRA ,
	A4.Descr_CredVtipoLanc AS TIPO_LANCAMENTO_COMPRA ,
	CASE WHEN A3.CodFunc_CredVlanc IS NULL THEN 'OFFLINE/MANUT' ELSE 'ONLINE/EMPRESA' END AS TIPO_COMPRA ,
	A1.CompraID_CredV AS CODIGO_COMPRA
INTO #TMP_CREDITOS_LANC
FROM [hrh-data].[dbo].[Clientes] AS A INNER JOIN [hrh-data].[dbo].[Creditos_VAGAS] AS A1 ON A.Cod_cli = A1.CodCli_CredV	
									  INNER JOIN [hrh-data].[dbo].[Creditos_VAGAS_escopo] AS A2 ON A1.Cod_CredV = A2.CodCredVAGAS_CredVesc
									  LEFT OUTER JOIN [hrh-data].[dbo].[Creditos_VAGAS_lancamentos] AS A3 ON A2.CodLanc_CredVesc = A3.Cod_CredVlanc
									  LEFT OUTER JOIN [hrh-data].[dbo].[Creditos_VAGAS_tipoLanc] AS A4 ON A3.Tipo_CredVlanc = A4.Cod_CredVtipoLanc 
WHERE A3.Creditos_CredVlanc > 0
	AND A1.TipoCredito_CredV IN (10, 20, 50) 
	AND A.Ident_cli NOT IN ('teste01', 'teste 01') 



INSERT INTO [VAGAS_DW].[TMP_CREDITOS_LANC](DATA_REFERENCIA, COD_CLI, CLIENTE_VAGAS, DATA_COMPRA, CONTAID, CREDITOS_COMPRA, TIPO_LANCAMENTO_COMPRA, TIPO_COMPRA, CODIGO_COMPRA)
	SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)) AS DATA_REFERENCIA ,
		COD_CLI ,
		CLIENTE_VAGAS ,
		DATA_COMPRA , 
		CONTAID ,
		CREDITOS_COMPRA ,
		TIPO_LANCAMENTO_COMPRA ,
		TIPO_COMPRA ,
		CODIGO_COMPRA
	FROM #TMP_CREDITOS_LANC ;

DROP TABLE #TMP_CREDITOS_LANC ;
GO