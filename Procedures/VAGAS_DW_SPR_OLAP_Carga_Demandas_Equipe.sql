USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Demandas_Equipes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Demandas_Equipes
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 19/05/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Demandas_Equipes 
AS
SET NOCOUNT ON

-- Atualizar informação de ciclo (baseado no registro de #CICLO adicionado nas tarefas atreladas à Marcos da mesma semana)
UPDATE VAGAS_DW.TMP_DEMANDAS_EQUIPES SET CICLO = UPPER(B.CICLO)
FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES A
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES
			  WHERE NOME_RELEASE = A.NOME_RELEASE
			  AND CICLO <> '' 
			  ORDER BY DATA_CADASTRAMENTO ASC ) B			  
WHERE A.CICLO = ''
AND A.NOME_RELEASE <> 'Sem Release'

UPDATE VAGAS_DW.TMP_DEMANDAS_EQUIPES SET CICLO = NULL
WHERE NOME_RELEASE = ''

DELETE VAGAS_DW.DEMANDAS_EQUIPES
FROM VAGAS_DW.DEMANDAS_EQUIPES A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES
				WHERE ID_DEMANDA = A.ID_DEMANDA)

-- Inserir novos contratos 
INSERT INTO VAGAS_DW.DEMANDAS_EQUIPES
SELECT *
FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES

-- Ajuste relativo à bug do Jira (falar com Matias)
-- Em 20160711 nós alteramos o processo pois o Mati finalizou o ajuste nas demandas "canceladas"
--UPDATE VAGAS_DW.DEMANDAS_EQUIPES SET STATUS_DEMANDA = 'Done'
--FROM VAGAS_DW.DEMANDAS_EQUIPES 
--WHERE STATUS_DEMANDA = 'Cancelada'

-- Ajuste relativo à normatização das equipes
UPDATE VAGAS_DW.DEMANDAS_EQUIPES SET EQUIPE_SOLICITANTE = B.CATEGORIA_NOVO + ' ' + B.NOME_NOVO
FROM VAGAS_DW.DEMANDAS_EQUIPES A
INNER JOIN VAGAS_DW.TMP_DE_PARA_EQUIPES B ON B.CATEGORIA_ANTERIOR + ' ' + B.NOME_ANTERIOR = A.EQUIPE_SOLICITANTE
