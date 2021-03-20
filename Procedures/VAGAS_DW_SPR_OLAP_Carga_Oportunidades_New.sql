USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_OPORTUNIDADES' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_OPORTUNIDADES
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW

-- Alterações
-- 17/06/2016
-- Adicionado atualização da coluna INDICE_IGPM para possibilitar cruzamento dos indicadores de renovação de contratos
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_OPORTUNIDADES 
AS
SET NOCOUNT ON

-- Regulariza as oportunidades seguintes que não estão com o produto da oportunidade anterior:
EXEC [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Prod_Opp_Anterior] ;


-- Atualiza o campo COD_PRODUTO (Catálogo de produtos do CRM):
EXEC [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Catalogo_Produtos] ;


-- var Prod /  Contr% 
UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_GRUPO = B.GRUPO,PESO_GRUPO = B.PESO
FROM VAGAS_DW.OPORTUNIDADES A
INNER JOIN VAGAS_DW.GRUPO_PRODUTOS B ON B.PRODUTO = A.PRODUTO

-- var ÉFechGan 
UPDATE VAGAS_DW.OPORTUNIDADES SET FECHADO_GANHO = CASE WHEN Fase = 'fechado_e_ganho' AND PropostaPrincipal = 1 THEN 1 ELSE 0 END

-- var ÉFGFit
 UPDATE VAGAS_DW.OPORTUNIDADES SET FIT = CASE WHEN FECHADO_GANHO = 1 AND COD_PRODUTO = 'FIT' THEN 1 ELSE 0 END  

-- var ÉFGRevFit 
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO_FIT = CASE WHEN FIT = 1 AND OportunidadeCategoria IN ('renovacao','retencao','revisao_de_perfil') AND NOT (OportunidadeCategoria = 'retencao' AND Fase = 'fechado_e_perdido' AND DataFechamento >= '20210101') THEN 1 ELSE 0 END

-- var new ÉRev
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO = 1 
WHERE OportunidadeCategoria IN ('renovacao','retencao','revisao_de_perfil','rescisao') OR (OportunidadeCategoria = 'retencao' AND Fase = 'fechado_e_perdido' AND DataFechamento >= '20210101')

-- var Rec
UPDATE VAGAS_DW.OPORTUNIDADES SET RECORRENTE = CASE WHEN PRODUTO_RECORRENCIA IN ('monthly', 'annually') THEN 1 ELSE 0 END 


-- Carrega o CONTROLE_OPP_PROD e SOMA_PRODUTOS_OPP:
-- DROP TABLE #TMP_REGISTROS_CONTROLE ;
SELECT	*
INTO	#TMP_REGISTROS_CONTROLE
FROM	[VAGAS_DW].[OPORTUNIDADES] ;

TRUNCATE TABLE [VAGAS_DW].[OPORTUNIDADES] ;

INSERT INTO [VAGAS_DW].[OPORTUNIDADES]
SELECT	
Conta, Categoria, Negocio, Perfil, ContaPAI, Oportunidade, Fase, OportunidadeCategoria, PropostaValor, DataCriacao, DataFechamento, Proprietario, Proposta, Produto, ValorProduto, Desconto, Quantidade, ValorProdutoFINAL, OportunidadeValor, PropostaPrincipal, DIAS_MEDIA, FIT, FECHADO_GANHO, REVISAO_FIT, ULTIMO_VALOR, PRODUTO_GRUPO, PESO_GRUPO, VALOR_REAL, CONTRIB, REVISAO_COM_VALOR_ANTERIOR, VALOR_POSIT, VALOR_NEGAT, GRUPO_VENDEDOR, PRODUTO_RECORRENCIA, RECORRENTE, PRODUTO_RECORRENTE, PROPOSTA_ID, VALOR_RANKING_CLIENTE, MESANO_FECHAMENTO, CLIENTE, OportunidadeID, PropostaID, ID_HSYS, REVISAO, LeadCampanha, ID_VAGAS, CONTAID, ContaValorPrincipal, ContaPropostaAprov, ContaProprietario, ContaValorPropAprov, FATURA_ERP, CNPJ, TIPO_CONTA, CriadorOportunidade, CONTEM_REDES, CONTEM_FIT, GRUPO_OPORTUNIDADE, ContaUsuarioAlteracao, DataAlteracaoConta, IGPM_MES, Campanha, POSSUI_CONTA_MEMBRO, CNAE_SECAO_ID, CNAE_SECAO, CNAE_DIVISAO_ID, CNAE_DIVISAO, CNAE_CLASSE_ID, CNAE_CLASSE, CNAE_FAIXA_FUNCIONARIOS, CNAE_SUBCLASSE_ID_C, CNAE_SUBCLASSE_DESCR_C, POSICOES_MES, TOTAL_UNIDADES, POSICOES_POR_UNIDADE, CONTEM_CREDITO_OFFLINE, ID_CONTATO, EMAIL_CONTATO, MOTIVO_FECHAMENTO, MOTIVO_FECHAMENTO_DETALHE, MOTIVO_CONCORRENTE, MOTIVO_PERFIL_ESPECIFICO, SEGMENTO_COMERC, INSERT_MANUAL, COD_PRODUTO
, CONCAT(COD_PRODUTO, ' ', ROW_NUMBER() OVER(PARTITION BY ContaID, OportunidadeID, PropostaID, COD_PRODUTO ORDER BY PRODUTO, VALORPRODUTO ASC)) AS CONTROLE_OPP_PROD,  
(SELECT SUM(A1.VALORPRODUTOFINAL) AS SOMA
  FROM	#TMP_REGISTROS_CONTROLE AS A1
  WHERE	A.CONTAID = A1.CONTAID
		AND A.OportunidadeID =  A1.OportunidadeID
		AND A.PropostaID = A1.PropostaID
		AND A.COD_PRODUTO = A1.COD_PRODUTO
		AND A1.RECORRENTE = 1) AS SOMA_PRODUTOS_OPP,NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO,PLANO
