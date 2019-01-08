-- =============================================
-- Author: Fiama
-- Create date: 08/10/2018
-- Description: Procedure para alimentação do DW
-- =============================================

USE VAGAS_DW ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_NPS_Candidatos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_NPS_Candidatos
GO

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_NPS_Candidatos
AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[NPS_CANDIDATOS]  ;

INSERT INTO [VAGAS_DW].[NPS_CANDIDATOS] (NPS_ONDA, NPS_MES_ONDA, NPS_PORCENTAGEM, NPS_CLASSIFICACAO, FERRAMENTA, SALDO_NPS, BASE_NPS)
SELECT	1 , '20170401', 0.19, 'DETRATORES', 'SITE', 0.45, 1195
UNION ALL
SELECT	1, '20170401', 0.17, 'NEUTROS', 'SITE', 0.45, 1195
UNION ALL
SELECT	1, '20170401', 0.64, 'PROMOTORES', 'SITE', 0.45, 1195
UNION ALL

SELECT	2, '20170601', 0.16, 'DETRATORES', 'SITE', 0.46, 1166
UNION ALL
SELECT	2, '20170601', 0.21, 'NEUTROS', 'SITE', 0.46, 1166
UNION ALL
SELECT	2, '20170601', 0.63, 'PROMOTORES', 'SITE', 0.46, 1166
UNION ALL

SELECT	3, '20170701', 0.152583799, 'DETRATORES', 'SITE', 0.5, 2864
UNION ALL
SELECT	3, '20170701', 0.21, 'NEUTROS', 'SITE', 0.5, 2864
UNION ALL
SELECT	3, '20170701', 0.644902235, 'PROMOTORES', 'SITE', 0.5, 2864
UNION ALL

SELECT	4, '20171201', 0.21, 'DETRATORES', 'SITE', 0.38, 5290
UNION ALL
SELECT	4, '20171201', 0.2, 'NEUTROS', 'SITE', 0.38, 5290
UNION ALL
SELECT	4, '20171201', 0.59, 'PROMOTORES', 'SITE', 0.38, 5290
UNION ALL

SELECT	5, '20180201', 0.19, 'DETRATORES', 'SITE', 0.4, 2611
UNION ALL
SELECT	5, '20180201', 0.22, 'NEUTROS', 'SITE', 0.4, 2611
UNION ALL
SELECT	5, '20180201', 0.59, 'PROMOTORES', 'SITE', 0.4, 2611
UNION ALL

SELECT	6, '20180501', 0.19582505, 'DETRATORES', 'SITE', 0.364811133, 2012
UNION ALL
SELECT	6, '20180501', 0.243538767, 'NEUTROS', 'SITE', 0.364811133, 2012
UNION ALL
SELECT	6, '20180501', 0.560636183, 'PROMOTORES', 'SITE', 0.364811133, 2012
UNION ALL


SELECT	7, '20180801', 0.175050302, 'DETRATORES', 'SITE', 0.41, 2485
UNION ALL
SELECT	7, '20180801', 0.232997988, 'NEUTROS', 'SITE', 0.41, 2485
UNION ALL
SELECT	7, '20180801', 0.59195171, 'PROMOTORES', 'SITE', 0.41, 2485
UNION ALL

SELECT	8, '20181101', 0.173322005, 'DETRATORES', 'SITE', 0.429906542, 2354 
UNION ALL
SELECT	8, '20181101', 0.230000000,'NEUTROS', 'SITE', 0.429906542, 2354 
UNION ALL
SELECT	8, '20181101', 0.603228547, 'PROMOTORES', 'SITE', 0.429906542, 2354 





INSERT INTO [VAGAS_DW].[NPS_CANDIDATOS] (NPS_ONDA, NPS_MES_ONDA, NPS_PORCENTAGEM, NPS_CLASSIFICACAO, FERRAMENTA, SALDO_NPS, BASE_NPS)
SELECT	1, '20180401', 0.174110258, 'DETRATORES', 'MOBILE', 0.48, 2866
UNION ALL
SELECT	1, '20180401', 0.18, 'NEUTROS', 'MOBILE', 0.48, 2866
UNION ALL
SELECT	1, '20180401', 0.653175157, 'PROMOTORES', 'MOBILE', 0.48, 2866
UNION ALL


SELECT	2, '20180601', 0.160179641, 'DETRATORES', 'MOBILE', 0.51, 2672
UNION ALL
SELECT	2, '20180601', 0.171032934, 'NEUTROS', 'MOBILE', 0.51, 2672
UNION ALL
SELECT	2, '20180601', 0.668787425, 'PROMOTORES', 'MOBILE', 0.51, 2672
UNION ALL

SELECT	3, '20180801', 0.16, 'DETRATORES', 'MOBILE', 0.5, 2543
UNION ALL
SELECT	3, '20180801', 0.18, 'NEUTROS', 'MOBILE', 0.5, 2543
UNION ALL
SELECT	3, '20180801', 0.66, 'PROMOTORES', 'MOBILE', 0.5, 2543
UNION ALL

SELECT	4, '20181101', 0.33236152,  'DETRATORES', 'MOBILE', 0.13281503, 2622
UNION ALL
SELECT	4, '20181101', 0.20246194,  'NEUTROS', 'MOBILE', 0.13281503, 2622
UNION ALL
SELECT	4, '20181101', 0.46517655,  'PROMOTORES', 'MOBILE', 0.13281503, 2622