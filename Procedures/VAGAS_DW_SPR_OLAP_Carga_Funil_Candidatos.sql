-- EXEC VAGAS_DW.SPR_OLAP_Carga_Funil_Candidatos
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Funil_Candidatos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Funil_Candidatos
GO

-- =============================================
-- Author: Fiama
-- Create date: 31/01/2017
-- Description: Procedure para alimenta��o do DW
-- =============================================


CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Funil_Candidatos

AS
SET NOCOUNT ON

DECLARE @DATA_REFERENCIA SMALLDATETIME
SET @DATA_REFERENCIA = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112))

-- LIMPAR DADOS DA DATA REFERENCIA QUE SER� ATUALIZADA
DELETE [VAGAS_DW].[FUNIL_CANDIDATOS]
FROM [VAGAS_DW].[FUNIL_CANDIDATOS] A
WHERE DATA_REFERENCIA = @DATA_REFERENCIA

SELECT	@DATA_REFERENCIA AS DATA_REFERENCIA , 
		A.TIPO_CADASTRO,
		A.DATA_CADASTRO ,
		COUNT(*) AS QTD_CANDIDATOS ,
		CASE WHEN A.CURRICULO_NOVO = 1 THEN 'SIM' ELSE 'N�O' END AS CURRICULO_NOVO
INTO	#FUNIL_CANDIDATOS
FROM	[VAGAS_DW].[VAGAS_DW].[TMP_FUNIL_CANDIDATOS] AS A
GROUP BY A.TIPO_CADASTRO ,
		A.DATA_CADASTRO ,
		CASE WHEN A.CURRICULO_NOVO = 1 THEN 'SIM' ELSE 'N�O' END


-- CONGELAMENTO DO FUNIL DE CANDIDATOS NA DATA REFERENCIA
INSERT INTO [VAGAS_DW].[FUNIL_CANDIDATOS] (DATA_REFERENCIA, TIPO_CADASTRO, DATA_CADASTRO, QTD_CANDIDATOS, CURRICULO_NOVO)
SELECT	DATA_REFERENCIA ,
		TIPO_CADASTRO ,
		DATA_CADASTRO ,
		QTD_CANDIDATOS ,
		CURRICULO_NOVO
FROM	#FUNIL_CANDIDATOS ;





























