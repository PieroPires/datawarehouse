-- EXEC VAGAS_DW.SPR_OLAP_Carga_Log_IIS_Relatorios
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Log_IIS_Relatorios' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Log_IIS_Relatorios
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 21/01/2016
-- Description: Procedure para alimenta��o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Log_IIS_Relatorios

AS
SET NOCOUNT ON


-- LIMPAR ARQUIVOS J� IMPORTADOS
DELETE VAGAS_DW.AUDITORIA_RELATORIOS
FROM VAGAS_DW.AUDITORIA_RELATORIOS A
WHERE EXISTS ( SELECT 1 FROM STAGE.VAGAS_DW.TMP_AUDITORIA_RELATORIOS
				WHERE NOME_ARQUIVO = A.NOME_ARQUIVO )

-- GRAVAR DADOS NA TABELA FATO
INSERT INTO VAGAS_DW.AUDITORIA_RELATORIOS
SELECT * FROM STAGE.VAGAS_DW.TMP_AUDITORIA_RELATORIOS
