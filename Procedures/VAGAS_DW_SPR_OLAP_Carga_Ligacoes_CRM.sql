USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Ligacoes_CRM' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Ligacoes_CRM
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Ligacoes_CRM 
AS
SET NOCOUNT ON

-- Limpar dados da tabela fato
DELETE VAGAS_DW.LIGACOES_CRM
FROM VAGAS_DW.LIGACOES_CRM A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_LIGACOES_CRM
				WHERE ID_LIGACAO = A.ID_LIGACAO )

-- var Grupo
UPDATE VAGAS_DW.TMP_LIGACOES_CRM SET GRUPO_VENDEDOR = B.GRUPO_VENDEDOR
FROM VAGAS_DW.TMP_LIGACOES_CRM A
INNER JOIN VAGAS_DW.GRUPO_VENDEDORES B ON B.VENDEDOR = A.USUARIO_RESPONSAVEL

---- CLIENTE ASSOCIADO À OPORTUNIDADE
--UPDATE VAGAS_DW.TMP_LIGACOES_CRM SET CONTA = B.CONTA
--FROM VAGAS_DW.TMP_LIGACOES_CRM A
--INNER JOIN VAGAS_DW.OPORTUNIDADES B ON B.OPORTUNIDADE = A.REFERENTE_A
--WHERE A.TIPO_CONTATO = 'Opportunities'

---- CONTA ASSOCIADA À OPORTUNIDADE
--UPDATE	[VAGAS_DW].[TMP_LIGACOES_CRM]
--SET		CONTA_ID = B.CONTAID
--FROM	[VAGAS_DW].[TMP_LIGACOES_CRM] AS A		INNER JOIN [VAGAS_DW].[OPORTUNIDADES] AS B ON B.OPORTUNIDADE = A.REFERENTE_A
--WHERE	A.TIPO_CONTATO = 'Opportunities' ;


--UPDATE VAGAS_DW.TMP_LIGACOES_CRM SET CONTA = A.REFERENTE_A
--FROM VAGAS_DW.TMP_LIGACOES_CRM A
--WHERE A.TIPO_CONTATO IN ('Accounts','Leads')

--UPDATE	[VAGAS_DW].[TMP_LIGACOES_CRM]
--SET		CONTA_ID = A.ID_TIPO_CONTATO
--FROM	[VAGAS_DW].[TMP_LIGACOES_CRM] AS A
--WHERE	A.TIPO_CONTATO = 'Accounts' ;


--------------------------------------------------------------
-- Conta associada a um registro de CONTA no CUBO de LIGACOES:
--------------------------------------------------------------
UPDATE	[VAGAS_DW].[TMP_LIGACOES_CRM]
SET		CONTA_ID = B.CONTA_ID ,
		CONTA = B.CONTA_CRM
FROM	[VAGAS_DW].[TMP_LIGACOES_CRM] AS A		LEFT OUTER JOIN ( SELECT A1.CONTA_ID ,
																		 A1.CONTA_CRM
																  FROM	[VAGAS_DW].[CONTAS_CRM] AS A1
																  UNION ALL
																  SELECT A1.CONTA_ID ,
																		 A1.CONTA_CRM
																  FROM	[VAGAS_DW].[CONTAS_MEMBRO_CRM] AS A1 ) AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.CONTA_ID
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Accounts' ;


----------------------------------------------------------------------------
-- Oportunidade associada a um registro de OPORTUNIDADE no CUBO de LIGACOES:
----------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[TMP_LIGACOES_CRM]
SET		CONTA_ID = B.CONTAID ,
		CONTA = B.CONTA
FROM	[VAGAS_DW].[TMP_LIGACOES_CRM] AS A		LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.OportunidadeID
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Opportunities' ;


-------------------------------------------------------------------
-- Contato associado a um registro de CONTATO no CUBO de LIGACOES:
-------------------------------------------------------------------
UPDATE	[VAGAS_DW].[TMP_LIGACOES_CRM]
SET		CONTA_ID = B.COD_CONTA_CRM ,
		CONTA = B.CONTA_CRM
FROM	[VAGAS_DW].[TMP_LIGACOES_CRM] AS A		LEFT OUTER JOIN [VAGAS_DW].[CONTATOS_CRM] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.COD_CONTATO
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Contacts' ;


