-- =============================================
-- Author: Fiama
-- Create date: 12/07/2018
-- Description: Procedure para alimentação do DW
-- =============================================

USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Requisicoes_Vagas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Requisicoes_Vagas
GO


CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Requisicoes_Vagas

AS
SET NOCOUNT ON


-- Limpeza da tabela:
TRUNCATE TABLE [VAGAS_DW].[REQUISICOES_VAGAS] ;


-- CARREGAR CUBO
INSERT INTO [VAGAS_DW].[REQUISICOES_VAGAS]
SELECT * FROM [STAGE].[VAGAS_DW].[TMP_REQUISICOES_VAGAS] ;