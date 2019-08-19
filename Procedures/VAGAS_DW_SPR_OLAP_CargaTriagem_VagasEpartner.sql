-- =============================================
-- Author: Fiama
-- Create date: 12/08/2019
-- Description: Script com a rotina de carga OLAP do Cubo de Triagem_VagasEpartner.
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLAP_Carga_Triagem_VagasEpartner')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Triagem_VagasEpartner]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Triagem_VagasEpartner]
AS
SET NOCOUNT ON

DECLARE @Max_Triagem_Temp INT = (SELECT MAX(Cod_Triagem) FROM [STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner]) ,
		@Max_Triagem INT = (SELECT MAX(Cod_Triagem) FROM [VAGAS_DW].[Triagem_VagasEpartner]) ;

WHILE ISNULL(@Max_Triagem, 0) < @Max_Triagem_Temp
BEGIN
	INSERT INTO [VAGAS_DW].[Triagem_VagasEpartner] (Cod_Triagem,Data_Triagem,DuracaoSegundos_Triagem,Cod_vaga,Cod_func,Contexto_Triagem,Versao_Triagem,IdConta_CRM,Cod_cli)
	SELECT	TOP 1000000
			A.Cod_Triagem ,
			A.Data_Triagem ,
			A.DuracaoSegundos_Triagem ,
			A.Cod_vaga ,
			A.Cod_func ,
			A.Contexto_Triagem ,
			A.Versao_Triagem ,
			A.IdConta_CRM ,
			A.Cod_cli
	FROM	[STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner] AS A
	WHERE	A.Cod_Triagem <= @Max_Triagem_Temp
			AND A.Cod_Triagem > ISNULL(@Max_Triagem, 0)
	ORDER BY
			A.Cod_Triagem ASC

	SET	@Max_Triagem = (SELECT MAX(Cod_Triagem) FROM [VAGAS_DW].[Triagem_VagasEpartner])
END