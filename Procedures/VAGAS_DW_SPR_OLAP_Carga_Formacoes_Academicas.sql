USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Formacoes_Academicas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Formacoes_Academicas
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================

-- =============================================
-- Alterações
-- 05/02/2020 - Diego Gatto - Ajustado para utilizar as tabelas TMP na base de dados stage e não vagas_dw
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Formacoes_Academicas 

AS
SET NOCOUNT ON

DELETE VAGAS_DW.Formacoes_Academicas  
FROM VAGAS_DW.Formacoes_Academicas A
WHERE EXISTS ( SELECT * FROM [STAGE].[VAGAS_DW].[TMP_FORMACOES_ACADEMICAS] 
					WHERE CANDIDATO_ID = A.COD_CAND ) 

-- CARREGAR CUBO
INSERT INTO VAGAS_DW.Formacoes_Academicas 
SELECT * FROM [STAGE].[VAGAS_DW].[TMP_FORMACOES_ACADEMICAS]
