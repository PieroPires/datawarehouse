-- =============================================
-- Author: Fiama
-- Create date: 27/05/2018
-- Description: Procedure para carga do código FATURAMENTO ERP.
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Clientes_Codigo_Faturamento_ERP' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Clientes_Codigo_Faturamento_ERP
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Clientes_Codigo_Faturamento_ERP]
AS

SET NOCOUNT ON

-- Limpeza da tabela:
TRUNCATE TABLE [VAGAS_DW].[TMP_NUM_PED_FAT] ;

INSERT INTO [VAGAS_DW].[TMP_NUM_PED_FAT]
SELECT	SA1.A1_X_CCRMF	AS CONTA_ID ,
		CASE SA1.A1_XPCNF 
			WHEN 1 THEN 'SIM' 
			ELSE 			'NAO' 
		END 				AS NUM_PD_NA_NF --Número de Pedido na Nota	
FROM	[ERP].[DB_TOTVS_P12_PROD].[dbo].[SA1010] AS SA1	WITH(NOLOCK)
WHERE	SA1.D_E_L_E_T_ = ' ' 
		AND SA1.A1_X_CCRMF IN (SELECT	A1.CONTA_ID COLLATE SQL_Latin1_General_CP1_CI_AI
							   FROM		[VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1
							   WHERE	A1.EX_CLIENTE = 0
										AND A1.CARTEIRA = 'RELACIONAMENTO') ;