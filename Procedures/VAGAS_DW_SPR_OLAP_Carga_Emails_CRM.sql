USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Emails_CRM' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Emails_CRM
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 24/08/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Emails_CRM 
AS
SET NOCOUNT ON

-- Limpar dados da tabela fato
DELETE VAGAS_DW.EMAILS_CRM
FROM VAGAS_DW.EMAILS_CRM A
WHERE EXISTS ( SELECT 1 FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM
				WHERE ID_EMAIL = A.ID_EMAIL )

-- var Grupo
UPDATE STAGE.VAGAS_DW.TMP_EMAILS_CRM SET GRUPO_VENDEDOR = B.GRUPO_VENDEDOR
FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM A
INNER JOIN VAGAS_DW.GRUPO_VENDEDORES B ON B.VENDEDOR = A.USUARIO_RESPONSAVEL

---- CLIENTE ASSOCIADO � OPORTUNIDADE
--UPDATE STAGE.VAGAS_DW.TMP_EMAILS_CRM SET CONTA = B.CONTA
--FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM A
--INNER JOIN VAGAS_DW.OPORTUNIDADES B ON B.OPORTUNIDADE = A.REFERENTE_A
--WHERE A.TIPO_CONTATO = 'Opportunities'

---- CONTA ASSOCIADA � OPORTUNIDADE
--UPDATE STAGE.VAGAS_DW.TMP_EMAILS_CRM SET CONTA_ID = B.CONTAID
--FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM A
--INNER JOIN VAGAS_DW.OPORTUNIDADES B ON B.OPORTUNIDADE = A.REFERENTE_A
--WHERE A.TIPO_CONTATO = 'Opportunities'

--UPDATE STAGE.VAGAS_DW.TMP_EMAILS_CRM SET CONTA = A.REFERENTE_A
--FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM A
--WHERE A.TIPO_CONTATO IN ('Accounts','Leads')

--UPDATE	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM]
--SET		CONTA_ID = A.ID_TIPO_CONTATO
--FROM	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM] AS A
--WHERE	A.TIPO_CONTATO = 'Accounts' ;

-- ATUALIZAR TIPO DE ANEXO ENVIADO
UPDATE STAGE.VAGAS_DW.TMP_EMAILS_CRM SET TIPO_ANEXO = 'Guia Boas pr�ticas'
FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM 
WHERE ANEXO LIKE 'EB%' OR ANEXO LIKE '%Boas pr�ticas%' OR ANEXO LIKE '%Boas_Praticas_Anuncio_Vaga%'

---- CONTA VINCULADA AO CASO 
--UPDATE STAGE.VAGAS_DW.TMP_EMAILS_CRM SET CONTA = B.CONTA
--FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM A
--INNER JOIN VAGAS_DW.CASOS B ON B.NUMERO_CASO = REPLACE(REPLACE(
--SUBSTRING(SUBSTRING(A.NOME,1,CHARINDEX(']',A.NOME)),CHARINDEX('[',SUBSTRING(A.NOME,1,CHARINDEX(']',A.NOME))),LEN(SUBSTRING(A.NOME,1,CHARINDEX(']',A.NOME))))
--,'[CASE:',''),']','')
--WHERE A.TIPO_ANEXO = 'Guia Boas Pr�ticas'

------------------------------------------------------------
-- Conta associada a um registro de CONTA no CUBO de EMAILS:
------------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM]
SET		CONTA_ID = B.CONTA_ID ,
		CONTA = B.CONTA_CRM
FROM	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM] AS A		LEFT OUTER JOIN ( SELECT A1.CONTA_ID ,
																		 A1.CONTA_CRM
																  FROM	[VAGAS_DW].[CONTAS_CRM] AS A1
																  UNION ALL
																  SELECT A1.CONTA_ID ,
																		 A1.CONTA_CRM
																  FROM	[VAGAS_DW].[CONTAS_MEMBRO_CRM] AS A1 ) AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.CONTA_ID
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Accounts' ;


--------------------------------------------------------------------------
-- Oportunidade associada a um registro de OPORTUNIDADE no CUBO de EMAILS:
--------------------------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM]
SET		CONTA_ID = B.CONTAID ,
		CONTA = B.CONTA
FROM	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM] AS A		LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.OportunidadeID
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Opportunities' ;


-----------------------------------------------------------------
-- Contatos associada a um registro de CONTATO no CUBO de EMAILS:
-----------------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM]
SET		CONTA_ID = B.COD_CONTA_CRM ,
		CONTA = B.CONTA_CRM
FROM	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM] AS A		LEFT OUTER JOIN [VAGAS_DW].[CONTATOS_CRM] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.COD_CONTATO
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Contacts' ;


