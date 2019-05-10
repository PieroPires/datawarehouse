-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_Candidaturas
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Candidaturas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidaturas
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
--				Processo atrelado à carga de candidatos
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidaturas @COD_HISTCAND INT = NULL

AS
SET NOCOUNT ON

TRUNCATE TABLE VAGAS_DW.TMP_CANDIDATURAS 
TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_CANDIDATURAS 

IF @COD_HISTCAND IS NULL
SET @COD_HISTCAND = 0

INSERT INTO VAGAS_DW.TMP_CANDIDATURAS
SELECT Cod_histCand,CodCand_HistCand,CodVaga_HistCand,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DtPrimCand_histCand,112))
	--,B.CPF_cand
FROM [HRH-DATA].DBO.HistoricoCandidaturas A
--INNER JOIN [HRH-DATA].DBO.Candidatos B ON B.Cod_cand = A.CodCand_histCand
WHERE Cod_HistCand > @COD_HISTCAND

-- INSERIR DIRETAMENTE NO BD VAGAS_DW
INSERT INTO VAGAS_DW.VAGAS_DW.TMP_CANDIDATURAS
SELECT * FROM VAGAS_DW.TMP_CANDIDATURAS