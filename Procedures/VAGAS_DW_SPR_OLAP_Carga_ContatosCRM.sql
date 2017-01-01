-- ============================================= 
-- Author: Fiama 
-- Create date: 16/12/2016 
-- Description: Procedure para carga dos dados na tabela VAGAS_DW.CONTATOS_CRM 
-- ============================================= 
 
USE VAGAS_DW ; 
 
IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_ContatosCRM' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW') 
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_ContatosCRM ; 
GO 
 
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_ContatosCRM 
 
AS 
SET NOCOUNT ON 
 
-- Limpar a VAGAS_DW.CONTATOS_CRM: 
TRUNCATE TABLE [VAGAS_DW].[VAGAS_DW].[CONTATOS_CRM] 
 
-- Carrega os dados na VAGAS_DW.CONTATOS_CRM: 
INSERT INTO [VAGAS_DW].[VAGAS_DW].[CONTATOS_CRM] (COD_CONTATO, NOME, SOBRENOME, DATA_INCLUSAO, DATA_MODIFICACAO, CARGO, DEPARTAMENTO, TELEFONE_CELULAR, TELEFONE_CONTATO, TELEFONE_OUTRO, RUA, CIDADE, ESTADO, PA�S, EMAIL, CLIENTE_VAGAS, CONTA_CRM, COD_CONTA_CRM, TIPO_CLIENTE_MANUT, TIPO_CLIENTE, EX_CLIENTE)
SELECT  A.COD_CONTATO , 
    A.NOME , 
    A.SOBRENOME , 
    A.DATA_INCLUSAO , 
    A.DATA_MODIFICACAO , 
    A.CARGO , 
    A.DEPARTAMENTO , 
    A.TELEFONE_CELULAR , 
    A.TELEFONE_CONTATO , 
    A.TELEFONE_OUTRO , 
    A.RUA , 
    A.CIDADE , 
    A.ESTADO , 
    A.PA�S ,
    A.EMAIL , 
    A.CLIENTE_VAGAS , 
    A.CONTA_CRM , 
    A.COD_CONTA_CRM , 
    B.TIPO_CLIENTE_MANUT , 
    B.TIPO_CLIENTE , 
    EX_CLIENTE 
FROM  [VAGAS_DW].[VAGAS_DW].[TMP_CONTATOS_CRM] AS A  LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS B ON A.COD_CONTA_CRM = B.CONTA_ID 
AND B.DATA_REFERENCIA = (SELECT MAX(A1.DATA_REFERENCIA) 
               FROM  [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS A1) 
 
 
-- Estrutura tempor�ria:
UPDATE [VAGAS_DW].[VAGAS_DW].[CONTATOS_CRM] 
SET OPTIN_EXACT_TARGET = 1 ; 
 
 
-- E-mails a serem removidos do OPTIN: 
UPDATE [VAGAS_DW].[VAGAS_DW].[CONTATOS_CRM] 
SET OPTIN_EXACT_TARGET = 0 
WHERE EMAIL = 'Michelle.Mica@dentsuaegis.com' ; 

-- Atualiza��o do campo "dominio" baseado no campo e-mail
UPDATE VAGAS_DW.CONTATOS_CRM SET DOMINIO = REPLACE(REPLACE(SUBSTRING(EMAIL,CHARINDEX('@',EMAIL),LEN(EMAIL)),
			   SUBSTRING(SUBSTRING(EMAIL,CHARINDEX('@',EMAIL),LEN(EMAIL)),CHARINDEX('.',SUBSTRING(EMAIL,CHARINDEX('@',EMAIL),LEN(EMAIL))),
			   LEN(SUBSTRING(EMAIL,CHARINDEX('@',EMAIL),LEN(EMAIL)))),
	   ''),'@','')
FROM VAGAS_DW.CONTATOS_CRM
WHERE DOMINIO IS NULL

 
 
-- Fazer a carga particionada, conforme a data modifica��o e a data de inclus�o, considerar os updates nos campos dos contatos j� existentes em VAGAS_DW.CONTATOS_CRM, e fazer o insert a partir da VAGAS_DW.TMP_CONTA.