-- =============================================
-- Author: Fiama
-- Create date: 18/06/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'Stage_SPR_OLTP_Carga_Testes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Testes] ;
GO

CREATE PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Testes]
AS
SET NOCOUNT ON

	-- Limpeza da tabela:
	TRUNCATE TABLE [VAGAS_DW].[TMP_TESTES] ;

	-- Extraindo os testes para carga na visão domínio:
	SELECT	A.Cod_fic AS COD_TESTE ,
			A.Ident_fic AS NOME_TESTE ,
			A.CodCli_fic AS COD_CLI_TESTE ,
			IIF(A.TesteGlobal_fic = 1, 'SIM', 'NÃO') AS GLOBAL_TESTE ,
			CHOOSE(A.CodIdioma_fic, 'PORTUGUÊS', 'ESPANHOL', 'INGLÊS') AS IDIOMA_TESTE
	INTO	#TMP_TESTES
	FROM	[hrh-data].[dbo].[Fichas-DescrGeral] AS A
	WHERE	A.Teste_fic = 4 ;

	
	-- Inserindo os registros na visão domínio:
	INSERT INTO [VAGAS_DW].[TMP_TESTES] (COD_TESTE, NOME_TESTE, COD_CLI_TESTE, GLOBAL_TESTE, IDIOMA_TESTE)
	SELECT	A.COD_TESTE ,
			A.NOME_TESTE ,
			A.COD_CLI_TESTE ,
			A.GLOBAL_TESTE ,
			A.IDIOMA_TESTE
	FROM	#TMP_TESTES AS A ;