----------------------------------------------------------
-- Caso associado a um registro de CASO no CUBO de EMAILS:
----------------------------------------------------------
UPDATE	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM]
SET		CONTA_ID = B.CONTA_ID ,
		CONTA = B.CONTA
FROM	[STAGE].[VAGAS_DW].[TMP_EMAILS_CRM] AS A		LEFT OUTER JOIN [VAGAS_DW].[CASOS] AS B ON IIF(ISNULL(A.ID_TIPO_CONTATO, '') = '', A.ID_CONTEXTO, A.ID_TIPO_CONTATO) = B.ID_CASO
WHERE	IIF(ISNULL(A.TIPO_CONTATO, '') = '', A.CONTEXTO, A.TIPO_CONTATO) = 'Cases' ;


INSERT INTO VAGAS_DW.EMAILS_CRM (ID_EMAIL,NOME,DATA_CADASTRO,DATA_ALTERACAO,USUARIO_CADASTRO,USUARIO_ALTERACAO,USUARIO_RESPONSAVEL,
								 DATA_ENVIO,STATUS,TIPO,CLASSIFICACAO,REFERENTE_A,GRUPO_VENDEDOR,TIPO_CONTATO,ID_TIPO_CONTATO,CONTA,ANEXO,TIPO_ANEXO,CONTA_ID,NOME_CONTATO,EMAIL_CONTATO,CONTATO_ADM_PRINCIPAL,CONTEXTO,ID_CONTEXTO)
SELECT ID_EMAIL,NOME,DATA_CADASTRO,DATA_ALTERACAO,USUARIO_CADASTRO,USUARIO_ALTERACAO,USUARIO_RESPONSAVEL,DATA_ENVIO,
	   CASE WHEN STATUS = 'unread' THEN 'N�o Lido'
			WHEN STATUS = 'read' THEN 'Lido'
			WHEN STATUS = 'Email cadastrado como NOTA' THEN STATUS
			ELSE 'N�o Classificado' END,
	   CASE WHEN TIPO = 'inbound' THEN 'Recebido'
			WHEN TIPO = 'out' THEN 'Enviado'
			ELSE 'N�o Classificado' END,
	   CASE WHEN CHARINDEX('#Prospec��o',NOME) > 0 THEN 'Prospec��o'
			WHEN CHARINDEX('#Relacionamento',NOME) > 0 THEN 'Relacionamento'
			ELSE 'N�o Classificado' END,
	  REFERENTE_A,
	  GRUPO_VENDEDOR,
	  IIF(ISNULL(TIPO_CONTATO, '') = '', CONTEXTO, TIPO_CONTATO) AS TIPO_CONTATO ,
	  IIF(ISNULL(ID_TIPO_CONTATO, '') = '', ID_CONTEXTO, ID_TIPO_CONTATO) AS ID_TIPO_CONTATO ,
	  CONTA,
	  ANEXO,
	  TIPO_ANEXO ,
	  CONTA_ID ,
	  NOME_CONTATO ,
	  EMAIL_CONTATO ,
	  CONTATO_ADM_PRINCIPAL,
	  CONTEXTO,
	  ID_CONTEXTO
FROM STAGE.VAGAS_DW.TMP_EMAILS_CRM
WHERE FLAG_DELETADO = 0


-------------------------------------------------------------------------------
-- Atualiza o campo que informa se o USUARIO_RESPONSAVEL � o atual GR da CONTA:
-------------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[EMAILS_CRM]
SET		FLAG_USR_RESP_GR = 1
FROM	[VAGAS_DW].[EMAILS_CRM] AS A
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
				 WHERE	A.CONTA_ID = SUBQUERY.CONTA_ID
						AND (A.USUARIO_RESPONSAVEL = SUBQUERY.PROPRIETARIO_CONTA
							  OR A.USUARIO_CADASTRO = SUBQUERY.PROPRIETARIO_CONTA
							  OR A.USUARIO_ALTERACAO = SUBQUERY.PROPRIETARIO_CONTA) ) ;


---------------------------------------------------------------------------------------------------
-- Atualiza o campo que informa se o contato � a partir da DATA_CONTRATO_MANUT no CUBO de CLIENTES:
---------------------------------------------------------------------------------------------------
UPDATE	[VAGAS_DW].[EMAILS_CRM]
SET		FLAG_DATA_CONTRATO_MANUT = 1
FROM	[VAGAS_DW].[EMAILS_CRM] AS A
WHERE	A.DATA_CADASTRO >= (SELECT	A1.DATA_CONTRATO_MANUT
							FROM	[VAGAS_DW].[CLIENTES] AS A1
							WHERE	A.CONTA_ID = A1.CONTA_ID) ;