-- =============================================
-- Author: Fiama
-- Create date: 08/01/2020
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
USE [vagas_dw] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Despesas_Marketing' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Despesas_Marketing] ;
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Despesas_Marketing]
AS
SET NOCOUNT ON

-- Limpa a tabela OLAP:
TRUNCATE TABLE [vagas_dw].[VAGAS_DW].[Despesas_Marketing] ;

-- Atualiza a tabela OLAP:
INSERT INTO [vagas_dw].[VAGAS_DW].[Despesas_Marketing]
SELECT	* FROM [stage].[VAGAS_DW].[Tmp_Despesas_Marketing] ;