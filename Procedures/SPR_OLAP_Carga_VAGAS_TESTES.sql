-- EXEC [VAGAS_DW].[VAGAS_DW].[SPR_OLAP_Carga_VAGAS_TESTES] ;
USE VAGAS_DW ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_VAGAS_TESTES' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_VAGAS_TESTES]
GO

-- =============================================
-- Author:      Fiama dos Santos Cristi
-- Create date: 24/01/2017
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_VAGAS_TESTES]

AS
SET NOCOUNT ON


-- LIMPAR TABELA FATO:
TRUNCATE TABLE [VAGAS_DW].[VAGAS_DW].[VAGAS_TESTES]


-- Carga dos dados na estrutura OLAP:
INSERT INTO [VAGAS_DW].[VAGAS_DW].[VAGAS_TESTES] (COD_VAGA, COD_TESTE, NUM_TESTE_VAGA)
SELECT	A.COD_VAGA ,
		A.COD_TESTE ,
		A.NUM_TESTE_VAGA
FROM	[STAGE].[VAGAS_DW].[TMP_VAGAS_TESTES] AS A ;