FROM	#TMP_REGISTROS_CONTROLE AS A
WHERE	A.RECORRENTE = 1
		AND A.PRODUTO IS NOT NULL
UNION ALL
SELECT	
Conta, Categoria, Negocio, Perfil, ContaPAI, Oportunidade, Fase, OportunidadeCategoria, PropostaValor, DataCriacao, DataFechamento, Proprietario, Proposta, Produto, ValorProduto, Desconto, Quantidade, ValorProdutoFINAL, OportunidadeValor, PropostaPrincipal, DIAS_MEDIA, FIT, FECHADO_GANHO, REVISAO_FIT, ULTIMO_VALOR, PRODUTO_GRUPO, PESO_GRUPO, VALOR_REAL, CONTRIB, REVISAO_COM_VALOR_ANTERIOR, VALOR_POSIT, VALOR_NEGAT, GRUPO_VENDEDOR, PRODUTO_RECORRENCIA, RECORRENTE, PRODUTO_RECORRENTE, PROPOSTA_ID, VALOR_RANKING_CLIENTE, MESANO_FECHAMENTO, CLIENTE, OportunidadeID, PropostaID, ID_HSYS, REVISAO, LeadCampanha, ID_VAGAS, CONTAID, ContaValorPrincipal, ContaPropostaAprov, ContaProprietario, ContaValorPropAprov, FATURA_ERP, CNPJ, TIPO_CONTA, CriadorOportunidade, CONTEM_REDES, CONTEM_FIT, GRUPO_OPORTUNIDADE, ContaUsuarioAlteracao, DataAlteracaoConta, IGPM_MES, Campanha, POSSUI_CONTA_MEMBRO, CNAE_SECAO_ID, CNAE_SECAO, CNAE_DIVISAO_ID, CNAE_DIVISAO, CNAE_CLASSE_ID, CNAE_CLASSE, CNAE_FAIXA_FUNCIONARIOS, CNAE_SUBCLASSE_ID_C, CNAE_SUBCLASSE_DESCR_C, POSICOES_MES, TOTAL_UNIDADES, POSICOES_POR_UNIDADE, CONTEM_CREDITO_OFFLINE, ID_CONTATO, EMAIL_CONTATO, MOTIVO_FECHAMENTO, MOTIVO_FECHAMENTO_DETALHE, MOTIVO_CONCORRENTE, MOTIVO_PERFIL_ESPECIFICO, SEGMENTO_COMERC, INSERT_MANUAL, COD_PRODUTO
, NULL AS CONTROLE_OPP_PROD,  NULL AS SOMA_PRODUTOS_OPP,NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO,PLANO
FROM	#TMP_REGISTROS_CONTROLE AS Opp
WHERE	Opp.RECORRENTE = 0
		OR Opp.PRODUTO IS NULL ;


-- DROP TABLE #Tab_Opp ;
SELECT	A.OportunidadeID,
		A.Oportunidade,
		A.COD_PRODUTO,
		CASE
			WHEN A.OportunidadeCategoria IN ('cliente_potencial','renovacao','rescisao','retencao','revisao_de_perfil','cliente_cotacao')
				AND NOT (ISNULL(Inf_Opp_Anterior.Oportunidade, '') = '')
				THEN ISNULL(Inf_Opp_Anterior.SOMA_PRODUTOS_OPP, 0)
			WHEN A.OportunidadeCategoria IN ('rescisao', 'renovacao')
					AND ULT_OPP.Campanha = 'COVID-19'
				THEN Info_UltOpp_Anterior_PrimOpp_Covid.SOMA_PRODUTOS_OPP
			ELSE ISNULL(ULT.SOMA_PRODUTOS_OPP, 0)
		END AS ULTIMO_VALOR,
		--Inf_Opp_Anterior.OportunidadeID AS Opp1,
		--Info_UltOpp_Anterior_PrimOpp_Covid.OportunidadeID AS Opp2,
		--ULT.OportunidadeID AS Opp3
		IIF((A.OportunidadeCategoria = 'cliente_potencial' 
			 OR A.OportunidadeCategoria = 'renovacao' 
			 OR A.OportunidadeCategoria = 'rescisao' 
			 OR A.OportunidadeCategoria = 'retencao' 
			 OR A.OportunidadeCategoria = 'revisao_de_perfil' 
			 OR A.OportunidadeCategoria = 'cliente_cotacao')
			AND ISNULL(Inf_Opp_Anterior.Oportunidade, '') <> '', 
			Inf_Opp_Anterior.OportunidadeID, NULL) AS Opp1,
		IIF((A.OportunidadeCategoria = 'rescisao'
			 OR A.OportunidadeCategoria = 'renovacao')
			AND ULT_OPP.Campanha = 'COVID-19',	Info_UltOpp_Anterior_PrimOpp_Covid.OportunidadeID, NULL) AS Opp2,
		IIF((A.OportunidadeCategoria = 'cliente_potencial' 
			 OR A.OportunidadeCategoria = 'renovacao' 
			 OR A.OportunidadeCategoria = 'rescisao' 
			 OR A.OportunidadeCategoria = 'retencao' 
			 OR A.OportunidadeCategoria = 'revisao_de_perfil' 
			 OR A.OportunidadeCategoria = 'cliente_cotacao')
			AND ISNULL(Inf_Opp_Anterior.Oportunidade, '') <> '', Inf_Opp_Anterior.OportunidadeID, 
			IIF((A.OportunidadeCategoria = 'rescisao'
				 OR A.OportunidadeCategoria = 'renovacao')
				AND ULT_OPP.Campanha = 'COVID-19',	Info_UltOpp_Anterior_PrimOpp_Covid.OportunidadeID, ULT.OportunidadeID)) AS Opp3
