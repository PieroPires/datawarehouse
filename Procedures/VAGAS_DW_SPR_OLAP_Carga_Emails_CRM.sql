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
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_EMAILS_CRM
				WHERE ID_EMAIL = A.ID_EMAIL )

-- var Grupo
UPDATE VAGAS_DW.TMP_EMAILS_CRM SET GRUPO_VENDEDOR = B.GRUPO_VENDEDOR
FROM VAGAS_DW.TMP_EMAILS_CRM A
INNER JOIN VAGAS_DW.GRUPO_VENDEDORES B ON B.VENDEDOR = A.USUARIO_RESPONSAVEL

INSERT INTO VAGAS_DW.EMAILS_CRM (ID_EMAIL,NOME,DATA_CADASTRO,DATA_ALTERACAO,USUARIO_CADASTRO,USUARIO_ALTERACAO,USUARIO_RESPONSAVEL,
								 DATA_ENVIO,STATUS,TIPO,CLASSIFICACAO,REFERENTE_A,GRUPO_VENDEDOR)
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
	  GRUPO_VENDEDOR
FROM VAGAS_DW.TMP_EMAILS_CRM
WHERE FLAG_DELETADO = 0



