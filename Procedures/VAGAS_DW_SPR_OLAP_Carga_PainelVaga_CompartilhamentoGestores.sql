-- =============================================
-- Author: Fiama
-- Create date: 28/08/2020
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_PainelVaga_CompartilhamentoGestores' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_PainelVaga_CompartilhamentoGestores]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_PainelVaga_CompartilhamentoGestores]
AS
SET NOCOUNT ON

	-- Limpar tabela FATO:
	TRUNCATE TABLE [VAGAS_DW].[PainelVaga_CompartilhamentoGestores] ;

	-- Inserindo registros na visão:
	INSERT INTO [VAGAS_DW].[PainelVaga_CompartilhamentoGestores]
	SELECT * FROM [stage].[VAGAS_DW].[Tmp_PainelVaga_CompartilhamentoGestores] ;