INTO	#Tab_Opp
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			  WHERE CONTAID = A.CONTAID
					AND RECORRENTE = 1
					AND Fase = 'fechado_e_ganho'
					AND ((DataFechamento < A.DataFechamento ) 
						   OR (DataFechamento = A.DataFechamento AND DataCriacao < A.DataCriacao))
					AND INSERT_MANUAL IS NULL
			  ORDER BY DataFechamento DESC,DataCriacao DESC) ULT_OPP -- Última oportunidade fechada e ganha anterior a atual pela data de fechamento, ou criação
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			  WHERE COD_PRODUTO = A.COD_PRODUTO
				AND CONTAID = A.CONTAID
				AND RECORRENTE = 1
				AND Fase = 'fechado_e_ganho'
				AND (    ( DataFechamento < A.DataFechamento ) 
					  OR ( DataFechamento = A.DataFechamento AND DataCriacao < A.DataCriacao ) )
				AND INSERT_MANUAL IS NULL
				AND OportunidadeID = ULT_OPP.OportunidadeID
			  ORDER BY DataFechamento DESC,DataCriacao DESC) ULT -- Última oportunidade anterior a atual com o mesmo código de produto
LEFT OUTER JOIN OPENQUERY(MYSQLPROVIDER, 'SELECT	id_c AS OportunidadeID,
													opportunity_id_c AS OportunidadeID_Anterior
										  FROM		sugarcrm.opportunities_cstm		INNER JOIN sugarcrm.opportunities ON opportunity_id_c = id
										  WHERE		deleted = 0') AS Opp_Anterior
ON A.OportunidadeID = Opp_Anterior.OportunidadeID COLLATE SQL_Latin1_General_CP1_CI_AI
LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS Inf_Opp_Anterior
ON Opp_Anterior.OportunidadeID_Anterior = Inf_Opp_Anterior.OportunidadeID  COLLATE SQL_Latin1_General_CP1_CI_AI
AND Inf_Opp_Anterior.RECORRENTE = 1
AND Inf_Opp_Anterior.INSERT_MANUAL IS NULL
AND A.COD_PRODUTO = Inf_Opp_Anterior.COD_PRODUTO
OUTER APPLY (SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			 WHERE	A.CONTAID = CONTAID
					AND RECORRENTE = 1
					AND Fase = 'fechado_e_ganho'
					AND Campanha = 'COVID-19'
					AND INSERT_MANUAL IS NULL
			  ORDER BY
					DataFechamento ASC, DataCriacao ASC) AS PrimOpp_Covid --> 1ª Oportunidade com Campanha = COVID-19
OUTER APPLY (SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			 WHERE	A.CONTAID = CONTAID
					AND RECORRENTE = 1
					AND Fase = 'fechado_e_ganho'
					AND INSERT_MANUAL IS NULL
					AND (DataFechamento < PrimOpp_Covid.DataFechamento)
					AND OportunidadeCategoria IN ('cliente_potencial','renovacao','rescisao','retencao','revisao_de_perfil','cliente_cotacao')
			  ORDER BY
					DataFechamento DESC, DataCriacao DESC) AS UltOpp_Anterior_PrimOpp_Covid  -- Oportunidade recorrente mais recente anterior a 1ª oportunidade covid
LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS Info_UltOpp_Anterior_PrimOpp_Covid
ON UltOpp_Anterior_PrimOpp_Covid.OportunidadeID = Info_UltOpp_Anterior_PrimOpp_Covid.OportunidadeID
AND Info_UltOpp_Anterior_PrimOpp_Covid.RECORRENTE = 1
AND Info_UltOpp_Anterior_PrimOpp_Covid.INSERT_MANUAL IS NULL
AND A.COD_PRODUTO = Info_UltOpp_Anterior_PrimOpp_Covid.COD_PRODUTO
LEFT OUTER JOIN OPENQUERY(MYSQLPROVIDER, 'SELECT	id_c AS OportunidadeID,
													diferenca_recorrente_c AS Diferenca_Recorrente_CRM
										  FROM		opportunities_cstm') AS Opp_DifRec
ON A.OportunidadeID = Opp_DifRec.OportunidadeID COLLATE SQL_Latin1_General_CP1_CI_AI
WHERE	((A.Fase = 'fechado_e_ganho' AND A.RECORRENTE = 1) 
		 OR (A.Fase = 'fechado_e_perdido' AND A.RECORRENTE = 1 AND A.OportunidadeCategoria = 'retencao' AND A.DataFechamento >= '20210101')) ;

-- DROP TABLE #Tab_UltOpp ;
SELECT	Opp.OportunidadeID AS OppAtual,
		COALESCE(OppRegra1.Opp1, OppRegra2.Opp2, OppRegra3.Opp3) AS UltOpp
INTO	#Tab_UltOpp
FROM	#Tab_Opp AS Opp	   OUTER APPLY (SELECT TOP 1 *
										FROM	#Tab_Opp AS Opp_A1
										WHERE	Opp.OportunidadeID = Opp_A1.OportunidadeID
												AND Opp_A1.Opp1 IS NOT NULL) AS OppRegra1
						   OUTER APPLY (SELECT TOP 1 *
										FROM	#Tab_Opp AS Opp_A2
										WHERE	Opp.OportunidadeID = Opp_A2.OportunidadeID
												AND Opp_A2.Opp2 IS NOT NULL) AS OppRegra2
						  OUTER APPLY (SELECT TOP 1 *
										FROM	#Tab_Opp AS Opp_A3
										WHERE	Opp.OportunidadeID = Opp_A3.OportunidadeID
												AND Opp_A3.Opp3 IS NOT NULL) AS OppRegra3 ;

-- DROP TABLE #Tab_UltOppVal ;
SELECT	DISTINCT Opp.OportunidadeID,
		Opp_UltOpp.UltOpp,
		Opp.COD_PRODUTO,
		ISNULL(Val_Prod_UltOpp.SOMA_PRODUTOS_OPP, 0) AS ULTIMO_VALOR
INTO	#Tab_UltOppVal
FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp		INNER JOIN #Tab_UltOpp AS Opp_UltOpp ON Opp.OportunidadeID = Opp_UltOpp.OppAtual
												OUTER APPLY (SELECT TOP 1 *
															 FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp_A1
															 WHERE	Opp_UltOpp.UltOpp = Opp_A1.OportunidadeID
																	AND Opp_A1.RECORRENTE = 1
																	AND Opp_A1.INSERT_MANUAL IS NULL
																	AND Opp.COD_PRODUTO = Opp_A1.COD_PRODUTO
															 ORDER BY
																	Opp_A1.DataFechamento DESC) AS Val_Prod_UltOpp ;



UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		ULTIMO_VALOR = Opp_UltValor.ULTIMO_VALOR
FROM	#Tab_UltOppVal AS Opp_UltValor		INNER JOIN [VAGAS_DW].[OPORTUNIDADES] AS Opp
													ON Opp_UltValor.OportunidadeID = Opp.OportunidadeID
													AND Opp_UltValor.COD_PRODUTO = Opp.COD_PRODUTO
WHERE	((Opp.Fase = 'fechado_e_ganho' AND Opp.RECORRENTE = 1)
		 OR (Opp.Fase = 'fechado_e_perdido' AND Opp.RECORRENTE = 1 AND Opp.OportunidadeCategoria = 'retencao' AND Opp.DataFechamento >= '20210101'))


-- atualização "Grupo Votorantim" (segmentação de conta) [processo acordado com Tati Pires e Baraza]
UPDATE VAGAS_DW.OPORTUNIDADES SET ULTIMO_VALOR = 10738.30
FROM VAGAS_DW.OPORTUNIDADES 
WHERE Oportunidade = 'Votorantim 04'


-- ALTERAÇÃO LUIZ (17/11/2015 - marcar qualquer um com revisão)
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO_COM_VALOR_ANTERIOR = CASE WHEN REVISAO = 1 AND ISNULL(ULTIMO_VALOR, 0) <> 0 THEN 1 ELSE 0	END 

-- var  ValorReal  
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_REAL =	ISNULL(SOMA_PRODUTOS_OPP ,0) - ISNULL(ULTIMO_VALOR , 0)
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A
WHERE	SUBSTRING(REVERSE(A.CONTROLE_OPP_PROD), 1, CHARINDEX(' ', REVERSE(A.CONTROLE_OPP_PROD))) = 
									( SELECT MAX(SUBSTRING(REVERSE(A1.CONTROLE_OPP_PROD), 1, CHARINDEX(' ', REVERSE(A1.CONTROLE_OPP_PROD))))
									  FROM	[VAGAS_DW].[OPORTUNIDADES] AS A1
									  WHERE	A.CONTAID = A1.CONTAID
											AND A.OPORTUNIDADEID = A1.OPORTUNIDADEID
											AND A.COD_PRODUTO = A1.COD_PRODUTO )
		AND ((A.Fase = 'fechado_e_ganho' AND A.RECORRENTE = 1)
			 OR (A.Fase = 'fechado_e_perdido' AND A.RECORRENTE = 1 AND A.OportunidadeCategoria = 'retencao' AND DataFechamento >= '20210101')) ;

-- ValorReal pra Rec = 0
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		VALOR_REAL = ISNULL(Opp.ValorProdutoFINAL, 0)
FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp
WHERE	Opp.Fase = 'fechado_e_ganho'
		AND Opp.RECORRENTE = 0 ;


-- Higienização pra efeitos de cálculos:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		VALOR_REAL = ISNULL(Opp.ValorProdutoFINAL, 0)
FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp
WHERE	VALOR_REAL IS NULL
		AND NOT (Opp.Fase = 'fechado_e_ganho'
				 AND Opp.RECORRENTE = 1) ;

-- Atualiza linhas de oportunidade recorrente:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		VALOR_REAL = 0
FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp
WHERE	VALOR_REAL IS NULL
		AND Opp.Fase = 'fechado_e_ganho'
		AND Opp.RECORRENTE = 1 ;



-- var  ValPos 
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_POSIT = CASE WHEN VALOR_REAL >= 0 THEN VALOR_REAL ELSE 0 END

-- var ValNeg
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_NEGAT = VALOR_REAL - VALOR_POSIT 


-- var  ProdRec 
--UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_RECORRENTE = CASE WHEN Produto = 'FIT' /*FIT = 1 */ AND RECORRENTE = 1 THEN
--															CASE WHEN REVISAO_COM_VALOR_ANTERIOR = 1 THEN 'FIT-REV' 
--																  ELSE 'FIT-NOV' END
--														ELSE PRODUTO_GRUPO END

-- ALTERAÇÃO LUIZ (17/11/2015 - marcar qualquer produto recorrente)
--UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_RECORRENTE = CASE WHEN RECORRENTE = 1 THEN
--															CASE WHEN REVISAO_COM_VALOR_ANTERIOR = 1 THEN PRODUTO_GRUPO + '-REV' 
--																  ELSE PRODUTO_GRUPO + '-NOV' END
--														ELSE PRODUTO_GRUPO END

-- ALTERAÇÃO LUIZ (07/03/2016 - marcar qualquer produto recorrente)
UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_RECORRENTE = CASE WHEN RECORRENTE = 1 THEN
															CASE WHEN REVISAO_COM_VALOR_ANTERIOR = 1 THEN
																  CASE WHEN VALOR_REAL > 0 THEN PRODUTO_GRUPO + '-REV-POS'
																	   WHEN VALOR_REAL < 0 THEN PRODUTO_GRUPO + '-REV-NEG'
																	   ELSE PRODUTO_GRUPO + '-REV' END 
																  ELSE PRODUTO_GRUPO + '-NOV' END
														ELSE PRODUTO_GRUPO END


-- var   Contrib 
UPDATE VAGAS_DW.OPORTUNIDADES SET CONTRIB = CASE WHEN RECORRENTE = 1 THEN 12 ELSE 1 END *
												 PESO_GRUPO * VALOR_REAL

-- var Cliente
UPDATE VAGAS_DW.OPORTUNIDADES SET CLIENTE = CASE WHEN ContaPAI IS NULL OR ContaPAI = '' THEN Conta 
												 ELSE ContaPAI END

-- var  ValRankCli 
UPDATE 	VAGAS_DW.OPORTUNIDADES SET VALOR_RANKING_CLIENTE = CASE WHEN RECORRENTE = 1 THEN VALOR_REAL
																ELSE CASE WHEN DATAFECHAMENTO >= DATEADD(DAY,-365,GETDATE()) 
																		  THEN VALOR_REAL / 12
																		  ELSE 0 END
																		  END
-- var  MesAnoFech 
UPDATE VAGAS_DW.OPORTUNIDADES SET MESANO_FECHAMENTO = (DataFechamento - DAY(DataFechamento) + 1) 

-- var Dias																
UPDATE VAGAS_DW.OPORTUNIDADES SET DIAS_MEDIA = CASE WHEN DATEDIFF(DAY,DataCriacao,DataFechamento) < 0 THEN 0 ELSE DATEDIFF(DAY,DataCriacao,DataFechamento) END 
										
-- var Grupo
UPDATE VAGAS_DW.OPORTUNIDADES SET GRUPO_VENDEDOR = B.GRUPO_VENDEDOR
FROM VAGAS_DW.OPORTUNIDADES A
INNER JOIN VAGAS_DW.GRUPO_VENDEDORES B ON B.VENDEDOR = A.PROPRIETARIO
WHERE	A.FASE NOT IN ('fechado_e_ganho', 'fechado_e_perdido')

-- Agrupamento do FIT e REDES para possibilitar análises em conjunto
UPDATE VAGAS_DW.OPORTUNIDADES SET CONTEM_FIT = CASE WHEN TAB_FIT.PRODUTO_GRUPO = 'FIT' OR A.PRODUTO_GRUPO = 'FIT' THEN 1 ELSE 0 END ,
	   CONTEM_REDES = CASE WHEN TAB_REDES.PRODUTO_GRUPO = 'REDES' OR A.PRODUTO_GRUPO = 'REDES' THEN 1 ELSE 0 END 
FROM VAGAS_DW.OPORTUNIDADES A
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			  WHERE OportunidadeID = A.OportunidadeID
			  AND PRODUTO_GRUPO = 'REDES'
			  AND PRODUTO_GRUPO <> A.PRODUTO_GRUPO ) TAB_REDES
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			  WHERE OportunidadeID = A.OportunidadeID
			  AND PRODUTO_GRUPO = 'FIT'
			  AND PRODUTO_GRUPO <> A.PRODUTO_GRUPO ) TAB_FIT
