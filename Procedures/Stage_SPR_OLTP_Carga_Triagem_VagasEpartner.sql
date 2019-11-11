-- =============================================
-- Author: Fiama
-- Create date: 09/08/2019
-- Description: Script com a rotina de carga OLTP do Cubo de Triagem_VagasEpartner.
-- =============================================

USE [STAGE] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLTP_Carga_Triagem_VagasEpartner')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Triagem_VagasEpartner]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Triagem_VagasEpartner]
AS
SET NOCOUNT ON

TRUNCATE TABLE [STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner] ;

DECLARE	@Max_Triagem INT = (SELECT MAX(Cod_triagem) FROM [VAGAS_DW].[VAGAS_DW].[Triagem_VagasEpartner]),
		@Max_Triagem_Temp INT = (SELECT MAX(Cod_triagem) FROM [STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner]),
		@Min_Triagem_Dump INT = (SELECT MIN(Cod_debTri) FROM [SRV-SQLSERVER].[hrh-dump].[dbo].[DebugTriagem] WITH(NOLOCK)) ,
		@Max_Triagem_Dump INT = (SELECT MAX(Cod_debTri) FROM [SRV-SQLSERVER].[hrh-dump].[dbo].[DebugTriagem] WITH(NOLOCK)) ,
		@Min_Triagem_Data INT = (SELECT MIN(Cod_debTri) FROM [hrh-data].[dbo].[DebugTriagem]) ,
		@Max_Triagem_Data INT = (SELECT MAX(Cod_debTri) FROM [hrh-data].[dbo].[DebugTriagem]) ;


-- Carga [hrh-dump]:
WHILE (ISNULL(@Max_Triagem, 0) < @Max_Triagem_Dump AND ISNULL(@Max_Triagem_Temp, 0) < @Max_Triagem_Dump)
BEGIN
	INSERT INTO [STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner] (Cod_triagem,Data_triagem,DuracaoSegundos_Triagem,Cod_vaga,Cod_func,Contexto_Triagem,Versao_Triagem,IdConta_CRM,Cod_cli)
	SELECT	TOP 1000000 A.Cod_debTri AS Cod_triagem ,
				CONVERT(DATE, A.Data_debTri) AS Data_triagem ,
				DATEDIFF(SECOND, A.Data_debTri, A.DataFim_debTri) AS DuracaoSegundos_Triagem ,
				A.CodVaga_debTri AS Cod_vaga ,
				A.CodUsu_debTri AS Cod_func ,
				CASE WHEN A.BCC_DebTri = 1 THEN 'BCC'
					 WHEN A.BCA_DebTri = 1 THEN 'BCE'
					 WHEN A.CodVaga_debTri > 0 AND D.ColetaCur_vaga = 0 THEN 'VAGA'
					 WHEN A.CodVaga_debTri > 0 AND D.ColetaCur_vaga = 1	THEN 'CAPTAÇÃO ABERTA'
					 ELSE NULL
				END AS Contexto_Triagem ,
				CASE WHEN A.VersaoTriagem_debTri IS NULL THEN 'Triagem 1.0'
					 WHEN A.VersaoTriagem_debTri = 2 THEN 'Triagem 2.0'
				END AS Versao_Triagem ,
				C.IdContaCRM_cli AS IdConta_CRM ,
				C.Cod_cli
	FROM	[SRV-SQLSERVER].[hrh-dump].[dbo].[DebugTriagem] AS A WITH(NOLOCK)		INNER JOIN [hrh-data].[dbo].[Funcionarios] AS B ON A.CodUsu_debTri = B.Cod_func
																					INNER JOIN [hrh-data].[dbo].[Clientes] AS C ON B.CodCli_func = C.Cod_cli
																					LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS D ON A.CodVaga_debTri = D.Cod_vaga
	WHERE	A.Cod_debTri > ISNULL(@Max_Triagem, 0)
			AND A.Cod_debTri > ISNULL(@Max_Triagem_Temp, 0)
			AND A.Cod_debTri <= @Max_Triagem_Dump
			AND A.SenhaMestre_debTri = 0
	ORDER BY
			A.Cod_debTri ASC

	SET @Max_Triagem_Temp = (SELECT MAX(Cod_triagem) FROM [STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner])
END

-- Carga [hrh-data]:
WHILE (ISNULL(@Max_Triagem, 0) < @Max_Triagem_Data AND ISNULL(@Max_Triagem_Temp, 0) < @Max_Triagem_Data)
BEGIN
	INSERT INTO [STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner] (Cod_triagem,Data_triagem,DuracaoSegundos_Triagem,Cod_vaga,Cod_func,Contexto_Triagem,Versao_Triagem,IdConta_CRM,Cod_cli)
	SELECT	TOP 1000000 A.Cod_debTri AS Cod_triagem ,
				CONVERT(DATE, A.Data_debTri) AS Data_triagem ,
				DATEDIFF(SECOND, A.Data_debTri, A.DataFim_debTri) AS DuracaoSegundos_Triagem ,
				A.CodVaga_debTri AS Cod_vaga ,
				A.CodUsu_debTri AS Cod_func ,
				CASE WHEN A.BCC_DebTri = 1 THEN 'BCC'
					 WHEN A.BCA_DebTri = 1 THEN 'BCE'
					 WHEN A.CodVaga_debTri > 0 AND D.ColetaCur_vaga = 0 THEN 'VAGA'
					 WHEN A.CodVaga_debTri > 0 AND D.ColetaCur_vaga = 1	THEN 'CAPTAÇÃO ABERTA'
					 ELSE NULL
			END AS Contexto_Triagem ,
			CASE WHEN A.VersaoTriagem_debTri IS NULL THEN 'Triagem 1.0'
				 WHEN A.VersaoTriagem_debTri = 2 THEN 'Triagem 2.0'
			END AS Versao_Triagem ,
			C.IdContaCRM_cli AS IdConta_CRM ,
			C.Cod_cli
	FROM	[hrh-data].[dbo].[DebugTriagem] AS A		INNER JOIN [hrh-data].[dbo].[Funcionarios] AS B ON A.CodUsu_debTri = B.Cod_func
														INNER JOIN [hrh-data].[dbo].[Clientes] AS C ON B.CodCli_func = C.Cod_cli
														LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS D ON A.CodVaga_debTri = D.Cod_vaga
	WHERE	A.Cod_debTri > ISNULL(@Max_Triagem, 0)
			AND A.Cod_debTri > ISNULL(@Max_Triagem_Temp, 0)
			AND A.Cod_debTri <= @Max_Triagem_Data
			AND A.SenhaMestre_debTri = 0
	ORDER BY
			A.Cod_debTri ASC

	SET @Max_Triagem_Temp = (SELECT MAX(Cod_triagem) FROM [STAGE].[VAGAS_DW].[TMP_Triagem_VagasEpartner])
END