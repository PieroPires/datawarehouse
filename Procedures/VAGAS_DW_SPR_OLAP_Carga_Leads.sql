USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_LEADS' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_LEADS
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 16/03/2016
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_LEADS 
AS
SET NOCOUNT ON



DELETE	VAGAS_DW.LEADS
FROM	VAGAS_DW.LEADS A
WHERE	EXISTS ( SELECT 1 FROM STAGE.VAGAS_DW.TMP_LEADS
				WHERE ID_LEAD = A.ID_LEAD
					  AND registro_teste IS NULL )
		AND registro_teste IS NULL ;
		

---- MARCAR SE O LEAD FOI ATRELADO à OPORTUNIDADE FLEX (NECESSIDADE GADE 1)
--UPDATE STAGE.VAGAS_DW.TMP_LEADS SET FLAG_CONTEM_FLEX_CREDITO = CASE WHEN B.OPORTUNIDADEID IS NOT NULL THEN 1 ELSE 0 END
--FROM STAGE.VAGAS_DW.TMP_LEADS A
--OUTER APPLY ( SELECT TOP 1 * 
--			  FROM VAGAS_DW.OPORTUNIDADES 
--			  WHERE OPORTUNIDADEID = A.OPORTUNIDADE_ID
--			  AND PRODUTO_GRUPO = 'FLEX' ) B

-- Inserir novos leads
INSERT INTO VAGAS_DW.LEADS(ID_LEAD,PRIMEIRO_NOME,ULTIMO_NOME,CONTA,ORIGEM,FLAG_CONVERTIDO,SEGMENTO,USUARIO,STATUS,DATA_INCLUSAO,DATA_ALTERACAO,
EMAIL,COMO_CONHECEU_VAGAS,MOTIVO_PERDA,OPORTUNIDADE,FASE_OPORTUNIDADE,VALOR_VENDA,OPORTUNIDADE_ID,CREDITOS_VAGAS, CAMPANHA, CONTA_ID,DATA_CONCLUSAO,CARGO,FORMULARIO_ORIGEM,CATEGORIA_LEAD,
Origem_lead_RD,Area_atuacao,Numero_colaboradores_RD,Media_mensal_de_processos,Web_lead,id_externo_RD,Sistema_externo_RD,URL_externa_RD,Score,Identificador_conversao)
SELECT	ID_LEAD,
		PRIMEIRO_NOME,
		ULTIMO_NOME,
		CONTA,
		ORIGEM,
		FLAG_CONVERTIDO,
		SEGMENTO,
		USUARIO,
		STATUS,
		CONVERT(SMALLDATETIME,CONVERT(VARCHAR, DATA_INCLUSAO,112)),
		CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_ALTERACAO,112)),
		EMAIL,
		COMO_CONHECEU_VAGAS,
		MOTIVO_PERDA,
		OPORTUNIDADE,
		FASE_OPORTUNIDADE,
		VALOR_VENDA,
		OPORTUNIDADE_ID,
		CREDITOS_VAGAS,
		CAMPANHA,
		CONTA_ID,
		DATA_CONCLUSAO,
		CARGO,
		FORMULARIO_ORIGEM,
		CASE
			WHEN CATEGORIA_LEAD = 'for_business' THEN 'For business'
			WHEN CATEGORIA_LEAD = 'midia' THEN 'Publicidade'
			ELSE CATEGORIA_LEAD
		END,				
		Origem_lead_RD,
		Area_atuacao,
		Numero_colaboradores_RD,
		Media_mensal_de_processos,
		Web_lead,
		id_externo_RD,
		Sistema_externo_RD,
		URL_externa_RD,
		Score,
		Identificador_conversao
FROM	STAGE.VAGAS_DW.TMP_LEADS


-- Regra FLAG_EMAIL_GENERICO:
UPDATE	[VAGAS_DW].[LEADS]
SET		FLAG_EMAIL_GENERICO = CASE
									WHEN (A.EMAIL IS NULL OR A.EMAIL NOT LIKE '%@%')	THEN 'SIM'
									WHEN LTRIM(RTRIM(REVERSE(SUBSTRING(REVERSE(LTRIM(RTRIM(A.EMAIL))), 1, CHARINDEX('@', REVERSE(LTRIM(RTRIM(A.EMAIL)))))))) 
																												IN (SELECT	A1.NOME_DOMINIO
																													FROM	[VAGAS_DW].[LEADS_DOMINIO_GENERICO] AS A1)
																						THEN 'SIM'
									ELSE 'NÃO'
								END
FROM	[VAGAS_DW].[LEADS] AS A ;


-----------------------------------------------------
-- Cálculo do Lead-Time em horas, minutos e segundos:
-----------------------------------------------------
UPDATE	[VAGAS_DW].[LEADS]
SET		LEAD_TIME = CONVERT(FLOAT, DATEDIFF(SECOND, DATA_INCLUSAO, DATA_CONCLUSAO))/60/60/24
FROM	[VAGAS_DW].[LEADS] AS A
WHERE	A.DATA_CONCLUSAO IS NOT NULL ;


-------------------------------------------------------------------------
-- Tratamento do campo CONTA, para evitar duplicidade de registros no DW:
-------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[VAGAS_DW].[LEADS]
SET		CONTA = REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(A.CONTA, ''))), CHAR(9), ''), CHAR(10), ''), CHAR(10), '')
FROM	[VAGAS_DW].[LEADS] AS A ;

-------------------------------------------------------------------------
-- Marcação se foi enviado e-mail de auto cadastro:
-------------------------------------------------------------------------
UPDATE VAGAS_DW.LEADS
SET [Enviado E-mail de Auto Cadastro] = 'Sim'
FROM VAGAS_DW.LEADS AS A
	JOIN STAGE.VAGAS_DW.TMP_LEADS_AUTO_CADASTRO AS B ON A.ID_LEAD = B.LEAD_ID;