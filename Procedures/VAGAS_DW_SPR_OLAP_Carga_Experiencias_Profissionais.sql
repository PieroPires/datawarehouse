-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_OLAP_Carga_Experiencias_Profissionais

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Experiencias_Profissionais' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Experiencias_Profissionais
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Experiencias_Profissionais 

AS
SET NOCOUNT ON

DELETE VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS  
FROM VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_EXPERIENCIAS_PROFISSIONAIS  
					WHERE COD_CAND = A.COD_CAND ) 

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS 
SELECT * FROM VAGAS_DW.TMP_EXPERIENCIAS_PROFISSIONAIS 
