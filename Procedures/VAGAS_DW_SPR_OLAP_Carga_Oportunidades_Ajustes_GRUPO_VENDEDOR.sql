-- =============================================
-- Author: Fiama
-- Create date: 12/04/2019
-- Description: Ajustes pontuais na carga do GRUPO_VENDEDOR.
-- =============================================

USE [VAGAS_DW] ;
GO


IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Oportunidades_Ajustes_GRUPO_VENDEDOR' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Oportunidades_Ajustes_GRUPO_VENDEDOR]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_Carga_Oportunidades_Ajustes_GRUPO_VENDEDOR]
AS
SET NOCOUNT ON

-- Atualização dos grupos retroativos:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		GRUPO_VENDEDOR = 
	CASE
			WHEN A.PROPRIETARIO IN ('raquel.oliveira', 'milena.santana')
				 AND A.FASE IN ('fechado_e_ganho','fechado_e_perdido')
				 AND A.DATAFECHAMENTO < '20190401'
				THEN 'Leads'
			WHEN A.PROPRIETARIO IN ('debora.nakao','MEREN.FISCHER','leticia.franca')
				 AND A.FASE IN ('fechado_e_ganho','fechado_e_perdido')
				 AND A.DATAFECHAMENTO < '20190401'
				THEN 'SI,NN - Simplifica Novos Negócios'
			WHEN A.PROPRIETARIO IN ('camila.martins','luciana.nascimento','daniela.martins')
				 AND A.FASE IN ('fechado_e_ganho','fechado_e_perdido')
				 AND A.DATAFECHAMENTO < '20190401'
				THEN 'SI,RL - Simplifica Relacionamento'
			WHEN A.PROPRIETARIO IN ('andreza.nogueira','alessandro.silva','daniela.rosa')
				 AND A.FASE IN ('fechado_e_ganho','fechado_e_perdido')
				 AND A.DATAFECHAMENTO < '20190401' 
				THEN 'SU,NN - Supera Novos Negócios'
			WHEN A.PROPRIETARIO IN ('silvia.ferreira','tatiane.pires','karina.ribeiro','fernanda.rocha','andressa.secioso')
				 AND A.FASE IN ('fechado_e_ganho','fechado_e_perdido')
				 AND A.DATAFECHAMENTO < '20190401'
				THEN 'SU,RL - Supera Relacionamento'
			ELSE NULL
		END
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A ;


-- Ajuste de Migração de GR, por período:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		GRUPO_VENDEDOR =  'SI,RL - Simplifica Relacionamento'
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A
WHERE	A.PROPRIETARIO = 'MEREN.FISCHER'
		AND A.FASE IN ('fechado_e_ganho','fechado_e_perdido')
		AND A.DATAFECHAMENTO >= '20181201' AND A.DATAFECHAMENTO < '20190401'
		AND A.GRUPO_VENDEDOR = 'SI,NN - Simplifica Novos Negócios' ;

-- Atualização dos grupos que estão com fase da oportunidade em aberto, ou com data de fechamento a partir de 01/04/2019:
UPDATE	[VAGAS_DW].[OPORTUNIDADES] 
SET		GRUPO_VENDEDOR = B.GRUPO_VENDEDOR
FROM	[VAGAS_DW].[OPORTUNIDADES]  AS A		INNER JOIN VAGAS_DW.GRUPO_VENDEDORES B ON B.VENDEDOR = A.PROPRIETARIO
WHERE	A.FASE NOT IN ('fechado_e_ganho', 'fechado_e_perdido')
		OR (A.FASE IN ('fechado_e_ganho', 'fechado_e_perdido') 
		    AND A.DATAFECHAMENTO >= '20190401')
		OR A.GRUPO_VENDEDOR IS NULL ;