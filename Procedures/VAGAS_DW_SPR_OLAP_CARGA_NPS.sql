-- =============================================
-- Author: Fiama
-- Create date: 08/10/2018
-- Description: Procedure para alimentação do DW
-- =============================================

USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_NPS' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_NPS
GO

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_NPS
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[NPS_EMPRESAS] ;
TRUNCATE TABLE [VAGAS_DW].[NPS_EMPRESAS_SALDO_BASE] ;


INSERT INTO [VAGAS_DW].[NPS_EMPRESAS] (NPS_ONDA, NPS_MES_ONDA, QTD_NPS, NPS_CLASSIFICACAO, MERCADO)
SELECT	1, '20170401', 11, 'DETRATORES (0 A 6)', 'TOTAL'
UNION ALL
SELECT	1, '20170401', 28, 'NEUTROS (7 E 8)' , 'TOTAL'
UNION ALL
SELECT	1, '20170401', 60, 'PROMOTORES (9 E 10)' , 'TOTAL'

UNION ALL
SELECT	2, '20170701', 14, 'DETRATORES (0 A 6)', 'TOTAL'
UNION ALL
SELECT	2, '20170701', 27, 'NEUTROS (7 E 8)' , 'TOTAL'
UNION ALL
SELECT	2, '20170701', 59, 'PROMOTORES (9 E 10)' , 'TOTAL'

UNION ALL
SELECT	3, '20171201', 11, 'DETRATORES (0 A 6)', 'TOTAL'
UNION ALL
SELECT	3, '20171201', 31, 'NEUTROS (7 E 8)' , 'TOTAL'
UNION ALL
SELECT	3, '20171201', 58, 'PROMOTORES (9 E 10)' , 'TOTAL'


UNION ALL
SELECT	4, '20180201', 9, 'DETRATORES (0 A 6)', 'TOTAL'
UNION ALL
SELECT	4, '20180201', 27, 'NEUTROS (7 E 8)' , 'TOTAL'
UNION ALL
SELECT	4, '20180201', 64, 'PROMOTORES (9 E 10)' , 'TOTAL'


UNION ALL
SELECT	5, '20180501', 8, 'DETRATORES (0 A 6)', 'TOTAL'
UNION ALL
SELECT	5, '20180501', 28, 'NEUTROS (7 E 8)' , 'TOTAL'
UNION ALL
SELECT	5, '20180501', 64, 'PROMOTORES (9 E 10)' , 'TOTAL'


UNION ALL
SELECT	6, '20180801', 8, 'DETRATORES (0 A 6)', 'TOTAL'
UNION ALL
SELECT	6, '20180801', 27, 'NEUTROS (7 E 8)' , 'TOTAL'
UNION ALL
SELECT	6, '20180801', 65, 'PROMOTORES (9 E 10)' , 'TOTAL'

UNION ALL
SELECT	7, 	'20181101', 10, 'DETRATORES (0 A 6)', 'TOTAL'
UNION ALL
SELECT	7,	'20181101',	34,	'NEUTROS (7 E 8)',	  'TOTAL'
UNION ALL
SELECT	7,	'20181101',	56,	'PROMOTORES (9 E 10)','TOTAL'

-- SALDO NPS e BASE:
INSERT INTO [VAGAS_DW].[NPS_EMPRESAS_SALDO_BASE] (NPS_ONDA, NPS_SALDO, NPS_BASE,NPS_MERCADO)
SELECT	1 AS NPS_ONDA, 49 AS SALDO, 256 AS BASE, 'TOTAL'
UNION ALL
SELECT	2, 44, 198, 'TOTAL'
UNION ALL
SELECT	3, 47, 281, 'TOTAL'
UNION ALL
SELECT	4, 55, 242, 'TOTAL'
UNION ALL
SELECT	5, 56, 257, 'TOTAL'
UNION ALL
SELECT	6, 57, 258, 'TOTAL'
UNION ALL
SELECT	7, 46, 243, 'TOTAL' ;

