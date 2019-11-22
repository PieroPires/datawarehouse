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

DECLARE @Max_Triagem_Temp INT = (SELECT MAX(Cod_Triagem) FROM [STAGE].[VAGAS_DW].[TMP_TRIAGEM_VAGAS_EPARTNER]) ,
		@Max_Triagem INT = (SELECT MAX(Cod_Triagem) FROM [VAGAS_DW].[TRIAGEM_VAGAS_EPARTNER]) ;

WHILE ISNULL(@Max_Triagem, 0) < @Max_Triagem_Temp
BEGIN
	INSERT INTO [VAGAS_DW].[TRIAGEM_VAGAS_EPARTNER] (COD_TRIAGEM,DATA_TRIAGEM,DURACAOSEGUNDOS_TRIAGEM,COD_VAGA,COD_FUNC,CONTEXTO_TRIAGEM,VERSAO_TRIAGEM,CONTA_ID,COD_CLI)
	SELECT	TOP 1000000
			A.COD_TRIAGEM ,
			A.DATA_TRIAGEM ,
			A.DURACAOSEGUNDOS_TRIAGEM ,
			A.COD_VAGA ,
			A.COD_FUNC ,
			A.CONTEXTO_TRIAGEM ,
			A.VERSAO_TRIAGEM ,
			A.CONTA_ID ,
			A.COD_CLI
	FROM	[STAGE].[VAGAS_DW].[TMP_TRIAGEM_VAGAS_EPARTNER] AS A
	WHERE	A.Cod_Triagem <= @Max_Triagem_Temp
			AND A.Cod_Triagem > ISNULL(@Max_Triagem, 0)
	ORDER BY
			A.Cod_Triagem ASC

	SET	@Max_Triagem = (SELECT MAX(Cod_Triagem) FROM [VAGAS_DW].[TRIAGEM_VAGAS_EPARTNER])
END