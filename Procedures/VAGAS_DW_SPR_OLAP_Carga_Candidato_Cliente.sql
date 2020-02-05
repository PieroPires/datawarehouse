USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Candidato_Cliente' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidato_Cliente
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================

-- =============================================
-- Alterações
-- 05/02/2020 - Diego Gatto - Ajustado para utilizar as tabelas TMP na base de dados stage e não vagas_dw
-- =============================================


CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidato_Cliente 

AS
SET NOCOUNT ON

-- Limpar dados da tabela fato com base na tabela Origem
DELETE VAGAS_DW.CANDIDATO_CLIENTE
FROM VAGAS_DW.CANDIDATO_CLIENTE A
WHERE NOT EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATO_CLIENTE] AS B
				WHERE B.COD_SQL = A.COD_SQL)

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CANDIDATO_CLIENTE
SELECT * FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATO_CLIENTE]