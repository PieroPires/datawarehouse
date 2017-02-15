-- select * from vagas_dw.TMP_VAGAS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_COMUNIDADES
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_COMUNIDADES' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_COMUNIDADES
GO


-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 23/01/2017
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_COMUNIDADES 

AS
SET NOCOUNT ON

DECLARE @DATA_REF SMALLDATETIME

-- Neste caso consideraremos vagas a partir da data ref. (ref = Início do ano anterior)
SELECT @DATA_REF  = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,YEAR(GETDATE())) + '0101')

TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_COMUNIDADES

INSERT INTO VAGAS_DW.VAGAS_DW.TMP_COMUNIDADES
SELECT @DATA_REF AS DATA_REFERENCIA,
	   A.Cod_div AS COD_DIV,
	   A.Nome_Div AS NOME_DIVISAO,
	   SUM(CASE WHEN C.Autorizacao_candCom > 0 THEN 1 ELSE 0 END) AS QTD_CAND_AUTORIZADOS,
	   SUM(CASE WHEN C.Autorizacao_candCom = 0 THEN 1 ELSE 0 END) AS QTD_CAND_AGUARD_AUTORIZACAO,
	   D.QTD_VAGAS,
	   ISNULL(D.QTD_VAGAS_EMPRESAS_CLIENTES,0) AS QTD_VAGAS_EMPRESAS_CLIENTES,
	   ISNULL(D.QTD_VAGAS_EMPRESAS_NAO_CLIENTES,0) AS QTD_VAGAS_EMPRESAS_NAO_CLIENTES,
	   SUM(CASE WHEN (CodCand_fnt IS NOT NULL) THEN 1 ELSE 0 END) AS QTD_CV_CAPTADO_COMUNIDADE
FROM [HRH-DATA].DBO.Divisoes A
INNER JOIN [HRH-DATA].DBO.Clientes B ON B.Cod_Cli = A.CodCli_div
INNER JOIN [HRH-DATA].DBO.CandidatoXComunidade C ON C.CodDiv_candCom = A.Cod_Div
OUTER APPLY ( SELECT COUNT(DISTINCT A1.Cod_Vaga) AS QTD_VAGAS,
					 SUM(CASE WHEN Restrito_cli = 0 THEN 1 ELSE 0 END) AS QTD_VAGAS_EMPRESAS_CLIENTES,
					 SUM(CASE WHEN Restrito_cli = 1 THEN 1 ELSE 0 END) AS QTD_VAGAS_EMPRESAS_NAO_CLIENTES
			  FROM [HRH-DATA].DBO.Vagas A1
			  INNER JOIN [HRH-DATA].DBO.Clientes B1 ON B1.Cod_Cli = A1.CodCliente_vaga
			  WHERE A1.CodDivVeic_vaga = A.Cod_Div
			  AND A1.DtInicioWeb_vaga <= GETDATE()
			  AND A1.DtExpiracaoWeb_vaga >= GETDATE()
			  AND A1.VagaComExt_vaga = 1
			  AND A1.VeiculacaoSuspensa_vaga = 0   ) D
LEFT OUTER JOIN [HRH-DATA].DBO.[Cand-Fonte] E ON E.CodCand_fnt = C.CodCand_candCom 
			  AND E.TipoNav_fnt = A.Cod_div
WHERE A.CodCli_div > 0 
AND A.CodNavEx_div IN (400,500)
AND A.Cod_div NOT IN (20098,29538)
AND B.Restrito_cli = 0
GROUP BY A.Cod_div,
	     A.Nome_Div,
		 D.QTD_VAGAS,
		 D.QTD_VAGAS_EMPRESAS_CLIENTES,
		 D.QTD_VAGAS_EMPRESAS_NAO_CLIENTES

