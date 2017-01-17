USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Demandas_Equipes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Demandas_Equipes
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 19/05/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Demandas_Equipes 
AS
SET NOCOUNT ON

-- Atualizar informa��o de ciclo (baseado no registro de #CICLO adicionado nas tarefas atreladas � Marcos da mesma semana)
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

-- ATUALIZAR SCORE
UPDATE VAGAS_DW.TMP_DEMANDAS_EQUIPES SET SCORE =		
		-- GRAVIDADE
		CASE WHEN GRAVIDADE = 'sem gravidade' THEN 1
			WHEN GRAVIDADE = 'pouco grave' THEN 2
			WHEN GRAVIDADE = 'grave' THEN 3
			WHEN GRAVIDADE = 'muito grave' THEN 4
			WHEN GRAVIDADE = 'extremamente grave' THEN 5
		END *
		
		-- URGENCIA
		CASE WHEN URGENCIA = 'pode esperar' THEN 1
			WHEN URGENCIA = 'pouco urgente' THEN 2
			WHEN URGENCIA = 'urgente (merece aten��o no curto prazo)' THEN 3
			WHEN URGENCIA = 'muito urgente' THEN 4
			WHEN URGENCIA = 'necessidade de a��o imediata' THEN 5
		END *
		
		-- ESFOR�O
		CASE WHEN ESFORCO = 'esfor�o m�nimo' THEN 5
			WHEN ESFORCO = 'esfor�o moderado' THEN 4
			WHEN ESFORCO = 'esfor�o significativo' THEN 3
			WHEN ESFORCO = 'muito esfor�o' THEN 2
			WHEN ESFORCO = 'muit�ssimo esfor�o' THEN 1
		END
FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES
WHERE GRAVIDADE IS NOT NULL AND URGENCIA IS NOT NULL AND ESFORCO IS NOT NULL

-- ATUALIZA��O DO ASSIGNED PARA SIST. CORPORATIVOS
UPDATE VAGAS_DW.TMP_DEMANDAS_EQUIPES SET DATA_PRM_ASSIGNED = DATA_CONCLUSAO
FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES 
WHERE ( STATUS_DEMANDA IN ('Conclu�da','Done') OR STATUS_RESOLUCAO = 'Fixed' )
AND EQUIPE_PROJETO = 'Sistemas Corporativos'
AND DATA_PRM_ASSIGNED IS NULL

DELETE VAGAS_DW.DEMANDAS_EQUIPES
FROM VAGAS_DW.DEMANDAS_EQUIPES A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES
				WHERE ID_DEMANDA = A.ID_DEMANDA
				AND EQUIPE_PROJETO = A.EQUIPE_PROJETO)

-- Inserir novas demandas
INSERT INTO VAGAS_DW.DEMANDAS_EQUIPES (ID_DEMANDA,NUMERO_DEMANDA,NOME_DEMANDA,NOME_PROJETO,RESPONSAVEL,CRIADOR,TIPO_DEMANDA,PRIORIDADE,STATUS_DEMANDA,DATA_CADASTRAMENTO,
DATA_ALTERACAO,DATA_EXPECTATIVA_CONCLUSAO,DATA_CONCLUSAO,STATUS_RESOLUCAO,TEMPO_ESTIMATIVA,TEMPO_GASTO,FLAG_ATRELADO_MARCO,NOME_DEMANDA_ROOT,
NOME_RELEASE,EQUIPE_SOLICITANTE,TIPO_SUB_TAREFA,FLAG_ROOT,CICLO,GRAVIDADE,URGENCIA,ESFORCO,SCORE,TIPO_CLIENTE,FATURAVEL,EQUIPE_PROJETO,DATA_PRM_ASSIGNED,
FERRAMENTA,SINTOMA,INDICE_SATISFACAO,LABEL,SPRINT)
SELECT ID_DEMANDA,NUMERO_DEMANDA,NOME_DEMANDA,NOME_PROJETO,RESPONSAVEL,CRIADOR,TIPO_DEMANDA,PRIORIDADE,STATUS_DEMANDA,DATA_CADASTRAMENTO,
DATA_ALTERACAO,DATA_EXPECTATIVA_CONCLUSAO,DATA_CONCLUSAO,STATUS_RESOLUCAO,TEMPO_ESTIMATIVA,TEMPO_GASTO,FLAG_ATRELADO_MARCO,NOME_DEMANDA_ROOT,
NOME_RELEASE,EQUIPE_SOLICITANTE,TIPO_SUB_TAREFA,FLAG_ROOT,CICLO,GRAVIDADE,URGENCIA,ESFORCO,SCORE,TIPO_CLIENTE,FATURAVEL,EQUIPE_PROJETO,DATA_PRM_ASSIGNED,
FERRAMENTA,SINTOMA,INDICE_SATISFACAO,LABEL,SPRINT
FROM VAGAS_DW.TMP_DEMANDAS_EQUIPES

-- Ajuste relativo � bug do Jira (falar com Matias)
-- Em 20160711 n�s alteramos o processo pois o Mati finalizou o ajuste nas demandas "canceladas"
--UPDATE VAGAS_DW.DEMANDAS_EQUIPES SET STATUS_DEMANDA = 'Done'
--FROM VAGAS_DW.DEMANDAS_EQUIPES 
--WHERE STATUS_DEMANDA = 'Cancelada'

-- Ajuste relativo � normatiza��o das equipes
UPDATE VAGAS_DW.DEMANDAS_EQUIPES SET EQUIPE_SOLICITANTE = B.CATEGORIA_NOVO + ' ' + B.NOME_NOVO
FROM VAGAS_DW.DEMANDAS_EQUIPES A
INNER JOIN VAGAS_DW.TMP_DE_PARA_EQUIPES B ON B.CATEGORIA_ANTERIOR + ' ' + B.NOME_ANTERIOR = A.EQUIPE_SOLICITANTE

-- Calcular m�dia de entregas da equipe Intelig�ncia de Neg�cios
EXEC VAGAS_DW.SPR_OLAP_Calculo_Media_Demandas_Inteligencia_Negocios