--------------
-- SIMPLIFICA:
--------------
INSERT INTO [VAGAS_DW].[NPS_EMPRESAS] (NPS_ONDA, NPS_MES_ONDA, QTD_NPS, NPS_CLASSIFICACAO, MERCADO)
SELECT	1, '20170401', 11, 'DETRATORES (0 A 6)', 'SIMPLIFICA'
UNION ALL
SELECT	1, '20170401', 29, 'NEUTROS (7 E 8)' , 'SIMPLIFICA'
UNION ALL
SELECT	1, '20170401', 60, 'PROMOTORES (9 E 10)' , 'SIMPLIFICA' 

UNION ALL
SELECT	2, '20170701', 15, 'DETRATORES (0 A 6)' , 'SIMPLIFICA'
UNION ALL
SELECT	2, '20170701', 29, 'NEUTROS (7 E 8)'  , 'SIMPLIFICA'
UNION ALL
SELECT	2, '20170701', 56, 'PROMOTORES (9 E 10)'  , 'SIMPLIFICA'

UNION ALL
SELECT	3, '20171201', 13, 'DETRATORES (0 A 6)' , 'SIMPLIFICA'
UNION ALL
SELECT	3, '20171201', 31, 'NEUTROS (7 E 8)'  , 'SIMPLIFICA'
UNION ALL
SELECT	3, '20171201', 56, 'PROMOTORES (9 E 10)'  , 'SIMPLIFICA'


UNION ALL
SELECT	4, '20180201', 9, 'DETRATORES (0 A 6)' , 'SIMPLIFICA'
UNION ALL
SELECT	4, '20180201', 27, 'NEUTROS (7 E 8)'  , 'SIMPLIFICA'
UNION ALL
SELECT	4, '20180201', 64, 'PROMOTORES (9 E 10)'  , 'SIMPLIFICA'


UNION ALL
SELECT	5, '20180501', 10, 'DETRATORES (0 A 6)' , 'SIMPLIFICA'
UNION ALL
SELECT	5, '20180501', 26, 'NEUTROS (7 E 8)'  , 'SIMPLIFICA'
UNION ALL
SELECT	5, '20180501', 64, 'PROMOTORES (9 E 10)' , 'SIMPLIFICA' 


UNION ALL
SELECT	6, '20180801', 8, 'DETRATORES (0 A 6)' , 'SIMPLIFICA'
UNION ALL
SELECT	6, '20180801', 31, 'NEUTROS (7 E 8)'  , 'SIMPLIFICA'
UNION ALL
SELECT	6, '20180801', 61, 'PROMOTORES (9 E 10)'  , 'SIMPLIFICA'


UNION ALL
SELECT	7,	'20181101',	10,	'DETRATORES (0 A 6)', 'SIMPLIFICA'
UNION ALL
SELECT	7,	'20181101',	39,	'NEUTROS (7 E 8)', 	  'SIMPLIFICA'
UNION ALL
SELECT	7,	'20181101',	51,	'PROMOTORES (9 E 10)','SIMPLIFICA'



-- SALDO NPS e BASE: SIMPLIFICA
INSERT INTO [VAGAS_DW].[NPS_EMPRESAS_SALDO_BASE] (NPS_ONDA, NPS_SALDO, NPS_BASE, NPS_MERCADO)
SELECT	1 AS NPS_ONDA, 49 AS SALDO, 156 AS BASE, 'SIMPLIFICA' AS MERCADO
UNION ALL
SELECT	2, 40, 130, 'SIMPLIFICA'
UNION ALL
SELECT	3, 43, 149, 'SIMPLIFICA'
UNION ALL
SELECT	4, 55, 151, 'SIMPLIFICA'
UNION ALL
SELECT	5, 54, 143, 'SIMPLIFICA'
UNION ALL
SELECT	6, 53, 158, 'SIMPLIFICA'
UNION ALL
SELECT	7, 41, 129, 'SIMPLIFICA' ;




