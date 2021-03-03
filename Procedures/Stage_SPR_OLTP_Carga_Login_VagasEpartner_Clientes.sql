-- =============================================
-- Author: Fiama
-- Create date: 14/08/2019
-- Description: Script com a rotina de carga OLTP do Cubo de Login_VagasEpartner_Clientes
-- =============================================

USE [STAGE] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLTP_Carga_Login_VagasEpartner_Clientes')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Login_VagasEpartner_Clientes]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Login_VagasEpartner_Clientes]
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_Login_VagasEpartner_Clientes] ;

DECLARE	@Max_Login INT = (SELECT MAX(Cod_login) FROM [VAGAS_DW].[VAGAS_DW].[Login_VagasEpartner_Clientes]) ,
		@Max_LoginTemp INT = (SELECT MAX(Cod_login) FROM [VAGAS_DW].[TMP_Login_VagasEpartner_Clientes]) ,
		@Max_LoginData INT = (SELECT MAX(Cod_log) FROM [hrh-data].[dbo].[Clientes-Login] WHERE ISNULL(CodUsuManut_log,0) < 1) ;

WHILE ISNULL(@Max_Login, 0) < @Max_LoginData AND ISNULL(@Max_LoginTemp, 0) < @Max_LoginData
BEGIN
	INSERT INTO [VAGAS_DW].[TMP_Login_VagasEpartner_Clientes] (Cod_login,Cod_cli,IdConta_CRM,Cod_func,Data_login,Tipo)
	SELECT	TOP 1000000 A.Cod_log AS Cod_login ,
			A.CodCli_log AS Cod_cli ,
			B.IdContaCRM_cli AS IdConta_CRM ,
			A.CodFunc_log AS Cod_func ,
			CONVERT(DATE, A.Data_log) AS Data_login ,
			IIF(A.Op_log = 1, 'Login', 'Logout') AS Tipo
	FROM	[hrh-data].[dbo].[Clientes-Login] AS A		INNER JOIN [hrh-data].[dbo].[Clientes] AS B ON A.CodCli_log = B.Cod_cli
	WHERE	A.Cod_log > ISNULL(@Max_Login, 0)
			AND A.Cod_log > ISNULL(@Max_LoginTemp, 0)
			AND ISNULL(A.CodUsuManut_log,0) < 1
	ORDER BY
			A.Cod_log ASC
	SET	@Max_LoginTemp = (SELECT MAX(Cod_login) FROM [VAGAS_DW].[TMP_Login_VagasEpartner_Clientes])
END