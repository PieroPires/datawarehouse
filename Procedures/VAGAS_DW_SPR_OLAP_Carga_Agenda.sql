USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Agenda' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Agenda
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 05/08/2016
-- Description: Procedure para carga das tabelas tempor?rias (BD Stage) para alimenta??o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Agenda 
@NOME_AGENDA VARCHAR(150)

AS
SET NOCOUNT ON

-- Limpar dados da tabela fato
DELETE VAGAS_DW.AGENDA
FROM VAGAS_DW.AGENDA A 
WHERE EXISTS ( SELECT 1 FROM STAGE.VAGAS_DW.TMP_AGENDA
				WHERE ID_AGENDA = A.ID_AGENDA
				AND NOME_AGENDA = @NOME_AGENDA)

-- ATUALIZAR HORAS GASTAS E O TIPO DA REUNI?O
UPDATE STAGE.VAGAS_DW.TMP_AGENDA SET QTD_HORAS = DATEDIFF(HOUR,DATA_INICIO,DATA_FIM),
							   TIPO_REUNIAO = CASE WHEN RESUMO LIKE '%Ciclo%' THEN 'Defini??o Marcos Estrat?gicos'
												   WHEN RESUMO LIKE '%Acordo%' THEN 'Acordo da VAGAS com a Equipe'
												   WHEN RESUMO LIKE '%Prepara??o%' THEN 'Prepara??o do Grupo VAGAS'
												   WHEN RESUMO LIKE '%Negocia??o%' THEN 'Negocia??o de Acordo + Marcos da VAGAS com a Equipe'
											  ELSE 'Outros' END
FROM STAGE.VAGAS_DW.TMP_AGENDA
WHERE NOME_AGENDA = @NOME_AGENDA

-- ATUALIZAR NOME_EQUIPE_PARTICIPANTE E SALA_REUNIAO
UPDATE STAGE.VAGAS_DW.TMP_AGENDA SET NOME_EQUIPE_PARTICIPANTE = B1.NOME,
							   SALA_REUNIAO = C.NOME_PARTICIPANTE
FROM STAGE.VAGAS_DW.TMP_AGENDA A
INNER JOIN STAGE.VAGAS_DW.TMP_AGENDA_PARTICIPANTES B ON B.ID_AGENDA = A.ID_AGENDA
INNER JOIN VAGAS_DW.EQUIPES B1 ON REPLACE(B1.EMAIL,'.br','') = REPLACE(B.EMAIL,'.br','')
OUTER APPLY ( SELECT TOP 1 * 
			  FROM STAGE.VAGAS_DW.TMP_AGENDA_PARTICIPANTES
			  WHERE ID_AGENDA = A.ID_AGENDA
			  AND FLAG_RECURSO = 1 ) C


-- EQUIPES DE PREPARA??O
UPDATE STAGE.VAGAS_DW.TMP_AGENDA SET NOME_EQUIPE_PARTICIPANTE = B.NOME
FROM STAGE.VAGAS_DW.TMP_AGENDA A
INNER JOIN VAGAS_DW.EQUIPES B ON B.CHAVE_EQUIPE = SUBSTRING(SUBSTRING(RESUMO,CHARINDEX('#',RESUMO),LEN(RESUMO)),1,CASE WHEN CHARINDEX(' ',SUBSTRING(RESUMO,CHARINDEX('#',RESUMO),LEN(RESUMO))) > 0
																			THEN CHARINDEX(' ',SUBSTRING(RESUMO,CHARINDEX('#',RESUMO),LEN(RESUMO)))
																			ELSE LEN(SUBSTRING(RESUMO,CHARINDEX('#',RESUMO),LEN(RESUMO))) END ) -- Tratamento do campo RESUMO para extra??o do #equipe..
WHERE TIPO_REUNIAO = 'Prepara??o do Grupo VAGAS' 

-- ATUALIZAR CICLO
UPDATE STAGE.VAGAS_DW.TMP_AGENDA SET CICLO_ACORDO = CASE WHEN RIGHT(SUBSTRING(RESUMO,CHARINDEX('Ciclo',RESUMO),7),1) = 'I' THEN
											CASE WHEN CHARINDEX('II',RESUMO) > 0 THEN 'Ciclo 2'
												 ELSE 'Ciclo 1' END
									   ELSE SUBSTRING(RESUMO,CHARINDEX('Ciclo',RESUMO),7) END
FROM STAGE.VAGAS_DW.TMP_AGENDA 
WHERE TIPO_REUNIAO = 'Defini??o Marcos Estrat?gicos' 
AND RESUMO LIKE '%Ciclo%'

INSERT INTO VAGAS_DW.AGENDA 
SELECT * FROM STAGE.VAGAS_DW.TMP_AGENDA 
WHERE NOME_AGENDA = @NOME_AGENDA

-- LIMPAR DADOS J? CARREGADOS
DELETE FROM STAGE.VAGAS_DW.TMP_AGENDA WHERE NOME_AGENDA = @NOME_AGENDA