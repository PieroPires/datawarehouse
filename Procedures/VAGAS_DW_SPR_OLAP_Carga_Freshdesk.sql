USE [VAGAS_DW]
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Freshdesk' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Freshdesk
GO

-- =============================================
-- Author: Diego Gatto
-- Create date: 29/10/2019
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Freshdesk

AS
SET NOCOUNT ON

/*
	TABELA DE AGENTES
*/
DELETE FROM VAGAS_DW.FRESHDESK_AGENTES
FROM VAGAS_DW.FRESHDESK_AGENTES AS A
	JOIN STAGE.VAGAS_DW.TMP_FRESHDESK_AGENTES AS B ON A.ID_AGENTE = B.ID_AGENTE
WHERE B.DATA_ATUALIZACAO > A.DATA_ATUALIZACAO

DELETE FROM STAGE.VAGAS_DW.TMP_FRESHDESK_AGENTES
FROM STAGE.VAGAS_DW.TMP_FRESHDESK_AGENTES AS A
	JOIN VAGAS_DW.FRESHDESK_AGENTES AS B ON A.ID_AGENTE = B.ID_AGENTE
WHERE B.DATA_ATUALIZACAO >= A.DATA_ATUALIZACAO

INSERT INTO VAGAS_DW.FRESHDESK_AGENTES(ID_AGENTE, NOME, EMAIL, FLAG_ATIVO, DATA_CRIACAO, DATA_ATUALIZACAO)
SELECT ID_AGENTE, NOME, EMAIL, FLAG_ATIVO, DATA_CRIACAO, DATA_ATUALIZACAO
FROM STAGE.VAGAS_DW.TMP_FRESHDESK_AGENTES

/*
	TABELA DE CONTATOS
*/

DELETE FROM VAGAS_DW.FRESHDESK_CONTATOS
WHERE ID_CONTATO IN (SELECT ID_CONTATO FROM STAGE.VAGAS_DW.TMP_FRESHDESK_CONTATOS)

INSERT INTO VAGAS_DW.FRESHDESK_CONTATOS(ID_CONTATO, NOME, TITULO, EMAIL, FLAG_ATIVO, DATA_CRIACAO, DATA_ATUALIZACAO, CPF)
SELECT ID_CONTATO, Coalesce(NOME, 'Não informado'), Coalesce(TITULO, 'Não definido'), COALESCE(EMAIL, 'Não informado'), FLAG_ATIVO, DATA_CRIACAO, DATA_ATUALIZACAO, COALESCE(CPF, 'Não informado')
FROM STAGE.VAGAS_DW.TMP_FRESHDESK_CONTATOS

/*
	TABELA DE TICKETS
*/

DELETE FROM VAGAS_DW.FRESHDESK_TICKETS
WHERE ID_TICKET IN (SELECT ID_TICKET FROM STAGE.VAGAS_DW.TMP_FRESHDESK_TICKETS)

INSERT INTO VAGAS_DW.FRESHDESK_TICKETS(ID_TICKET, FILA_ATENDIMENTO, SUBTIPO, DATA_CRIACAO, FLAG_ESCALADO, EMAIL_ENCAMINHADO, PRIORIDADE, ID_CLIENTE, ID_ATENDENTE, ORIGEM, [STATUS], ASSUNTO, TIPO, DATA_ATUALIZACAO, DATA_PRIMEIRA_RESPOSTA, DATA_RESOLUCAO, DATA_FECHAMENTO)
SELECT ID_TICKET, FILA_ATENDIMENTO, COALESCE(SUBTIPO, 'Não definido'), DATA_CRIACAO, FLAG_ESCALADO, EMAIL_ENCAMINHADO, PRIORIDADE, ID_CLIENTE, ID_ATENDENTE, ORIGEM, [STATUS], ASSUNTO, COALESCE(TIPO, 'Não definido'), DATA_ATUALIZACAO, DATA_PRIMEIRA_RESPOSTA, DATA_RESOLUCAO, DATA_FECHAMENTO
FROM STAGE.VAGAS_DW.TMP_FRESHDESK_TICKETS

/*
	CONVERSAS
*/

DELETE FROM VAGAS_DW.FRESHDESK_CONVERSAS
WHERE ID_CONVERSA IN (SELECT ID_CONVERSA FROM STAGE.VAGAS_DW.TMP_FRESHDESK_CONVERSAS)

INSERT INTO VAGAS_DW.FRESHDESK_CONVERSAS
SELECT * FROM STAGE.VAGAS_DW.TMP_FRESHDESK_CONVERSAS

/*
	CONSULTA PARA CRIAÇÃO DO CUBO
*/
/*
SELECT TOP 10
	A.ID_TICKET
	,A.FILA_ATENDIMENTO
	,A.TIPO
	,A.SUBTIPO
	,CAST(A.DATA_CRIACAO AS smalldatetime) AS DATA_CRIACAO
	,A.FLAG_ESCALADO
	,A.EMAIL_ENCAMINHADO
	,A.PRIORIDADE
	,B.NOME AS AGENTE
	,C.NOME AS CLIENTE
	,C.EMAIL AS EMAIL_CLIENTE
	,C.TITULO AS TITULO_CLIENTE
	,C.CPF AS CPF_CLIENTE
	,A.ORIGEM
	,A.STATUS
FROM VAGAS_DW.FRESHDESK_TICKETS AS A
	LEFT JOIN VAGAS_DW.FRESHDESK_AGENTES AS B ON A.ID_ATENDENTE = B.ID_AGENTE
	LEFT JOIN VAGAS_DW.FRESHDESK_CONTATOS AS C ON A.ID_CLIENTE = C.ID_CONTATO
*/