----------
-- SUPERA:
----------
INSERT INTO [VAGAS_DW].[NPS_EMPRESAS] (NPS_ONDA, NPS_MES_ONDA, QTD_NPS, NPS_CLASSIFICACAO, MERCADO)
SELECT	1, '20170401', 12, 'DETRATORES (0 A 6)', 'SUPERA'
UNION ALL
SELECT	1, '20170401', 27, 'NEUTROS (7 E 8)' , 'SUPERA'
UNION ALL
SELECT	1, '20170401', 61, 'PROMOTORES (9 E 10)' , 'SUPERA' 

UNION ALL
SELECT	2, '20170701', 13, 'DETRATORES (0 A 6)' , 'SUPERA'
UNION ALL
SELECT	2, '20170701', 22, 'NEUTROS (7 E 8)'  , 'SUPERA'
UNION ALL
SELECT	2, '20170701', 65, 'PROMOTORES (9 E 10)'  , 'SUPERA'

UNION ALL
SELECT	3, '20171201', 10, 'DETRATORES (0 A 6)' , 'SUPERA'
UNION ALL
SELECT	3, '20171201', 29, 'NEUTROS (7 E 8)'  , 'SUPERA'
UNION ALL
SELECT	3, '20171201', 61, 'PROMOTORES (9 E 10)'  , 'SUPERA'


UNION ALL
SELECT	4, '20180201', 9, 'DETRATORES (0 A 6)' , 'SUPERA'
UNION ALL
SELECT	4, '20180201', 27, 'NEUTROS (7 E 8)'  , 'SUPERA'
UNION ALL
SELECT	4, '20180201', 64, 'PROMOTORES (9 E 10)'  , 'SUPERA'


UNION ALL
SELECT	5, '20180501', 5, 'DETRATORES (0 A 6)' , 'SUPERA'
UNION ALL
SELECT	5, '20180501', 32, 'NEUTROS (7 E 8)'  , 'SUPERA'
UNION ALL
SELECT	5, '20180501', 63, 'PROMOTORES (9 E 10)' , 'SUPERA' 


UNION ALL
SELECT	6, '20180801', 9, 'DETRATORES (0 A 6)' , 'SUPERA'
UNION ALL
SELECT	6, '20180801', 21, 'NEUTROS (7 E 8)'  , 'SUPERA'
UNION ALL
SELECT	6, '20180801', 70, 'PROMOTORES (9 E 10)'  , 'SUPERA'


UNION ALL
SELECT	7,	'20181101',	11,	'DETRATORES (0 A 6)', 'SUPERA'
UNION ALL
SELECT	7,	'20181101',	28,	'NEUTROS (7 E 8)',	  'SUPERA'
UNION ALL
SELECT	7,	'20181101',	61,	'PROMOTORES (9 E 10)','SUPERA'


-- SALDO NPS e BASE: SUPERA
INSERT INTO [VAGAS_DW].[NPS_EMPRESAS_SALDO_BASE] (NPS_ONDA, NPS_SALDO, NPS_BASE, NPS_MERCADO)
SELECT	1 AS NPS_ONDA, 49 AS SALDO, 100 AS BASE, 'SUPERA' AS MERCADO
UNION ALL
SELECT	2, 52, 68, 'SUPERA'
UNION ALL
SELECT	3, 51, 132, 'SUPERA'
UNION ALL
SELECT	4, 55, 91, 'SUPERA'
UNION ALL
SELECT	5, 58, 114, 'SUPERA'
UNION ALL
SELECT	6, 61, 100, 'SUPERA'
UNION ALL
SELECT	7, 50, 114, 'SUPERA' ;


-- CHAVE RELACIONAMENTO:
UPDATE	[VAGAS_DW].[NPS_EMPRESAS_SALDO_BASE]
SET		CHAVE_RELACIONAMENTO = CONCAT(NPS_ONDA, ' ', NPS_MERCADO) 
FROM	[VAGAS_DW].[NPS_EMPRESAS_SALDO_BASE] ;

UPDATE	[VAGAS_DW].[NPS_EMPRESAS]
SET		CHAVE_RELACIONAMENTO = CONCAT(NPS_ONDA, ' ', MERCADO)
FROM	[VAGAS_DW].[NPS_EMPRESAS] ;