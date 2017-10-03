USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Evolucao_Marcos_Equipes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Evolucao_Marcos_Equipes
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 05/07/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Evolucao_Marcos_Equipes

AS
SET NOCOUNT ON

-- SEMPRE CARGA FULL
TRUNCATE TABLE VAGAS_DW.EVOLUCAO_MARCOS_EQUIPES

-- Apagar marco 1 (ajustes para garantir a sa�de...) para n�o contabilizar na m�dia
DELETE VAGAS_DW.TMP_INDICADOR_MARCOS_INTRANET 
FROM VAGAS_DW.TMP_INDICADOR_MARCOS_INTRANET 
WHERE MARCO LIKE '%Ajustes para garantir a sa�de das Responsabilidades definidas no Acordo com a VAGAS%'
OR MARCO LIKE '%Garantir a sa�de das Responsabilidades definidas no Acordo com a VAGAS%'

-- Apagar inconsist�ncias de ciclos intranet
DELETE FROM VAGAS_DW.TMP_INDICADOR_MARCOS_INTRANET WHERE CICLO IS NULL

INSERT INTO VAGAS_DW.EVOLUCAO_MARCOS_EQUIPES (NOME_EQUIPE,NUMERO_MARCO,MARCO,PERC_ATINGIMENTO,CICLO,NID_MARCO,NID_CICLO,
											  CICLO_INICIO,CICLO_FIM,STATUS_MARCO)
SELECT DISTINCT 
		NOME_EQUIPE,
		NUMERO_MARCO,
		CONVERT(VARCHAR(200),MARCO),
		CONVERT(NUMERIC(4,1),PERC_ATINGIMENTO) / 100 AS PERC_ATINGIMENTO,
		CICLO,
		NID_MARCO,
		NID_CICLO,
		CICLO_INICIO,
		CICLO_FIM,
		CASE WHEN STATUS = 0 THEN 'PROPOSTA' 
			 WHEN STATUS = 1 THEN 'NEGOCIADO'
			 ELSE 'CANCELADO' END AS STATUS_MARCO			   
FROM VAGAS_DW.TMP_INDICADOR_MARCOS_INTRANET 

-- atualizar flag ultimo ciclo
UPDATE VAGAS_DW.EVOLUCAO_MARCOS_EQUIPES SET FLAG_CICLO_ENCERRADO = 0
FROM VAGAS_DW.EVOLUCAO_MARCOS_EQUIPES  
WHERE CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)) BETWEEN CICLO_INICIO AND CICLO_FIM

UPDATE VAGAS_DW.EVOLUCAO_MARCOS_EQUIPES SET FLAG_CICLO_ENCERRADO = 1 
WHERE FLAG_CICLO_ENCERRADO IS NULL 
AND CICLO_INICIO < CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112))

-- incluir impacto neg�cio
TRUNCATE TABLE VAGAS_DW.MARCOS_IMPACTO_NEGOCIO

INSERT INTO VAGAS_DW.MARCOS_IMPACTO_NEGOCIO(NID_MARCO,NUMERO_CONTEXTO,CONTEXTO,TIPO_IMPACTO)
SELECT DISTINCT 
		NID_MARCO,
		CONTEXTO_IMPACTO_NEGOCIO AS NUMERO_CONTEXTO,
		CASE WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '0' THEN 'EMPRESAS - Proposta de valor'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '1' THEN 'VAGAS - Imagem'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '2' THEN 'VAGAS - Receita'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '3' THEN 'VAGAS - Sustentabilidade'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '4' THEN 'VAGAS - Custos'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '5' THEN 'VAGAS - Investimentos'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '6' THEN 'VAGAS - Efici�ncia'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '7' THEN 'VAGAS - Conhecimento'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '8' THEN 'VAGAS - Ambiente de Trabalho'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '9' THEN 'PESSOAS - Proposta de valor'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '10'THEN 'EQUIPE - Efici�ncia'
			 WHEN CONTEXTO_IMPACTO_NEGOCIO 	= '11'THEN 'EQUIPE - Conhecimento'
		ELSE NULL END AS CONTEXTO,
		CASE WHEN IMPACTO_NEGOCIO = '9' THEN '0 - Muito Baixo'
			 WHEN IMPACTO_NEGOCIO = '10' THEN '1 - Baixo'
			 WHEN IMPACTO_NEGOCIO = '11' THEN '2 - M�dio'
			 WHEN IMPACTO_NEGOCIO = '12' THEN '3 - Alto'
			 WHEN IMPACTO_NEGOCIO = '13' THEN '4 - Muito Alto'
		ELSE NULL END TIPO_IMPACTO
