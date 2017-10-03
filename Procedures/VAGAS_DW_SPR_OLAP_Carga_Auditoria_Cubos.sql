-- EXEC VAGAS_DW.SPR_OLAP_Carga_Auditoria_Cubos
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Auditoria_Cubos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Auditoria_Cubos
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 31/05/2016
-- Description: Procedure para alimenta��o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Auditoria_Cubos 
@DATA_INICIO SMALLDATETIME = NULL,
@DATA_FIM SMALLDATETIME = NULL

AS
SET NOCOUNT ON

IF @DATA_INICIO IS NULL
SET @DATA_INICIO = '19010101'

IF @DATA_FIM IS NULL
SET @DATA_FIM = '20790101'

TRUNCATE TABLE VAGAS_DW.TMP_AUDITORIA_CUBOS

INSERT INTO VAGAS_DW.TMP_AUDITORIA_CUBOS
SELECT RowNumber AS ID_AUDITORIA,
	   ISNULL(B.NOME_CUBO,'N�o Classificado') AS CUBO,
	   REPLACE(REPLACE(LEFT(CONVERT(VARCHAR(MAX),TextData),200),CHAR(10),''),CHAR(13),'') AS COMANDO,
	   CONNECTIONID,
	   SPID,
	   StartTime AS DATA_INICIO,
	   Duration AS DURACAO_MS,
	   NTUserName AS USUARIO 
FROM LOG_SSAS_TABULAR A
OUTER APPLY ( SELECT TOP 1 * 
			  FROM VAGAS_DW.CUBOS
			  WHERE CHARINDEX('[' + NOME_SEGMENTACAO + ' -',TextData) > 0
			  OR CHARINDEX('[$' + NOME_SEGMENTACAO + ' -',TextData) > 0
			  OR CHARINDEX('[' + NOME_CUBO + ']',TextData) > 0
			  OR CHARINDEX('[$' + NOME_CUBO + ']',TextData) > 0
			   ) B
WHERE A.EventClass = 10 
AND CONVERT(VARCHAR(50),TextData) <> 'REFRESH CUBE [VAGAS_DW]'
AND A.StartTime >= @DATA_INICIO
AND A.StartTime < @DATA_FIM

-- LIMPAR TABELA FATO
-- Limpar dados da tabela fato
DECLARE @DT_INICIO SMALLDATETIME,
		@DT_FIM SMALLDATETIME

SELECT @DT_INICIO = MIN(DATA_INICIO),
	   @DT_FIM = MAX(DATA_INICIO)
FROM VAGAS_DW.TMP_AUDITORIA_CUBOS

DELETE VAGAS_DW.AUDITORIA_CUBOS
FROM VAGAS_DW.AUDITORIA_CUBOS A
WHERE DATA_INICIO >= @DT_INICIO
AND DATA_INICIO < DATEADD(DAY,1,@DT_FIM)

INSERT INTO VAGAS_DW.AUDITORIA_CUBOS
SELECT * FROM VAGAS_DW.TMP_AUDITORIA_CUBOS