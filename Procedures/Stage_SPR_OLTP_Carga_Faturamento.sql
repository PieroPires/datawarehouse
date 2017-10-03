-- select * from vagas_dw.TMP_CANDIDATOS
-- EXEC VAGAS_DW.SPR_OLTP_Carga_Faturamento '19010101'
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Faturamento' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Faturamento
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Faturamento 
@DT_CARGA_INICIO SMALLDATETIME ,
@DT_CARGA_FIM SMALLDATETIME = NULL

AS
SET NOCOUNT ON

IF @DT_CARGA_INICIO IS NULL
SET @DT_CARGA_INICIO = '19010101'

-- SSIS passa neste formato quando NULO
IF @DT_CARGA_FIM < '19010101' 
SET @DT_CARGA_FIM = '20700101'

TRUNCATE TABLE VAGAS_DW.TMP_FATURAMENTO

INSERT INTO VAGAS_DW.TMP_FATURAMENTO
SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataDeEmissão,112)) AS DATA_EMISSAO,
	   D.Produto AS PRODUTO,
	   E.StatusDeProduto AS STATUS_PRODUTO,
	   C.IdCliente AS CLIENTE,	
	   F.Classe AS TIPO_CLIENTE,
	   C.[RAZÃOSOCIAL] AS RAZAO_SOCIAL,
	   G.NomeCompleto AS RESPONSAVEL,
	   H.Interesse AS INTERESSE,
	   I.TipoDePedido AS TIPO_PEDIDO,
	   L.[StatusDeCobrança] AS STATUS_COBRANCA,
	   L.Pago AS FLAG_PAGO,
	   M.Cod_cli AS COD_CLI_VAGAS,
		SUM(CAST([Quantidade] * CASE WHEN [ExecSimultâneas]=0 THEN 1 
								 ELSE [ExecSimultâneas] END * 
								 [PreçoUnitário] AS DECIMAL(10,2))) AS PRECO_TOTAL 
  FROM HSYS.dbo.Pedidos A
 INNER JOIN HSYS.DBO.LinhaDePedido B ON B.IdPedido = A.IdPedido
 INNER JOIN HSYS.dbo.Clientes C ON C.IdCliente = A.IdClienteComprador
 INNER JOIN HSYS.dbo.Produtos D ON D.IdProduto = B.IdProduto
 INNER JOIN HSYS.DBO.StatusDeProdutos E ON E.IdStatusDeProduto = D.IdStatusDeProduto
 INNER JOIN HSYS.DBO.[Tipos de Cliente] F ON F.IdClasse = C.IdClasse
 OUTER APPLY ( SELECT TOP 1 * FROM HSYS.DBO.Pessoas	
				WHERE IdCliente = C.IdCliente
				ORDER BY DataAtualização DESC ) G
 OUTER APPLY ( SELECT TOP 1 * FROM HSYS.DBO.[Tipos de Interesse] 
				WHERE IDInteresse = G.IdInteresse
				ORDER BY 1 ASC ) H
 INNER JOIN HSYS.DBO.[TiposDePedidos] I ON I.IdTipoDePedido = A.IdTipoDePedido
 OUTER APPLY ( SELECT TOP 1 * FROM HSYS.DBO.Boletos
				WHERE [Id Pedido] = A.IdPedido 
				ORDER BY [Emissão] DESC ) J
 LEFT OUTER JOIN HSYS.DBO.[TiposDeStatusDeCobrança] L ON L.[IdStatusDeCobrança] = J.StatusCobrança
 LEFT OUTER JOIN HSYS.DBO.[ClientesXClientes_IDVAGAS] M ON M.IdCliente = C.IdCliente
 WHERE B.Quantidade > 0
   --AND A.DataDeEmissão >= '20150101' AND A.DataDeEmissão < '20150901'
 GROUP BY  CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataDeEmissão,112)),
	   D.Produto ,
	   E.StatusDeProduto ,
	   C.IdCliente ,	
	   F.Classe ,
	   C.[RAZÃOSOCIAL] ,
	   G.NomeCompleto ,
	   H.Interesse ,
	   I.TipoDePedido ,
	   L.[StatusDeCobrança] ,
	   L.Pago ,
	   M.Cod_cli
 ORDER BY DATA_EMISSAO DESC,PRECO_TOTAL DESC