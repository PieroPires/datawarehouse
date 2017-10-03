IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'VW_TAIL_COMPORTAMENTO' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP VIEW VAGAS_DW.VW_TAIL_COMPORTAMENTO
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 04/08/2017
-- Description: VIEW para utilização no cubo de TAIL_COMPORTAMENTO
-- =============================================

CREATE VIEW VAGAS_DW.VW_TAIL_COMPORTAMENTO

AS

SELECT TIPO,
	   DESCRICAO,
	   DATA_REFERENCIA,
	   COUNT(*) AS QTD
FROM VAGAS_DW.TAIL_COMPORTAMENTO
GROUP BY TIPO,
	   DESCRICAO,
	   DATA_REFERENCIA