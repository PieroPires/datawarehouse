USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_CONTRATOS' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_CONTRATOS
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_CONTRATOS 
AS
SET NOCOUNT ON

TRUNCATE TABLE VAGAS_DW.CONTRATOS

DROP INDEX IF EXISTS IDX_CONTRATOS_CONTAID ON VAGAS_DW.CONTRATOS

-- Inserir novos contratos 
INSERT INTO VAGAS_DW.CONTRATOS (ID_CONTRATO,CONTA_ID,CONTA,PROPRIETARIO,TIPO,INICIO_VIGENCIA,FIM_VIGENCIA,
								STATUS,DATA_ALTERACAO,VALOR,DOCUMENTO,CLIENTE_VAGAS,CNPJ,CATEGORIA_CONTA,TIPO_CONTA,CLIENTE_HSYS,NOME_CONTRATO,
								NUMERO_CONTRATO,CONTEM_FIT,CONTEM_REDES,CONTEM_FLEX,CONTEM_PRC,CONTEM_VET,INDICE,TIPO_RENOVACAO,
								DATA_PRM_ASSINATURA,DATA_RECEBIMENTO_DIGITAL,DATA_RECEBIMENTO_FISICO,DATA_ENVIO_FISICO,TIPO_ENVIO,
								TIPO_ENVIO_COMPLEMENTO,DATA_SOLICITACAO,DATA_EMISSAO)
SELECT ID_CONTRATO,CONTA_ID,CONTA,PROPRIETARIO,TIPO,INICIO_VIGENCIA,FIM_VIGENCIA,STATUS,DATA_ALTERACAO,VALOR,DOCUMENTO,
		CLIENTE_VAGAS,CNPJ,CATEGORIA_CONTA,TIPO_CONTA,CLIENTE_HSYS,NOME_CONTRATO,
		NUMERO_CONTRATO,CONTEM_FIT,CONTEM_REDES,CONTEM_FLEX,CONTEM_PRC,CONTEM_VET,INDICE,TIPO_RENOVACAO,
		DATA_PRM_ASSINATURA,DATA_RECEBIMENTO_DIGITAL,DATA_RECEBIMENTO_FISICO,DATA_ENVIO_FISICO,TIPO_ENVIO,
		TIPO_ENVIO_COMPLEMENTO,DATA_SOLICITACAO,DATA_EMISSAO
FROM STAGE.VAGAS_DW.TMP_CONTRATOS

CREATE NONCLUSTERED INDEX IDX_CONTRATOS_CONTAID ON VAGAS_DW.CONTRATOS (CONTA_ID)

-- Iniciar atualiza��o do "valor" para os �lt. contratos
SELECT DISTINCT CONTAID,OportunidadeValor 
INTO #TMP_OPORTUNIDADE_VALOR
FROM VAGAS_DW.OPORTUNIDADES A
WHERE Fase = 'fechado_e_ganho'
AND RECORRENTE = 1
AND DataFechamento = ( SELECT MAX(DataFechamento) FROM VAGAS_DW.OPORTUNIDADES 
						WHERE CONTAID = A.CONTAID
						AND Fase = 'fechado_e_ganho' 
						AND Recorrente = 1 ) -- Pegar �ltima oportunidade fechada e ganha

-- ATUALIZAR CONTRATOS COM �LTIMO VALOR
UPDATE VAGAS_DW.CONTRATOS SET VALOR =  CASE WHEN VALOR IS NULL OR VALOR = 0 THEN B.OportunidadeValor
											ELSE VALOR END, -- CASO O VALOR ORIGINAL DO CRM TENHA SIDO INFORMADO N�S MANTEREMOS ESTE VALOR
							  FLAG_ULT_CONTRATO = 1
FROM VAGAS_DW.CONTRATOS A
INNER JOIN #TMP_OPORTUNIDADE_VALOR B ON B.CONTAID = A.CONTA_ID
WHERE INICIO_VIGENCIA = ( SELECT MAX(INICIO_VIGENCIA) FROM VAGAS_DW.CONTRATOS
							WHERE CONTA_ID = A.CONTA_ID  
							AND STATUS NOT IN ('vencido','rescindido') ) -- �LTIMO CONTRATO
AND STATUS NOT IN ('vencido','rescindido')

-- AJUSTAR CONTRATOS QUE FICARAM COMO �LT
UPDATE VAGAS_DW.CONTRATOS SET FLAG_ULT_CONTRATO = 0
FROM VAGAS_DW.CONTRATOS A
WHERE INICIO_VIGENCIA <> ( SELECT MAX(INICIO_VIGENCIA) FROM VAGAS_DW.CONTRATOS
							WHERE CONTA_ID = A.CONTA_ID
							AND STATUS NOT IN ('vencido','rescindido') ) -- �LTIMO CONTRATO
AND STATUS NOT IN ('vencido','rescindido')

UPDATE VAGAS_DW.CONTRATOS SET FLAG_ULT_CONTRATO = 0 WHERE FLAG_ULT_CONTRATO IS NULL

-- atualizar informa��es de BCE e BCC
UPDATE VAGAS_DW.CONTRATOS SET CAPACIDADE_BCE = B.CAPACIDADE_BCE ,
							  QTD_BCE = B.QTD_BCE,
							  QTD_EXTRACOES_BCC = B.QTD_EXTRACOES_BCC,
							  EX_CLIENTE = B.EX_CLIENTE,
							  PERFIL_CRM = B.PERFIL_CRM,
							  PERFIL_BCE = B.PERFIL_BCE
FROM VAGAS_DW.CONTRATOS A
INNER JOIN VAGAS_DW.CLIENTES B ON B.CLIENTE_VAGAS = A.CLIENTE_VAGAS
