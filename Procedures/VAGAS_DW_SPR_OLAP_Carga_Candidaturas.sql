USE VAGAS_DW
GO
-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_Carga_Candidatos

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Candidaturas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidaturas
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Candidaturas 

AS
SET NOCOUNT ON

DECLARE @COD_HISTCAND INT

SELECT @COD_HISTCAND = MIN(COD_HISTCAND) FROM STAGE.VAGAS_DW.TMP_CANDIDATURAS

DELETE VAGAS_DW.CANDIDATURAS 
FROM VAGAS_DW.CANDIDATURAS A
WHERE COD_HISTCAND >= @COD_HISTCAND

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CANDIDATURAS (Cod_histCand,CodCand_HistCand,CodVaga_HistCand,DATA_CANDIDATURA)
SELECT * FROM STAGE.VAGAS_DW.TMP_CANDIDATURAS