WHERE A.RECORRENTE = 1
--AND A.Fase = 'fechado_e_ganho' 
--AND A.PRODUTO_GRUPO IN ('VREDES','FIT')

-- ajuste de inconsistencia em Out/15 (aguardar Marina com carga das rescisões que faltaram para remover este trecho_
UPDATE VAGAS_DW.OPORTUNIDADES SET MESANO_FECHAMENTO = '20151001',DATAFECHAMENTO = '20151001', VALOR_REAL = -6000,PRODUTO_RECORRENTE = 'FIT-REV',VALOR_NEGAT = -6000,OPORTUNIDADECATEGORIA = 'parceiro',FECHADO_GANHO = 1
FROM VAGAS_DW.OPORTUNIDADES 
WHERE Conta = 'Ficticia'

-- Alteração solicitada pela Mari (22/04/2016) para criação de campo "AgrupamentoOportunidade" 
UPDATE VAGAS_DW.OPORTUNIDADES SET GRUPO_OPORTUNIDADE = CASE 
			WHEN OPORTUNIDADECATEGORIA = 'rescisao' OR (OportunidadeCategoria = 'retencao' AND Fase = 'fechado_e_perdido' AND DataFechamento >= '20210101') THEN 'Rescisões'  
			WHEN OPORTUNIDADECATEGORIA = 'cliente_potencial' THEN 'Novos'
			WHEN OPORTUNIDADECATEGORIA = 'produtos_complementares' 
				 OR PRODUTO_RECORRENTE IN ('FIT-REV-POS','PROD COMP-NOV','VET-NOV') THEN 'Rev Positiva'
			WHEN OPORTUNIDADECATEGORIA = 'renovacao' THEN 'Renovações'
			WHEN OPORTUNIDADECATEGORIA = 'retencao' 
				 OR PRODUTO_RECORRENTE IN ('FIT-REV-NEG') THEN 'Rev Negativa'
			END
FROM VAGAS_DW.OPORTUNIDADES 
WHERE RECORRENTE = 1 

-- Atualização no caso que estão com o ID_VAGAS = ""
UPDATE VAGAS_DW.OPORTUNIDADES SET ID_VAGAS = CONTA
FROM VAGAS_DW.OPORTUNIDADES
WHERE RTRIM(LTRIM(ID_VAGAS)) = '' 

-- ATUALIZAR DATA DE FECHAMENTO DAS OPORTUNIDADES DE RENOVAÇÃO QUE FORAM INCLUÍDAS NO MÊS ERRADO
--UPDATE VAGAS_DW.OPORTUNIDADES SET DATAFECHAMENTO = CONVERT(SMALLDATETIME,RIGHT([MÊS],4) + SUBSTRING([MÊS],4,2) + LEFT([MÊS],2)) 
--FROM VAGAS_DW.OPORTUNIDADES A
--INNER JOIN VAGAS_DW.TMP_CONTRATOS_DATA_FECHAMENTO_20160701 B ON B.CNPJ = A.CNPJ
--WHERE A.OPORTUNIDADECATEGORIA = 'renovacao'
--AND DATAFECHAMENTO = ( SELECT MAX(DATAFECHAMENTO) FROM VAGAS_DW.OPORTUNIDADES 
--						WHERE CONTA = A.CONTA
--						AND OPORTUNIDADECATEGORIA = 'renovacao'
--						AND Fase = 'fechado_e_ganho' )
--AND MONTH(CONVERT(SMALLDATETIME,RIGHT([MÊS],4) + SUBSTRING([MÊS],4,2) + LEFT([MÊS],2))) <> MONTH(DATAFECHAMENTO )
--AND NOT EXISTS ( SELECT 1 FROM VAGAS_DW.OPORTUNIDADES 
--				 WHERE CONTA = A.CONTA
--				 AND OPORTUNIDADECATEGORIA = 'revisao_de_perfil'
--				 AND DATAFECHAMENTO > A.DATAFECHAMENTO
--				 AND Fase = 'fechado_e_ganho' )
--AND A.Categoria = 'cliente_fit'
--AND A.Fase = 'fechado_e_ganho'

-- adicionado em 17/06/2016 (para relatório de renovações de contratos)
UPDATE VAGAS_DW.OPORTUNIDADES SET IGPM_MES = B.INDICE_ACUM_12_MESES_IGPM
FROM VAGAS_DW.OPORTUNIDADES A
INNER JOIN VAGAS_DW.INDICADORES_ECONOMICOS_MENSAL B ON DATEADD(MONTH,-1,A.DATAFECHAMENTO) >= B.DATA 
													AND DATEADD(MONTH,-1,A.DATAFECHAMENTO) < DATEADD(MONTH,1,B.DATA)
WHERE OPORTUNIDADECATEGORIA = 'renovacao' 
AND FECHADO_GANHO = 1 
AND IGPM_MES IS NULL

-- Controle para sabermos se a oportunidade está atrelada à um crédito que foi vendido "online" (via pagseguro)
UPDATE VAGAS_DW.OPORTUNIDADES SET CONTEM_CREDITO_OFFLINE = 1
FROM VAGAS_DW.OPORTUNIDADES A
WHERE OportunidadeCategoria = 'venda_pontual' 
AND Produto IN ('CRED.VAGAS' , 'VAGAS PONTUAL')
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.CREDITOS_VAGAS
				 WHERE ID_OPORTUNIDADE = A.OPORTUNIDADEID )

