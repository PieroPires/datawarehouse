USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_ALTERACOES_MERCADO' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_ALTERACOES_MERCADO
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 19/05/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_ALTERACOES_MERCADO 
AS
SET NOCOUNT ON

TRUNCATE TABLE VAGAS_DW.ALTERACOES_MERCADO

INSERT INTO VAGAS_DW.ALTERACOES_MERCADO
SELECT * FROM VAGAS_DW.TMP_ALTERACOES_MERCADO

-- criar registro inicial
INSERT INTO VAGAS_DW.ALTERACOES_MERCADO (CONTA,DATA_ALTERACAO,VALOR_ANTERIOR,VALOR_ATUALIZADO,CONTA_ID)
SELECT A.CONTA,
	   '20000101' AS DATA_ALTERACAO,
	   NULL AS VALOR_ANTERIOR,
	   A.VALOR_ANTERIOR AS VALOR_ATUALIZADO,
	   A.CONTA_ID
FROM VAGAS_DW.ALTERACOES_MERCADO A
WHERE A.DATA_ALTERACAO = ( SELECT MIN(DATA_ALTERACAO) 
						 FROM VAGAS_DW.ALTERACOES_MERCADO
						 WHERE CONTA_ID = A.CONTA_ID )
AND ISNULL(A.VALOR_ANTERIOR,'') <> ''

-- manter apenas ultima posicao do dia
DELETE VAGAS_DW.ALTERACOES_MERCADO 
FROM VAGAS_DW.ALTERACOES_MERCADO A
WHERE DATA_ALTERACAO <> ( SELECT MAX(DATA_ALTERACAO) 
						  FROM VAGAS_DW.ALTERACOES_MERCADO
						  WHERE CONTA_ID = A.CONTA_ID
						  AND CONVERT(VARCHAR,DATA_ALTERACAO,112) = CONVERT(VARCHAR,A.DATA_ALTERACAO,112) )