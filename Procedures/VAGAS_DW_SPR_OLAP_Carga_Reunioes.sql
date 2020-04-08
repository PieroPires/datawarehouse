USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_REUNIOES' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_REUNIOES
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_REUNIOES 
AS
SET NOCOUNT ON

--DECLARE @DATA_CARGA SMALLDATETIME

--SELECT @DATA_CARGA = MIN(CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_CRIACAO,112)))
--FROM [STAGE].[VAGAS_DW].[TMP_REUNIOES] 

--DELETE FROM VAGAS_DW.REUNIOES
--WHERE DATA_CRIACAO >= @DATA_CARGA

TRUNCATE TABLE VAGAS_DW.REUNIOES

-- ATUALIZAR GRUPO VENDEDOR
UPDATE [STAGE].[VAGAS_DW].[TMP_REUNIOES] SET GRUPO_VENDEDOR = ISNULL(B.GRUPO_VENDEDOR,'Outros')
FROM [STAGE].[VAGAS_DW].[TMP_REUNIOES] A
LEFT OUTER JOIN VAGAS_DW.GRUPO_VENDEDORES B ON B.VENDEDOR = A.USUARIO_PARTICIPANTE

---- CLIENTE ASSOCIADO À OPORTUNIDADE
--UPDATE [STAGE].[VAGAS_DW].[TMP_REUNIOES] SET CONTA = B.CONTA,CONTAID = B.CONTAID
--FROM [STAGE].[VAGAS_DW].[TMP_REUNIOES] A
--INNER JOIN VAGAS_DW.OPORTUNIDADES B ON B.OPORTUNIDADE = A.OPORTUNIDADE
--WHERE A.TIPO_CONTATO = 'Opportunities'


--------------------------------------------------------------
-- Conta associada a um registro de CONTA no CUBO de REUNIOES:
--------------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_REUNIOES]
SET		CONTAID = B.CONTA_ID ,
		CONTA = B.CONTA_CRM
FROM	[STAGE].[VAGAS_DW].[TMP_REUNIOES] AS A		LEFT OUTER JOIN ( SELECT A1.CONTA_ID ,
																	 A1.CONTA_CRM
															  FROM	[VAGAS_DW].[CONTAS_CRM] AS A1
															  UNION ALL
															  SELECT A1.CONTA_ID ,
																	 A1.CONTA_CRM
															  FROM	[VAGAS_DW].[CONTAS_MEMBRO_CRM] AS A1 ) AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.CONTA_ID
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Accounts' ;


----------------------------------------------------------------------------
-- Oportunidade associada a um registro de OPORTUNIDADE no CUBO de REUNIOES:
----------------------------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_REUNIOES]
SET		CONTAID = B.CONTAID ,
		CONTA = B.CONTA
FROM	[STAGE].[VAGAS_DW].[TMP_REUNIOES] AS A		LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.OportunidadeID
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Opportunities' ;


------------------------------------------------------------------
-- Contato associado a um registro de CONTATO no CUBO de REUNIOES:
------------------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_REUNIOES]
SET		CONTAID = B.COD_CONTA_CRM ,
		CONTA = B.CONTA_CRM
FROM	[STAGE].[VAGAS_DW].[TMP_REUNIOES] AS A		LEFT OUTER JOIN [VAGAS_DW].[CONTATOS_CRM] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.COD_CONTATO
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Contacts' ;


------------------------------------------------------------
-- Caso associado a um registro de CASO no CUBO de REUNIOES:
------------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_REUNIOES]
SET		CONTAID = B.CONTA_ID ,
		CONTA = B.CONTA
FROM	[STAGE].[VAGAS_DW].[TMP_REUNIOES] AS A		LEFT OUTER JOIN [VAGAS_DW].[CASOS] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.ID_CASO
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Cases' ;


INSERT INTO VAGAS_DW.REUNIOES (ID_REUNIAO,USUARIO_PARTICIPANTE,USUARIO_CRIACAO,USUARIO_RESPONSAVEL,GRUPO_VENDEDOR,CONTAID,CONTA,ASSUNTO,DATA_INICIO,DATA_CRIACAO,
								STATUS,TIPO,DURACAO_HORAS,DURACAO_MINUTOS,OPORTUNIDADE,FLAG_RESPONSAVEL_REUNIAO,TIPO_CONTATO,CONTEXTO,ID_CONTEXTO)
SELECT ID_REUNIAO,
	   USUARIO_PARTICIPANTE,
	   USUARIO_CRIACAO,
	   USUARIO_RESPONSAVEL,
	   GRUPO_VENDEDOR,
	   CONTAID,
	   CONTA,
	   ASSUNTO,
	   DATA_INICIO,
	   DATA_CRIACAO,
	   CASE WHEN STATUS = 'Held' THEN 'Realizado'
			WHEN STATUS = 'Planned' THEN 'Planejado'
			WHEN STATUS = 'Not Held' THEN 'Não Realizado'
			ELSE 'Não Classificado' END,
	   TIPO,
	   DURACAO_HORAS,
	   DURACAO_MINUTOS,
	   OPORTUNIDADE,
	   FLAG_RESPONSAVEL_REUNIAO,
	   TIPO_CONTATO,
	   CONTEXTO,
	   ID_CONTEXTO
FROM [STAGE].[VAGAS_DW].[TMP_REUNIOES]


--------------------------------------------------------------------------------
-- Atualiza o campo que informar se o USUARIO_RESPONSAVEL é o atual GR da CONTA:
--------------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[REUNIOES]
SET		FLAG_USR_RESP_GR = 1
FROM	[VAGAS_DW].[REUNIOES] AS A
WHERE	EXISTS ( SELECT	1
				 FROM	
						(SELECT	A1.CONTA_ID ,
								A1.CONTA_CRM ,
								A1.PROPRIETARIO_CONTA
						 FROM		[VAGAS_DW].[CONTAS_CRM] AS A1
						 UNION ALL
						 SELECT	A1.CONTA_ID ,
								A1.CONTA_CRM ,
								A1.PROPRIETARIO_CONTA
						 FROM		[VAGAS_DW].[CONTAS_MEMBRO_CRM] AS A1 ) AS SUBQUERY
				 WHERE	(A.CONTAID = SUBQUERY.CONTA_ID
						 OR A.CONTA = SUBQUERY.CONTA_CRM ) 
						 AND (A.USUARIO_RESPONSAVEL = SUBQUERY.PROPRIETARIO_CONTA
						      OR A.USUARIO_PARTICIPANTE = SUBQUERY.PROPRIETARIO_CONTA) ) ;


---------------------------------------------------------------------------------------------------
-- Atualiza o campo que informa se a reunião é a partir da DATA_CONTRATO_MANUT no CUBO de CLIENTES:
---------------------------------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[REUNIOES]
SET		FLAG_DATA_CONTRATO_MANUT = 1
FROM	[VAGAS_DW].[REUNIOES] AS A
WHERE	A.DATA_INICIO >= (SELECT	A1.DATA_CONTRATO_MANUT
						  FROM		[VAGAS_DW].[CLIENTES] AS A1
						  WHERE		A.CONTAID = A1.CONTA_ID) ;