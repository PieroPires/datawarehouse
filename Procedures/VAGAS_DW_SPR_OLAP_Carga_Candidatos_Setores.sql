USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Candidatos_Setores' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidatos_Setores
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


CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidatos_Setores

AS
SET NOCOUNT ON

DELETE VAGAS_DW.CANDIDATOS_SETORES
FROM VAGAS_DW.CANDIDATOS_SETORES A
WHERE EXISTS ( SELECT 1 FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS_SETORES]
					WHERE COD_CAND = A.COD_CAND )

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CANDIDATOS_SETORES
SELECT * FROM [STAGE].[VAGAS_DW].[TMP_CANDIDATOS_SETORES]