-- EMAIL DO CONTATO
UPDATE VAGAS_DW.OPORTUNIDADES SET EMAIL_CONTATO = B.EMAIL
FROM VAGAS_DW.OPORTUNIDADES A
INNER JOIN VAGAS_DW.CONTATOS_CRM B ON B.COD_CONTATO = A.ID_CONTATO


-- LIMPEZA DOS CAMPOS DE MOTIVO FECHAMENTO
UPDATE VAGAS_DW.OPORTUNIDADES SET MOTIVO_PERFIL_ESPECIFICO = NULL
WHERE MOTIVO_PERFIL_ESPECIFICO = '^^' OR MOTIVO_PERFIL_ESPECIFICO = ''

UPDATE VAGAS_DW.OPORTUNIDADES SET MOTIVO_PERFIL_ESPECIFICO = LTRIM(RTRIM(REPLACE(MOTIVO_PERFIL_ESPECIFICO,'^',' ')))
WHERE MOTIVO_PERFIL_ESPECIFICO IS NOT NULL

UPDATE VAGAS_DW.OPORTUNIDADES SET MOTIVO_FECHAMENTO = NULL
WHERE MOTIVO_FECHAMENTO = ''

UPDATE VAGAS_DW.OPORTUNIDADES SET MOTIVO_FECHAMENTO_DETALHE = NULL
WHERE MOTIVO_FECHAMENTO_DETALHE = ''

