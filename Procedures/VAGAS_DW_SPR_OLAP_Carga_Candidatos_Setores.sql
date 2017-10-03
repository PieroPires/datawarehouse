-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_Carga_Candidatos

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Candidatos_Setores' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidatos_Setores
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidatos_Setores

AS
SET NOCOUNT ON

DELETE VAGAS_DW.CANDIDATOS_SETORES
FROM VAGAS_DW.CANDIDATOS_SETORES A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_CANDIDATOS_SETORES
					WHERE COD_CAND = A.COD_CAND )

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CANDIDATOS_SETORES
SELECT * FROM VAGAS_DW.TMP_CANDIDATOS_SETORES
