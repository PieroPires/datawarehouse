-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 05/09/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Clientes_Login' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Clientes_Login]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLTP_Carga_Clientes_Login]
AS
SET NOCOUNT ON

-- Limpeza da tabela temporária:
TRUNCATE TABLE [VAGAS_DW].[TMP_CLIENTES_LOGIN] ;

INSERT INTO [VAGAS_DW].[TMP_CLIENTES_LOGIN]
SELECT	A.Cod_log AS COD_LOGIN ,
		A.CodCli_log AS COD_CLI ,
		A.CodFunc_log AS COD_FUNC ,
		CONVERT(SMALLDATETIME, CONVERT(CHAR(10), A.Data_log, 112)) AS DATA_LOGIN ,
		CASE 
			WHEN A.Op_log = 1
				THEN 'LOGIN'
			WHEN A.Op_log = 0
				THEN 'LOGOUT'
		END AS TIPO ,
		IIF(A.Data_log >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE)), 'SIM', 'NÃO') AS USUARIO_ATIVO ,
		IIF(A.Data_log >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE))
						  AND B.Removido_func  = 1, 'SIM', 'NÃO') AS USUARIO_ATIVO_REMOVIDO
FROM	[hrh-data].[dbo].[Clientes-Login] AS A		INNER JOIN [hrh-data].[dbo].[Funcionarios] AS B ON A.CodFunc_log = B.Cod_func ;