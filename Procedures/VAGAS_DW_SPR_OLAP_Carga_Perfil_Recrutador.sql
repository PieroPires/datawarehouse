-- =============================================
-- Author: Fiama
-- Create date: 14/08/2019
-- Description: Script com a rotina de carga OLAP do Cubo de Login_VagasEpartner_Clientes
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'VAGAS_DW_SPR_OLAP_Carga_Perfil_Recrutador')
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Perfil_Recrutador]
GO

CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Perfil_Recrutador]
AS
SET NOCOUNT ON

-- Remove os registros existentes na tabela temporária:
DELETE FROM [VAGAS_DW].[Perfil_Recrutador]
FROM [VAGAS_DW].[Perfil_Recrutador] AS A
WHERE EXISTS (SELECT	*
			  FROM	[VAGAS_DW].[TMP_Perfil_Recrutador] AS A1
			  WHERE	A.ID = A1.ID) ;


-- Insere os registros na tabela OLAP:
INSERT INTO [VAGAS_DW].[Perfil_Recrutador] (ID,Status_Assinatura,Plano,DtProx_Credito,Qtd_Credito_Contratado,Vigencia_contrato,Renovacao,DtUltAtualizacao_Perfil,Cod_cli)
SELECT	A.ID ,
		A.Status_Assinatura ,
		A.Plano ,
		A.DtProx_Credito ,
		A.Qtd_Credito_Contratado ,
		A.Vigencia_contrato ,
		A.Renovacao ,
		A.DtUltAtualizacao_Perfil ,
		A.Cod_cli
FROM	[VAGAS_DW].[TMP_Perfil_Recrutador] AS A ;