UPDATE VAGAS_DW.OPORTUNIDADES SET MOTIVO_CONCORRENTE = NULL
WHERE MOTIVO_CONCORRENTE = ''

-- 20170403 BRAZ: ATUALIZAÇÃO NA OPORTUNIDADE DA DROGARIA ONOFRE CONFORME ORIENTAÇÃO DO COMERCIAL [PABLO]
-- NA VERDADE HOUVE UMA "MIGRAÇÃO DE PRODUTO" POR ISSO A ATUALIZAÇÃO
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_REAL = 0,VALOR_NEGAT = -3990.96 
FROM VAGAS_DW.OPORTUNIDADES 
WHERE OPORTUNIDADE = 'Drogaria Onofre 08'

-- 20170522: ATUALIZAÇÃO NA CLARO CONFORME ORIENTAÇÃO DO COMERCIAL [E-MAIL PABLO]
-- OBS PABLO: Foi necessário cadastrar essa opt para realização de tramites contratuais, mas na prática não foi gerada receita adicional - valor real deve ser zero.
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_REAL = 0
FROM VAGAS_DW.OPORTUNIDADES 
WHERE OPORTUNIDADE = 'Claro 04'

-- PROCESSO DE "CONGELAMENTO" PARA IDENTIFICARMOS INCONSISTÊNCIAS QUE POSSAM OCORRER NO PE
-- GRAVAMOS ATÉ O DIA 06 DE CADA MÊS
DECLARE @DATA_REFERENCIA SMALLDATETIME
SET @DATA_REFERENCIA = CONVERT(SMALLDATETIME, CONVERT(VARCHAR,GETDATE(),112))


