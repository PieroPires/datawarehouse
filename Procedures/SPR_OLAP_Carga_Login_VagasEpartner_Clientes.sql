-- =============================================
-- Author: Fiama
-- Create date: 14/08/2019
-- Description: Script com a rotina de carga OLAP do Cubo de Login_VagasEpartner_Clientes
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'SPR_OLAP_Carga_Login_VagasEpartner_Clientes')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Login_VagasEpartner_Clientes]
GO

CREATE PROCEDURE SPR_OLAP_Carga_Login_VagasEpartner_Clientes
AS
SET NOCOUNT ON

WHILE EXISTS (SELECT * FROM [STAGE].[VAGAS_DW].[TMP_Login_VagasEpartner_Clientes] AS A1
			  WHERE	NOT EXISTS (SELECT *
								FROM	[VAGAS_DW].[Login_VagasEpartner_Clientes] AS AA1
								WHERE	A1.Cod_login = AA1.Cod_login))

INSERT INTO [VAGAS_DW].[Login_VagasEpartner_Clientes] (Cod_login,Cod_cli,IdConta_CRM,Cod_func,Data_login,Tipo)
SELECT	TOP 1000000 A.Cod_login ,
		A.Cod_cli ,
		A.IdConta_CRM ,
		A.Cod_func ,
		A.Data_login ,
		A.Tipo
FROM	[STAGE].[VAGAS_DW].[TMP_Login_VagasEpartner_Clientes] AS A
WHERE	NOT EXISTS (SELECT *
					FROM	[VAGAS_DW].[Login_VagasEpartner_Clientes] AS A1
					WHERE	A.Cod_login = A1.Cod_login)
ORDER BY
		A.Cod_login ASC ;