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
	INSERT INTO [VAGAS_DW].[TESTES] (COD_TESTE, NOME_TESTE, COD_CLI_TESTE, GLOBAL_TESTE, IDIOMA_TESTE, TESTE_IDIOMAS, TESTE_CUSTOMIZADO, CLASSIFICACAO_TESTE, COD_FUNC, FLAG_CONSTRUTOR_TESTES, DATA_CRIACAO, DATA_ALTERACAO, DATA_RASCUNHO, FLAG_RASCUNHO,RASCUNHO_CONV_TESTE)
	SELECT	* FROM [STAGE].[VAGAS_DW].[TMP_TESTES] ;


	-- Teste enviado:
	UPDATE	[VAGAS_DW].[TESTES]
	SET		TESTE_ENVIADO = 'Sim'
	FROM	[VAGAS_DW].[TESTES] AS Testes
	WHERE	EXISTS (SELECT	*
					 FROM	[hrh-data].[dbo].[Cand-FichasPend] AS Teste_enviado_A1
					 WHERE	Testes.COD_TESTE = Teste_enviado_A1.CodFicha_ficPend)
			AND ISNULL(Testes.TESTE_ENVIADO, '') <> 'Sim' ;

	UPDATE	[VAGAS_DW].[TESTES]
	SET		TESTE_ENVIADO = 'Sim'
	FROM	[VAGAS_DW].[TESTES] AS Testes
	WHERE	EXISTS (SELECT * FROM VAGAS_DW.VAGAS_TESTES AS Testes_vaga
					WHERE	Testes.COD_TESTE = Testes_vaga.COD_TESTE)
			AND ISNULL(Testes.TESTE_ENVIADO, '') <> 'Sim' ;

	UPDATE	[VAGAS_DW].[TESTES]
	SET		TESTE_ENVIADO = 'Não'
	FROM	[VAGAS_DW].[TESTES] AS Testes
	WHERE	Testes.TESTE_ENVIADO IS NULL



	-- Teste respondido:
	UPDATE	[VAGAS_DW].[TESTES]
	SET		TESTE_RESPONDIDO = 'Sim'
	FROM	[VAGAS_DW].[TESTES] AS Testes
	WHERE	EXISTS (SELECT	*
					FROM	[hrh-data].[dbo].[Fichas-RespCab] AS Teste_respondido_A1
					WHERE	Testes.COD_TESTE = Teste_respondido_A1.CodFicha_respCab)
			AND ISNULL(Testes.TESTE_RESPONDIDO, '') <> 'Sim' ;
	
	UPDATE	[VAGAS_DW].[TESTES]
	SET		TESTE_RESPONDIDO = 'Não'
	FROM	[VAGAS_DW].[TESTES] AS Testes
	WHERE	Testes.TESTE_RESPONDIDO IS NULL ;

	-- ver uma solução:
	-- Ajuste a flag construtor testes quando o valor não corresponde a um registro válido na tabela de rascunho do postgres:
	--UPDATE	[VAGAS_DW].[TESTES]
	--SET		FLAG_CONSTRUTOR_TESTES = 0
	--FROM	[VAGAS_DW].[TESTES] AS Testes
	--WHERE	Testes.RASCUNHO_CONV_TESTE IS NULL ;


	-- Remoção de registros inválidos:
	DELETE FROM VAGAS_DW.TESTES
	WHERE	FLAG_CONSTRUTOR_TESTES = 1
			AND COD_CLI_TESTE IN (12702, 47635, 58459, 66969, 69246) ;


	-- Correção de inconsistência no banco (teste respondido que não foi enviado):
	UPDATE	[VAGAS_DW].[VAGAS_DW].[TESTES]
	SET		TESTE_RESPONDIDO = 'Não'
	WHERE	TESTE_RESPONDIDO = 'Sim'
			AND TESTE_ENVIADO = 'Não' ;