-- Ajustes do GRUPO_VENDEDOR:
EXEC [VAGAS_DW].[SPR_OLAP_Carga_Oportunidades_Ajustes_GRUPO_VENDEDOR] ;

-- Negociações que compõem o MRR:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		NEGOCIACAO_MRR = CASE
							WHEN ((A.OportunidadeCategoria IN ('rescisao'))
								 OR (A.OportunidadeCategoria = 'retencao'
									 AND A.Fase = 'fechado_e_perdido'
									 AND A.DataFechamento >= '20210101'))
							AND A.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
								THEN 'CHURN'
							WHEN A.OportunidadeCategoria IN ('cliente_potencial','cliente_cotacao')
							AND A.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
								THEN 'NOVO'
							WHEN A.OportunidadeCategoria IN ('revisao_de_perfil','retencao')
							AND A.VALOR_REAL >= 0
							AND A.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
								THEN 'UPSELL'
							WHEN A.OportunidadeCategoria IN ('revisao_de_perfil','retencao')
							AND A.VALOR_REAL < 0
							AND A.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
								THEN 'DOWNSELL'
							WHEN A.OportunidadeCategoria IN ('venda_pontual','projeto')
							--AND A.PRODUTO_GRUPO IN ('DSM', 'PROD COMP')
							AND A.RECORRENTE = 0
								THEN 'CROSS SELL'
							WHEN A.OportunidadeCategoria = 'renovacao'
							AND A.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
								THEN 'RENEWAL'
							WHEN A.fase = 'fechado_e_ganho'
								AND A.RECORRENTE = 0
								AND EXISTS (SELECT *
											FROM	[vagas_dw].[OPORTUNIDADES] AS Opp_A1
											WHERE	A.OportunidadeID = Opp_A1.OportunidadeID
													AND Opp_A1.OportunidadeCategoria IN ('cliente_potencial','cliente_cotacao')
													AND Opp_A1.PRODUTO_RECORRENCIA IN ('monthly', 'annually'))
								THEN 'IMPLANTAÇÃO DE NOVO CLIENTE'
							ELSE NULL
						END
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A
WHERE	A.Produto IS NOT NULL ;


-- Plano da conta (adicionado no dia 02/03/2021):
-- ID da conta e Grupo do Produto classificado como "Plano" na tabela GRUPO_PRODUTOS:
DROP TABLE IF EXISTS  #UltOpp_Conta_GrupoProdRec ;

SELECT	DISTINCT ContasCRM.CONTA_ID,
		Opp.PRODUTO_GRUPO
