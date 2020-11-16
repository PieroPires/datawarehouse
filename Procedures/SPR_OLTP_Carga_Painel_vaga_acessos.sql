USE [stage] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Painel_vaga_acessos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Painel_vaga_acessos]
GO

-- =============================================
-- Author: Fiama Cristi
-- Create date: 06/10/2020
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Painel_vaga_acessos]

AS
SET NOCOUNT ON

-- Limpa a tabela temporária stage:
TRUNCATE TABLE [VAGAS_DW].[Tmp_PainelVaga_acessos] ;

-- Carga dos dados na Tmp_PainelVaga_acessos:
DECLARE @CMD VARCHAR(8000) ;
SET @CMD = 'Z:\Scripts\Python3\python Z:\Scripts\Scripts_Python\Painel_vaga_acessos.py'

EXEC MASTER.DBO.XP_CMDSHELL @CMD