-- EXEC VAGAS_DW.SPR_OLAP_Carga_Extracoes_BCC
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Extracoes_BCC' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Extracoes_BCC
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Extracoes_BCC

AS
SET NOCOUNT ON

-- Limpar registros que já existem na FATO
DELETE VAGAS_DW.EXTRACOES_BCC
FROM VAGAS_DW.EXTRACOES_BCC A
WHERE EXISTS ( SELECT 1 FROM STAGE.VAGAS_DW.TMP_EXTRACOES_BCC
				WHERE COD_PEDIDO = A.COD_PEDIDO)

INSERT INTO VAGAS_DW.EXTRACOES_BCC
SELECT * FROM STAGE.VAGAS_DW.TMP_EXTRACOES_BCC