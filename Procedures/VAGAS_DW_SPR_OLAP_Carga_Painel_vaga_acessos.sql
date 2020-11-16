USE [VAGAS_DW]
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Painel_vaga_acessos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Painel_vaga_acessos]
GO

-- =============================================
-- Author: Fiama Cristi
-- Create date: 06/10/2020
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Painel_vaga_acessos]

AS
SET NOCOUNT ON

-- Apaga os registros existentes na tabela OLAP:
DELETE FROM [VAGAS_DW].[PainelVaga_acessos]
FROM	[VAGAS_DW].[PainelVaga_acessos] AS Pva_DW
WHERE	EXISTS (SELECT *
				FROM	[stage].[VAGAS_DW].[Tmp_PainelVaga_acessos] AS TmpPva_DW_A1
				WHERE	Pva_DW.Cod_chave_acessoPainel = TmpPva_DW_A1._id COLLATE SQL_Latin1_General_CP1_CI_AI) ;


-- Popula a tabela OLAP:
INSERT INTO [VAGAS_DW].[PainelVaga_acessos] (Cod_acessoPainel,Cod_cli_acessoPainel,Cod_vaga_acessoPainel,Cod_func_acessoPainel,Data_acessoPainel,Tipo_acessoPainel,
Cod_chave_acessoPainel)
SELECT	row_number() OVER(ORDER BY [_source.timestamp]),
		[_source.cliente],
		[_source.vaga],
		[_source.funcionario],
		[_source.timestamp],
		[_source.tipo],
		[_id]
FROM	[stage].[VAGAS_DW].[Tmp_PainelVaga_acessos] ;