USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Extracoes_BCC' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Extracoes_BCC
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Extracoes_BCC @COD_PEDIDO INT = NULL

AS
SET NOCOUNT ON

IF @COD_PEDIDO = 0
SET @COD_PEDIDO = NULL

TRUNCATE TABLE VAGAS_DW.TMP_EXTRACOES_BCC

INSERT INTO VAGAS_DW.TMP_EXTRACOES_BCC
SELECT COD_PEDIDO,CODCLIENTE_PEDIDO AS COD_CLI,DT_PEDIDO,QTDECUR_PEDIDO AS QTD_CVS
FROM [hrh-data].dbo.Pedidos A
WHERE COD_PEDIDO > @COD_PEDIDO OR @COD_PEDIDO IS NULL


