USE VAGAS_DW
GO
-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_OLAP_Carga_Candidato_Cliente

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Candidato_Cliente' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidato_Cliente
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidato_Cliente 

AS
SET NOCOUNT ON

-- Limpar dados da tabela fato com base na tabela Origem
DELETE VAGAS_DW.CANDIDATO_CLIENTE
FROM VAGAS_DW.CANDIDATO_CLIENTE A
WHERE NOT EXISTS ( SELECT 1 FROM [hrh-data].dbo.[CandidatoxCliente]
				WHERE CHAVESQL_CANDCLI = A.COD_SQL)

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CANDIDATO_CLIENTE
SELECT * FROM VAGAS_DW.TMP_CANDIDATO_CLIENTE