INTO	#UltOpp_Conta_GrupoProdRec
FROM	(
			SELECT	CONTA_ID
			FROM	[VAGAS_DW].[CONTAS_CRM] AS Cnt
			UNION ALL
			SELECT	CONTA_ID
			FROM	[VAGAS_DW].[CONTAS_MEMBRO_CRM] AS Cnt) AS ContasCRM				OUTER APPLY (SELECT TOP 1 *
																					     FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp_A1
																						 WHERE	ContasCRM.CONTA_ID = Opp_A1.CONTAID
																								AND Opp_A1.RECORRENTE = 1
																								--AND Opp_A1.Fase = 'fechado_e_ganho'
																								AND Opp_A1.INSERT_MANUAL IS NULL
																						 ORDER BY
																								Opp_a1.DataFechamento DESC) AS UltOpp_Rec
																			INNER JOIN [VAGAS_DW].[OPORTUNIDADES] AS Opp
																			ON UltOpp_Rec.OportunidadeID = Opp.OportunidadeID
																			AND Opp.RECORRENTE = 1
																			AND Opp.INSERT_MANUAL IS NULL
																			INNER JOIN [VAGAS_DW].[GRUPO_PRODUTOS] AS GrupoProd
																			ON Opp.PRODUTO_GRUPO = GrupoProd.GRUPO
																			AND GrupoProd.PLANO_GRUPO = 1 ;

-- Plano da conta no CRM (fazaer update direto na tabela de oportunidades):
DROP TABLE IF EXISTS #Opp_Plano ;

SELECT	CONTA_ID,
		STRING_AGG(PRODUTO_GRUPO, ' / ') WITHIN GROUP (ORDER BY PRODUTO_GRUPO ASC) AS Plano
INTO	#Opp_Plano
FROM	#UltOpp_Conta_GrupoProdRec
GROUP BY
		CONTA_ID ;

UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		PLANO = Opp_Plano.Plano
FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp		INNER JOIN #Opp_Plano AS Opp_Plano
												ON Opp.CONTAID = Opp_Plano.CONTA_ID ;


IF DAY(@DATA_REFERENCIA) < 7
BEGIN
	-- LIMPAMOS OS DADOS PARA MANTER O ULTIMO
	DELETE VAGAS_DW.OPORTUNIDADES_HISTORICO 
	FROM VAGAS_DW.OPORTUNIDADES_HISTORICO 
	WHERE MONTH(DATA_REFERENCIA) = MONTH(@DATA_REFERENCIA)
	AND YEAR(DATA_REFERENCIA) = YEAR(@DATA_REFERENCIA)

	INSERT INTO VAGAS_DW.OPORTUNIDADES_HISTORICO (Conta,Categoria,Negocio,Perfil,ContaPAI,Oportunidade,Fase,OportunidadeCategoria,
PropostaValor,DataCriacao,DataFechamento,Proprietario,Proposta,Produto,ValorProduto,Desconto,Quantidade,ValorProdutoFINAL,
OportunidadeValor,PropostaPrincipal,DIAS_MEDIA,FIT,FECHADO_GANHO,REVISAO_FIT,ULTIMO_VALOR,PRODUTO_GRUPO,PESO_GRUPO,
VALOR_REAL,CONTRIB,REVISAO_COM_VALOR_ANTERIOR,VALOR_POSIT,VALOR_NEGAT,GRUPO_VENDEDOR,PRODUTO_RECORRENCIA,
RECORRENTE,PRODUTO_RECORRENTE,PROPOSTA_ID,VALOR_RANKING_CLIENTE,MESANO_FECHAMENTO,CLIENTE,OportunidadeID,
PropostaID,ID_HSYS,REVISAO,LeadCampanha,ID_VAGAS,CONTAID,ContaValorPrincipal,ContaPropostaAprov,
ContaProprietario,ContaValorPropAprov,FATURA_ERP,CNPJ,TIPO_CONTA,CriadorOportunidade,CONTEM_REDES,CONTEM_FIT,
GRUPO_OPORTUNIDADE,ContaUsuarioAlteracao,DataAlteracaoConta,IGPM_MES,
Campanha,POSSUI_CONTA_MEMBRO,DATA_REFERENCIA,INSERT_MANUAL,NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO,PLANO)
	SELECT Conta,Categoria,Negocio,Perfil,ContaPAI,Oportunidade,Fase,OportunidadeCategoria,PropostaValor,DataCriacao,DataFechamento,
Proprietario,Proposta,Produto,ValorProduto,Desconto,Quantidade,ValorProdutoFINAL,OportunidadeValor,PropostaPrincipal,DIAS_MEDIA,
FIT,FECHADO_GANHO,REVISAO_FIT,ULTIMO_VALOR,PRODUTO_GRUPO,PESO_GRUPO,VALOR_REAL,CONTRIB,REVISAO_COM_VALOR_ANTERIOR,VALOR_POSIT,
VALOR_NEGAT,GRUPO_VENDEDOR,PRODUTO_RECORRENCIA,RECORRENTE,PRODUTO_RECORRENTE,PROPOSTA_ID,VALOR_RANKING_CLIENTE,MESANO_FECHAMENTO,
CLIENTE,OportunidadeID,PropostaID,ID_HSYS,REVISAO,LeadCampanha,ID_VAGAS,CONTAID,ContaValorPrincipal,ContaPropostaAprov,ContaProprietario,
ContaValorPropAprov,FATURA_ERP,CNPJ,TIPO_CONTA,CriadorOportunidade,CONTEM_REDES,CONTEM_FIT,GRUPO_OPORTUNIDADE,ContaUsuarioAlteracao,
DataAlteracaoConta,IGPM_MES,Campanha,POSSUI_CONTA_MEMBRO,
@DATA_REFERENCIA AS DATA_REFERENCIA,INSERT_MANUAL,NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO,PLANO FROM VAGAS_DW.OPORTUNIDADES
END

CREATE NONCLUSTERED INDEX IDX_OPORTUNIDADES_CONTAID ON VAGAS_DW.OPORTUNIDADES (CONTAID)