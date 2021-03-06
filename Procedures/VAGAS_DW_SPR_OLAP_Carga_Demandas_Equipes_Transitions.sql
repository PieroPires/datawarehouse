-- EXEC [VAGAS_DW].[VAGAS_DW].[SPR_OLAP_Carga_Demandas_Equipes_Transitions]
USE VAGAS_DW ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Demandas_Equipes_Transitions' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Demandas_Equipes_Transitions]
GO

-- =============================================
-- Author:      Fiama dos Santos Cristi
-- Create date: 24/01/2017
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Demandas_Equipes_Transitions]

AS
SET NOCOUNT ON


-- LIMPAR TABELA FATO:
TRUNCATE TABLE [VAGAS_DW].[VAGAS_DW].[DEMANDAS_EQUIPES_TRANSITIONS] ;


-- Carga dos dados na estrutura OLAP:
INSERT INTO [VAGAS_DW].[VAGAS_DW].[DEMANDAS_EQUIPES_TRANSITIONS] (ID_DEMANDA,NUMERO_DEMANDA,EQUIPE_PROJETO,STATUS_ANTERIOR,TRANSICAO,QTD_DIAS,QTD_TRANSICOES,ULT_RESPONSAVEL, ULT_DATA_TRANSICAO,DATA_CRIACAO,STATUS_DEMANDA)

SELECT	LTRIM(RTRIM(A.ID_DEMANDA)) AS ID_DEMANDA ,
		LTRIM(RTRIM(A.NUMERO_DEMANDA)) AS NUMERO_DEMANDA , 
		LTRIM(RTRIM(A.EQUIPE_PROJETO)) AS EQUIPE_PROJETO , 
		A.STATUS_ANTERIOR , 
		A.TRANSICAO , 
		A.QTD_DIAS , 
		A.QTD_TRANSICOES , 
		A.ULT_RESPONSAVEL , 
		A.ULT_DATA_TRANSICAO , 
		A.DATA_CRIACAO ,
		A.STATUS_DEMANDA
FROM	[STAGE].[VAGAS_DW].[TMP_DEMANDAS_EQUIPES_TRANSITIONS] AS A ;