-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_Candidaturas_Fonte_Candidatura
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Candidaturas_Fonte_Candidatura' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidaturas_Fonte_Candidatura
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
--				Processo atrelado à carga de candidatos
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidaturas_Fonte_Candidatura

AS
SET NOCOUNT ON

TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_CANDIDATURAS_FONTE_CANDIDATURA  

DECLARE @COD_CANDVAGA INT

SELECT @COD_CANDVAGA = MAX(COD_CandVAGA) FROM VAGAS_DW.VAGAS_DW.CONTROLE_FONTE_CANDIDATURAS

IF @COD_CANDVAGA IS NULL -- CARGA FULL (vagas criadas a partir de 2016)
	INSERT INTO VAGAS_DW.VAGAS_DW.TMP_CANDIDATURAS_FONTE_CANDIDATURA (COD_CandVAGA,COD_VAGA,COD_CAND,FONTE)
	SELECT Cod_candVaga,
		   CodVaga_candVaga AS COD_VAGA,
		   CodCand_candVaga AS COD_CAND,
		   ISNULL(B.Descr_FonteCandidatura,'') AS FONTE
	FROM [HRH-DATA].DBO.CandidatoXVagas A
	LEFT OUTER JOIN [HRH-DATA].DBO.Cad_FonteCandidaturas B ON B.Cod_FonteCandidatura = A.FonteTipo_candVaga
	WHERE A.Cod_candVaga >= 519804270 
ELSE  -- CARGA INCREMENTAL BASEADO NO ÚLTIMO ID
	INSERT INTO VAGAS_DW.VAGAS_DW.TMP_CANDIDATURAS_FONTE_CANDIDATURA (COD_CandVAGA,COD_VAGA,COD_CAND,FONTE)
	SELECT Cod_candVaga,
		   CodVaga_candVaga AS COD_VAGA,
		   CodCand_candVaga AS COD_CAND,
		   B.Descr_FonteCandidatura AS FONTE
	FROM [HRH-DATA].DBO.CandidatoXVagas A
	LEFT OUTER JOIN [HRH-DATA].DBO.Cad_FonteCandidaturas B ON B.Cod_FonteCandidatura = A.FonteTipo_candVaga
	WHERE A.Cod_candVaga > @COD_CANDVAGA 

-- ATUALIZAÇÃO DA FONTE DE CANDIDATURA DO CUBO DE CANDIDATURAS
UPDATE VAGAS_DW.VAGAS_DW.CANDIDATURAS SET FONTE_CANDIDATURA = B.FONTE
FROM VAGAS_DW.VAGAS_DW.CANDIDATURAS A
INNER JOIN VAGAS_DW.VAGAS_DW.TMP_CANDIDATURAS_FONTE_CANDIDATURA B ON B.COD_CAND = A.CodCand_HistCand
														AND B.COD_VAGA = A.CodVaga_HistCand
WHERE A.FONTE_CANDIDATURA IS NULL

-- Realizar o Controle de registros da [CandidatoXVagas] que já foram inseridos
TRUNCATE TABLE VAGAS_DW.VAGAS_DW.CONTROLE_FONTE_CANDIDATURAS 

INSERT INTO VAGAS_DW.VAGAS_DW.CONTROLE_FONTE_CANDIDATURAS 
SELECT MAX(COD_CandVAGA) FROM [HRH-DATA].DBO.CandidatoXVagas

