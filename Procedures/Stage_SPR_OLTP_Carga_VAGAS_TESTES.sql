-- =============================================
-- Author: Fiama
-- Create date: 18/06/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'Stage_SPR_OLTP_Carga_VAGAS_TESTES' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_VAGAS_TESTES]
GO

CREATE PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_VAGAS_TESTES]
AS
SET NOCOUNT ON
	
	-- Limpeza da tabela:
	TRUNCATE TABLE [VAGAS_DW].[TMP_VAGAS_TESTES] ;

	-- Levantamento dos dados para carga na visão temporária:
	SELECT	A.Cod_vaga AS COD_VAGA ,
			A.CodFicha1_vaga AS COD_TESTE ,
			1 AS NUM_TESTE_VAGA
	INTO	#TMP_VAGAS_TESTES
	FROM	[hrh-data].[dbo].[Vagas] AS A		INNER JOIN [VAGAS_DW].[VAGAS_DW].[VAGAS] AS B ON A.Cod_vaga = B.VAGAS_Cod_vaga
	WHERE	EXISTS (SELECT	1
					FROM	[hrh-data].[dbo].[Fichas-DescrGeral] AS A1
					WHERE	A1.Teste_fic = 4
							AND ( A.CodFicha1_vaga = A1.Cod_fic ) )

	UNION ALL

	SELECT	A.Cod_vaga AS COD_VAGA ,
			A.CodFicha2_vaga AS COD_TESTE ,
			2 AS NUM_TESTE_VAGA
	FROM	[hrh-data].[dbo].[Vagas] AS A		INNER JOIN [VAGAS_DW].[VAGAS_DW].[VAGAS] AS B ON A.Cod_vaga = B.VAGAS_Cod_vaga
	WHERE	EXISTS (SELECT	1
					FROM	[hrh-data].[dbo].[Fichas-DescrGeral] AS A1
					WHERE	A1.Teste_fic = 4
							AND ( A.CodFicha2_vaga = A1.Cod_fic ) )

	UNION ALL

	SELECT	A.Cod_vaga AS COD_VAGA ,
			A.CodFicha3_vaga AS COD_TESTE ,
			3 AS NUM_TESTE_VAGA
	FROM	[hrh-data].[dbo].[Vagas] AS A		INNER JOIN [VAGAS_DW].[VAGAS_DW].[VAGAS] AS B ON A.Cod_vaga = B.VAGAS_Cod_vaga
	WHERE	EXISTS (SELECT	1
					FROM	[hrh-data].[dbo].[Fichas-DescrGeral] AS A1
					WHERE	A1.Teste_fic = 4
							AND ( A.CodFicha3_vaga = A1.Cod_fic ) )
	UNION ALL

	SELECT	A.Cod_vaga AS COD_VAGA ,
			A.CodFicha4_vaga AS COD_TESTE ,
			4 AS NUM_TESTE_VAGA
	FROM	[hrh-data].[dbo].[Vagas] AS A		INNER JOIN [VAGAS_DW].[VAGAS_DW].[VAGAS] AS B ON A.Cod_vaga = B.VAGAS_Cod_vaga
	WHERE	EXISTS (SELECT	1
					FROM	[hrh-data].[dbo].[Fichas-DescrGeral] AS A1
					WHERE	A1.Teste_fic = 4
							AND ( A.CodFicha4_vaga = A1.Cod_fic ) ) ;


	-- Inserir registros na tabela:
	INSERT INTO [VAGAS_DW].[TMP_VAGAS_TESTES] (COD_VAGA, COD_TESTE, NUM_TESTE_VAGA)
	SELECT	A.COD_VAGA ,
			A.COD_TESTE ,
			A.NUM_TESTE_VAGA
	FROM	#TMP_VAGAS_TESTES AS A ;