FROM VAGAS_DW.TMP_INDICADOR_MARCOS_INTRANET 
WHERE CONTEXTO_IMPACTO_NEGOCIO IS NOT NULL

-- incluir impacto PE
TRUNCATE TABLE VAGAS_DW.MARCOS_IMPACTO_PE 

INSERT INTO VAGAS_DW.MARCOS_IMPACTO_PE (NID_MARCO,NUMERO_DIRECIONADOR,DIRECIONADOR,TIPO_IMPACTO)
SELECT DISTINCT 
		NID_MARCO,
		'D' + CONVERT(VARCHAR,NUMERO_DIRECIONADOR),
		'D' + CONVERT(VARCHAR,NUMERO_DIRECIONADOR) + ' - ' + DIRECIONADOR,
		CASE WHEN IMPACTO_PE = '9' THEN '0 - Muito Baixo'
			 WHEN IMPACTO_PE = '10' THEN '1 - Baixo'
			 WHEN IMPACTO_PE = '11' THEN '2 - M�dio'
			 WHEN IMPACTO_PE = '12' THEN '3 - Alto'
			 WHEN IMPACTO_PE = '13' THEN '4 - Muito Alto'
		ELSE NULL END TIPO_IMPACTO 
FROM VAGAS_DW.TMP_INDICADOR_MARCOS_INTRANET 
WHERE NUMERO_DIRECIONADOR IS NOT NULL

-- criar as categorias
UPDATE VAGAS_DW.MARCOS_IMPACTO_NEGOCIO SET CATEGORIA = CASE WHEN CONTEXTO IN ('EMPRESAS - Proposta de valor',
																			  'VAGAS - Imagem','VAGAS - Receita','VAGAS - Sustentabilidade')
															THEN 'GRUPO I'
															WHEN CONTEXTO IN ('PESSOAS - Proposta de valor',
																			  'VAGAS - Custos','VAGAS - Investimentos','VAGAS - Efici�ncia')
															THEN 'GRUPO II'
															WHEN CONTEXTO IN ('VAGAS - Conhecimento',
																			  'VAGAS - Ambiente de Trabalho','EQUIPE - Efici�ncia','EQUIPE - Conhecimento')
															THEN 'GRUPO III'
														END
															 
FROM VAGAS_DW.MARCOS_IMPACTO_NEGOCIO 

-- criar o calculo do "grau de impacto no neg�cio" conforme escala dada pelo Grupo VAGAS
UPDATE VAGAS_DW.MARCOS_IMPACTO_NEGOCIO SET GRAU_IMPACTO_NEGOCIO = CASE WHEN TIPO_IMPACTO = '0 - Muito Baixo' THEN -2
																	   WHEN TIPO_IMPACTO = '1 - Baixo' THEN -1
																	   WHEN TIPO_IMPACTO = '2 - M�dio' THEN 0
																	   WHEN TIPO_IMPACTO = '3 - Alto' THEN 1
																	   WHEN TIPO_IMPACTO = '4 - Muito Alto' THEN 2
																  END +
																  CASE WHEN CATEGORIA = 'GRUPO I' THEN 8
																	   WHEN CATEGORIA = 'GRUPO II' THEN 5
																	   WHEN CATEGORIA = 'GRUPO III' THEN 3
																   END																				
FROM VAGAS_DW.MARCOS_IMPACTO_NEGOCIO 

-- atualizar m�dia do impacto no neg�cio
UPDATE VAGAS_DW.EVOLUCAO_MARCOS_EQUIPES SET MEDIA_IMPACTO_NEGOCIO = B.MEDIA_IMPACTO_NEGOCIO,
											IMPACTO_NEGOCIO = CASE WHEN B.MEDIA_IMPACTO_NEGOCIO >= 8 THEN 'ALTO'
																   WHEN B.MEDIA_IMPACTO_NEGOCIO <= 3 THEN 'BAIXO'
																   ELSE 'M�DIO' END
FROM VAGAS_DW.EVOLUCAO_MARCOS_EQUIPES A
OUTER APPLY ( SELECT AVG(GRAU_IMPACTO_NEGOCIO) AS MEDIA_IMPACTO_NEGOCIO
			  FROM VAGAS_DW.MARCOS_IMPACTO_NEGOCIO 
			  WHERE NID_MARCO = A.NID_MARCO ) B 