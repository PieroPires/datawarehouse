USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Controle_Versao_Commits' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Controle_Versao_Commits
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 17/11/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Controle_Versao_Commits

AS
SET NOCOUNT ON

-- LIMPAR TABELA FATO
DELETE VAGAS_DW.CONTROLE_VERSAO_COMMITS
FROM VAGAS_DW.CONTROLE_VERSAO_COMMITS A
WHERE EXISTS ( SELECT * FROM VAGAS_DW.TMP_CONTROLE_VERSAO_COMMITS
				WHERE ID_PULL_REQUEST = A.ID_PULL_REQUEST
				AND REPOSITORIO = A.REPOSITORIO )

-- INSERÇÃO DE NOVOS DADOS
INSERT INTO VAGAS_DW.CONTROLE_VERSAO_COMMITS
SELECT * FROM VAGAS_DW.TMP_CONTROLE_VERSAO_COMMITS


