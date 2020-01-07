-- =============================================
-- Author: Fiama
-- Create date: 21/11/2019
-- Description: Script com a rotina OLAP dos cr�ditos lan�amento e consumo.
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLAP_Carga_Creditos')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Creditos]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Creditos]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[VAGAS_DW].[CREDITOS_LANC] ;
TRUNCATE TABLE [VAGAS_DW].[VAGAS_DW].[CREDITOS_CONSUMO] ;

-- Lan�amento do cr�dito no Manut:
INSERT INTO [VAGAS_DW].[VAGAS_DW].[CREDITOS_LANC](DATA_REFERENCIA, COD_CLI, CLIENTE_VAGAS, DATA_COMPRA, CONTAID, CREDITOS_COMPRA, TIPO_LANCAMENTO_COMPRA, TIPO_COMPRA, CODIGO_COMPRA)
SELECT 	DATA_REFERENCIA,
		COD_CLI,
		CLIENTE_VAGAS,
		DATA_COMPRA,
		CONTAID,
		CREDITOS_COMPRA,
		TIPO_LANCAMENTO_COMPRA,
		TIPO_COMPRA,
		CODIGO_COMPRA
FROM [VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_LANC]	;

-- Uso do cr�dito no Manut:
INSERT INTO [VAGAS_DW].[VAGAS_DW].[CREDITOS_CONSUMO](DATA_REFERENCIA,COD_CLI,CLIENTE_VAGAS,DATA_CREDITO_CONSUMO,CONTAID,TIPO_CONSUMO,CREDITOS_CONSUMO)
SELECT	DATA_REFERENCIA,
		COD_CLI,
		CLIENTE_VAGAS,
		DATA_CREDITO_CONSUMO,
		CONTAID,
		TIPO_CONSUMO,
		CREDITOS_CONSUMO
FROM	[VAGAS_DW].[VAGAS_DW].[TMP_CREDITOS_CONSUMO] 