------------------------------------------------------------
-- Caso associado a um registro de CASO no CUBO de LIGACOES:
------------------------------------------------------------
UPDATE	[VAGAS_DW].[TMP_LIGACOES_CRM]
SET		CONTA_ID = B.CONTA_ID ,
		CONTA = B.CONTA
FROM	[VAGAS_DW].[TMP_LIGACOES_CRM] AS A		LEFT OUTER JOIN [VAGAS_DW].[CASOS] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.ID_CASO
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Cases' ;

INSERT INTO VAGAS_DW.LIGACOES_CRM (ID_LIGACAO,NOME,DESCRICAO,DATA_CADASTRO,DATA_ALTERACAO,USUARIO_CADASTRO,USUARIO_ALTERACAO,
									USUARIO_RESPONSAVEL,DURACAO_HORAS,DURACAO_MINUTOS,DATA_INICIO,DATA_FIM,STATUS,TIPO,CLASSIFICACAO,
									REFERENTE_A,GRUPO_VENDEDOR,TIPO_CONTATO,CONTA,CONTA_ID,NOME_CONTATO,EMAIL_CONTATO,CONTATO_ADM_PRINCIPAL,CONTEXTO,ID_CONTEXTO)
SELECT ID_LIGACAO,
	   NOME,
	   DESCRICAO,
	   DATA_CADASTRO,
	   DATA_ALTERACAO,
	   USUARIO_CADASTRO,
	   USUARIO_ALTERACAO,
	   USUARIO_RESPONSAVEL,
	   DURACAO_HORAS,
	   DURACAO_MINUTOS,
	   DATA_INICIO,
	   DATA_FIM,
	   CASE WHEN STATUS = 'Held' THEN 'Realizado'
			WHEN STATUS = 'Planned' THEN 'Planejado'
			WHEN STATUS = 'Not Held' THEN 'Não Realizado'
			ELSE 'Não Classificado' END,
	   CASE WHEN TIPO = 'Inbound' THEN 'Recebida'
			WHEN TIPO = 'Outbound' THEN 'Efetuada'
			ELSE 'Não Classificado' END,
	   CASE WHEN CHARINDEX('#Prospecção',NOME) > 0 OR CHARINDEX('#Prospecção',DESCRICAO) > 0 THEN 'Prospecção'
			WHEN CHARINDEX('#Relacionamento',NOME) > 0 OR CHARINDEX('#Relacionamento',DESCRICAO) > 0 THEN 'Relacionamento'
			ELSE 'Não Classificado' END,
	   REFERENTE_A,
	   GRUPO_VENDEDOR,
	   TIPO_CONTATO,
	   CONTA,
	   CONTA_ID,
	   NOME_CONTATO,
	   EMAIL_CONTATO,
	   CONTATO_ADM_PRINCIPAL,
	   CONTEXTO,
	   ID_CONTEXTO
FROM VAGAS_DW.TMP_LIGACOES_CRM
WHERE FLAG_DELETADO = 0


--------------------------------------------------------------------------------
-- Atualiza o campo que informar se o USUARIO_RESPONSAVEL é o atual GR da CONTA:
--------------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[LIGACOES_CRM]
SET		FLAG_USR_RESP_GR = 1
FROM	[VAGAS_DW].[LIGACOES_CRM] AS A
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
				 WHERE	(A.CONTA_ID = SUBQUERY.CONTA_ID) 
						 AND (A.USUARIO_RESPONSAVEL = SUBQUERY.PROPRIETARIO_CONTA
							  OR A.USUARIO_CADASTRO = SUBQUERY.PROPRIETARIO_CONTA
							  OR A.USUARIO_ALTERACAO = SUBQUERY.PROPRIETARIO_CONTA) ) ;



---------------------------------------------------------------------------------------------------
-- Atualiza o campo que informa se o contato é a partir da DATA_CONTRATO_MANUT no CUBO de CLIENTES:
---------------------------------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[LIGACOES_CRM]
SET		FLAG_DATA_CONTRATO_MANUT = 1
FROM	[VAGAS_DW].[LIGACOES_CRM] AS A
WHERE	A.DATA_FIM >= (SELECT	A1.DATA_CONTRATO_MANUT
					   FROM		[VAGAS_DW].[CLIENTES] AS A1
					   WHERE	A.CONTA_ID = A1.CONTA_ID) ;