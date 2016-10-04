-- EXEC VAGAS_DW.SPR_OLAP_Carga_Vagas_Validacao
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Vagas_Validacao' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Vagas_Validacao
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 30/08/2016
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Vagas_Validacao

AS
SET NOCOUNT ON

-- LIMPAR TABELA FATO COM REGISTROS EXISTENTES
--DELETE VAGAS_DW.VAGAS_VALIDACAO
--FROM VAGAS_DW.VAGAS_VALIDACAO A
--WHERE EXISTS ( SELECT * FROM VAGAS_DW.TMP_VAGAS_VALIDACAO
--				WHERE COD_VALIDACAO = A.COD_VALIDACAO )

TRUNCATE TABLE VAGAS_DW.VAGAS_VALIDACAO

-- LIMPAR REGISTROS SEM VALIDAÇÃO
DELETE VAGAS_DW.TMP_VAGAS_VALIDACAO
FROM VAGAS_DW.TMP_VAGAS_VALIDACAO
WHERE DATA_VALIDACAO IS NULL

-- INSERIR TABELA FATO
INSERT INTO VAGAS_DW.VAGAS_VALIDACAO (COD_VALIDACAO,COD_VAGA,DATA_ENTRADA,DATA_VALIDACAO,USUARIO,CLIENTE,TIPO_AJUSTE)
SELECT COD_VALIDACAO,COD_VAGA,DATA_ENTRADA,DATA_VALIDACAO,USUARIO,CLIENTE,TIPO_AJUSTE
FROM VAGAS_DW.TMP_VAGAS_VALIDACAO

-- EXCLUIR REGISTROS INCONSISTENTES
SELECT COD_VAGA,
	   DATA_VALIDACAO,
	   TIPO_AJUSTE,
	   MIN(COD_VALIDACAO) AS MENOR_COD_VALIDACAO,
	   COUNT(*) AS QTD 
INTO #TMP_REGISTROS_INCONSISTENTES
FROM VAGAS_DW.VAGAS_VALIDACAO
WHERE DATA_VALIDACAO >= '20160101'
GROUP BY COD_VAGA,
	   DATA_VALIDACAO,
	   TIPO_AJUSTE
HAVING COUNT(*) > 1

DELETE VAGAS_DW.VAGAS_VALIDACAO
FROM VAGAS_DW.VAGAS_VALIDACAO A
WHERE EXISTS ( SELECT * FROM #TMP_REGISTROS_INCONSISTENTES
			   WHERE MENOR_COD_VALIDACAO = A.COD_VALIDACAO )

