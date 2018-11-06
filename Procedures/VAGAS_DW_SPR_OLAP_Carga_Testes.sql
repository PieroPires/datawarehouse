-- =============================================
-- Author: Fiama
-- Create date: 18/06/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [VAGAS_DW] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Testes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Testes]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Testes]
AS
SET NOCOUNT ON

	-- Limpar tabela FATO:
	TRUNCATE TABLE [VAGAS_DW].[TESTES] ;

	-- Inserindo registros na visão:
	INSERT INTO [VAGAS_DW].[TESTES] (COD_TESTE, NOME_TESTE, COD_CLI_TESTE, GLOBAL_TESTE, IDIOMA_TESTE, TESTE_IDIOMAS, TESTE_CUSTOMIZADO, CLASSIFICACAO_TESTE)
	SELECT	* FROM [STAGE].[VAGAS_DW].[TMP_TESTES] ;
