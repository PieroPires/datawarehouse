-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_Candidato_Cliente'19010101'
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Candidato_Cliente' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidato_Cliente
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Candidato_Cliente
@CODIGO INT = NULL

AS
SET NOCOUNT ON

-- NÃO VAMOS UTILIZAR O BD STAGE NESTE CASO
TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_CANDIDATO_CLIENTE 

INSERT INTO VAGAS_DW.VAGAS_DW.TMP_CANDIDATO_CLIENTE 
SELECT A.ChaveSQL_candCli AS Cod_SQL,
	   A.CodCliente_candCli AS CodCli,
	   B.Ident_cli AS Cliente,
	   A.CodCand_candCli AS Cod_Cand,
	   CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DtIniStatus_candCli,112)) AS Data_Cadastro,
	   CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DtExpiracao_candCli,112)) AS Data_Expiracao,
	   CASE WHEN Estado_candCli = 0 THEN 0 ELSE 1 END AS FLAG_UsoLiberado
FROM [hrh-data].dbo.[CandidatoxCliente] A
INNER JOIN [hrh-data].dbo.Clientes B ON B.Cod_Cli = A.CodCliente_candCli 
WHERE A.ChaveSQL_candCli > @CODIGO OR @CODIGO IS NULL -- CARGA INCREMENTAL

---- Remoçoes
--SELECT NULL AS COD_SQL,
--	   A.CodCliente_hist AS COD_CLI,
--	   B.Ident_Cli AS CLIENTE,
--	   A.CODCAND_HIST AS COD_CAND,
--	   C.DT_HIST AS DATA_CADASTRO,
--	   NULL AS DATA_EXPIRACAO,
--	   0 AS FLAG_USOLIBERADO,
--	   A.DT_HIST AS DATA_REMOCAO,
--	   1 AS FLAG_REMOCAO
--FROM EntradaHistorico A
--INNER JOIN Clientes B ON B.Cod_Cli = A.CodCliente_hist
--OUTER APPLY ( SELECT TOP 1 * FROM EntradaHistorico
--			  WHERE CodCand_hist = A.CodCand_hist
--			  AND CodCliente_hist = A.CodCliente_hist 
--			  AND Tipo_Hist <> 0
--			  ORDER BY ChaveSQL_hist ASC ) C
--WHERE A.Tipo_Hist = 0 -- Remoção
--AND NOT EXISTS ( SELECT 1 FROM [CandidatoXCliente]
--				 WHERE CodCand_candcli = A.CodCand_hist
--				 AND CodCliente_candCli = A.CodCliente_hist )