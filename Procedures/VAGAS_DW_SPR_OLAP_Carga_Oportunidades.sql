USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_OPORTUNIDADES' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_OPORTUNIDADES
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW

-- Altera��es
-- 17/06/2016
-- Adicionado atualiza��o da coluna INDICE_IGPM para possibilitar cruzamento dos indicadores de renova��o de contratos
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_OPORTUNIDADES 
AS
SET NOCOUNT ON

-- Novo Cat�logo de produtos:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		COD_PRODUTO =	CASE
							WHEN A.PRODUTO IN ('FIT', 'VAGAS FIT ANUID', 'VAGAS FIT LIC', 'VAGAS FIT REV', 'VAGAS FIT EI')
								THEN 'FIT'
							WHEN A.PRODUTO IN ('CRED.VAGAS', 'VAGAS PONTUAL')
								THEN 'VAGAS PONTUAL'
							WHEN A.PRODUTO IN ('VETM', 'COMPL AVALIACAOM')
								THEN 'COMPL AVALIACAOM'
							WHEN A.PRODUTO IN ('VETP', 'COMPL AVALIACAOP')
								THEN 'COMPL AVALIACAOP'
							WHEN A.PRODUTO IN ('COMPL EBPORT', 'COMPL PORTAL')
								THEN 'COMPL PORTAL'
							WHEN A.PRODUTO IN ('SMS', 'COMPL SMSM', 'COMPL SMS')
								THEN 'COMPL SMS'
							WHEN A.PRODUTO IN ('PET', 'VAGAS PETM', 'VAGAS PETP')
								THEN 'VAGAS PETP'
							WHEN A.PRODUTO IN ('PUBL.ADNETWORK', 'PUBL ADNETWORK')
								THEN 'PUBL ADNETWORK'
							WHEN A.PRODUTO IN ('PUBL.BANNER', 'PUBL BANNER', 'PUBL.EDITORIAL')
								THEN 'PUBL BANNER'
							WHEN A.PRODUTO IN ('PUBL.MAILMKT', 'PUBL MAILMKT')
								THEN 'PUBL MAILMKT'
							WHEN A.PRODUTO IN ('PUBL.POST', 'PUBL POST')
								THEN 'PUBL POST'
							WHEN A.PRODUTO IN ('DSMCORT', 'SERV DSM CORTESIA')
								THEN 'SERV DSM CORTESIA'
							WHEN A.PRODUTO IN ('DSMFRANQ', 'SERV DSM FRANQUIA')
								THEN 'SERV DSM FRANQUIA'
							WHEN A.PRODUTO IN ('EI')
								THEN 'EI'
							WHEN A.PRODUTO IN ('REV')
								THEN 'REV'
							WHEN A.PRODUTO IN ('VREDES', 'VAGAS REDES')
								THEN 'VAGAS REDES'
							WHEN A.PRODUTO IN ('COMPL HOMEPAGE', 'COMPL HOMEPAGE')
								THEN 'COMPL HOMEPAGE'
							ELSE A.PRODUTO
						END
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A ;

-- Subir registros da tabela de oportunidades:
-- DROP TABLE #TMP_REGISTROS_CONTROLE ;
SELECT	*
INTO	#TMP_REGISTROS_CONTROLE
FROM	[VAGAS_DW].[OPORTUNIDADES] ;

-- TRUNCAR REGISTROS p/ subir sequencial:
TRUNCATE TABLE [VAGAS_DW].[OPORTUNIDADES] ;

-- Sequencial p/ produtos que se repetem em uma mesma proposta:
INSERT INTO [VAGAS_DW].[OPORTUNIDADES]
SELECT	
Conta, Categoria, Negocio, Perfil, ContaPAI, Oportunidade, Fase, OportunidadeCategoria, PropostaValor, DataCriacao, DataFechamento, Proprietario, Proposta, Produto, ValorProduto, Desconto, Quantidade, ValorProdutoFINAL, OportunidadeValor, PropostaPrincipal, DIAS_MEDIA, FIT, FECHADO_GANHO, REVISAO_FIT, ULTIMO_VALOR, PRODUTO_GRUPO, PESO_GRUPO, VALOR_REAL, CONTRIB, REVISAO_COM_VALOR_ANTERIOR, VALOR_POSIT, VALOR_NEGAT, GRUPO_VENDEDOR, PRODUTO_RECORRENCIA, RECORRENTE, PRODUTO_RECORRENTE, PROPOSTA_ID, VALOR_RANKING_CLIENTE, MESANO_FECHAMENTO, CLIENTE, OportunidadeID, PropostaID, ID_HSYS, REVISAO, LeadCampanha, ID_VAGAS, CONTAID, ContaValorPrincipal, ContaPropostaAprov, ContaProprietario, ContaValorPropAprov, FATURA_ERP, CNPJ, TIPO_CONTA, CriadorOportunidade, CONTEM_REDES, CONTEM_FIT, GRUPO_OPORTUNIDADE, ContaUsuarioAlteracao, DataAlteracaoConta, IGPM_MES, Campanha, POSSUI_CONTA_MEMBRO, CNAE_SECAO_ID, CNAE_SECAO, CNAE_DIVISAO_ID, CNAE_DIVISAO, CNAE_CLASSE_ID, CNAE_CLASSE, CNAE_FAIXA_FUNCIONARIOS, CNAE_SUBCLASSE_ID_C, CNAE_SUBCLASSE_DESCR_C, POSICOES_MES, TOTAL_UNIDADES, POSICOES_POR_UNIDADE, CONTEM_CREDITO_OFFLINE, ID_CONTATO, EMAIL_CONTATO, MOTIVO_FECHAMENTO, MOTIVO_FECHAMENTO_DETALHE, MOTIVO_CONCORRENTE, MOTIVO_PERFIL_ESPECIFICO, SEGMENTO_COMERC, INSERT_MANUAL, COD_PRODUTO
, CONCAT(COD_PRODUTO, ' ', ROW_NUMBER() OVER(PARTITION BY CONTA, OPORTUNIDADE, PROPOSTA, PRODUTO ORDER BY PRODUTO, VALORPRODUTO ASC)) AS CONTROLE_OPP_PROD, NULL AS SOMA_PRODUTOS_OPP,NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO
FROM	#TMP_REGISTROS_CONTROLE ;

-- var Prod /  Contr% 
UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_GRUPO = B.GRUPO,PESO_GRUPO = B.PESO
FROM VAGAS_DW.OPORTUNIDADES A
INNER JOIN VAGAS_DW.GRUPO_PRODUTOS B ON B.PRODUTO = A.PRODUTO

-- var �FechGan 
UPDATE VAGAS_DW.OPORTUNIDADES SET FECHADO_GANHO = CASE WHEN Fase = 'fechado_e_ganho' AND PropostaPrincipal = 1 THEN 1 ELSE 0 END

-- var �FGFit
-- UPDATE VAGAS_DW.OPORTUNIDADES SET FIT = CASE WHEN FECHADO_GANHO = 1 AND Produto = 'FIT' THEN 1 ELSE 0 END  
 UPDATE VAGAS_DW.OPORTUNIDADES SET FIT = CASE WHEN FECHADO_GANHO = 1 AND COD_PRODUTO = 'FIT' THEN 1 ELSE 0 END  

-- var �FGRevFit 
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO_FIT = CASE WHEN FIT = 1 AND OportunidadeCategoria IN ('renovacao','retencao','revisao_de_perfil') THEN 1 ELSE 0 END

-- var new �Rev
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO = 1 
WHERE OportunidadeCategoria IN ('renovacao','retencao','revisao_de_perfil','rescisao')

-- var Rec
UPDATE VAGAS_DW.OPORTUNIDADES SET RECORRENTE = CASE WHEN PRODUTO_RECORRENCIA = 'monthly' THEN 1 ELSE 0 END 

-- Ajuste de produtos que sa�ram na oportunidade do CRM, por�m o registro n�o foi feito:
-- DROP TABLE #TMP_REGISTROS
SELECT	A.Conta ,
		B.OPP_POS_ATUAL AS Oportunidade ,
		B.FASE_POS_ATUAL AS Fase ,
		B.OPP_CATEGORIA_POS_ATUAL AS OportunidadeCategoria ,
		B.OPP_DT_POS_ATUAL AS DataFechamento ,
		B.PROP_POS_ATUAL AS Proposta ,
		A.Produto ,
		0.00 AS ValorProdutoFINAL ,
		B.OPP_ID_POS_ATUAL AS OportunidadeID ,
		B.PROP_PRINCIP_POS_ATUAL AS PropostaPrincipal ,
		1 AS RECORRENTE ,
		B.PROP_DT_CRIACAO_POS_ATUAL AS DataCriacao ,
		B.OPP_PROD_POS_ATUAL AS ProdutoRecorrencia ,
		B.OPP_PROP_POS_ATUAL AS Proprietario,
		B.CAMP_OPP_POS_ATUAL AS Campanha ,
		B.CATEG_OPP_POST_ATUAL AS Categoria ,
		B.PROD_GRUP_POS_ATUAL AS PRODUTO_GRUPO ,
		B.GRUP_VEND_POS_ATUAL AS GRUPO_VENDEDOR ,
		B.ULT_VAL_POS_ATUAL AS ULTIMO_VALOR ,
		B.CONTA_ID_OPP_POS_ATUAL AS CONTAID ,
		B.PROP_VAL_POS_ATUAL AS PropostaValor ,
		B.NEG_VAL_POS_ATUAL AS Negocio ,
		B.VAL_PROD_POS_ATUAL AS ValorProduto ,
		B.PROP_ID_POS_ATUAL AS PropostaID ,
		'SIM' AS INSERT_MANUAL
INTO	#TMP_REGISTROS
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A		CROSS APPLY (SELECT	TOP 1 A1.OportunidadeID AS OPP_ID_POS_ATUAL ,
																	  A1.DataFechamento AS OPP_DT_POS_ATUAL ,
																	  A1.OPORTUNIDADE AS OPP_POS_ATUAL ,
																	  A1.Proposta AS PROP_POS_ATUAL ,
																	  A1.Fase AS FASE_POS_ATUAL ,
																	  A1.OportunidadeCategoria AS OPP_CATEGORIA_POS_ATUAL ,
																	  A1.PropostaPrincipal AS PROP_PRINCIP_POS_ATUAL ,
																	  A1.DataCriacao AS PROP_DT_CRIACAO_POS_ATUAL ,
																	  A1.PRODUTO_RECORRENCIA AS OPP_PROD_POS_ATUAL ,
																	  A1.Proprietario AS OPP_PROP_POS_ATUAL ,
																	  A1.Campanha AS CAMP_OPP_POS_ATUAL ,
																	  A1.Categoria AS CATEG_OPP_POST_ATUAL ,
																	  A1.PRODUTO_GRUPO AS PROD_GRUP_POS_ATUAL ,
																	  A1.PRODUTO_RECORRENCIA AS PROD_REC_POS_ATUAL ,
																	  A1.GRUPO_VENDEDOR AS GRUP_VEND_POS_ATUAL ,
																	  A1.ULTIMO_VALOR AS ULT_VAL_POS_ATUAL ,
																	  A1.CONTAID AS CONTA_ID_OPP_POS_ATUAL ,
																	  A1.PropostaValor AS PROP_VAL_POS_ATUAL ,
																	  A1.Negocio AS NEG_VAL_POS_ATUAL ,
																	  A1.ValorProduto AS VAL_PROD_POS_ATUAL ,
																	  A1.PropostaID AS PROP_ID_POS_ATUAL
														 FROM		  [VAGAS_DW].[OPORTUNIDADES] AS A1
														 WHERE		  A1.FASE = 'fechado_e_ganho'
																	  AND A1.RECORRENTE = 1
																	  AND A.CONTAID = A1.CONTAID
																	  AND A1.DataFechamento > A.DataFechamento
														 ORDER BY A1.DataFechamento ASC) AS B -- Pr�xima opp fechada_e_ganha, recorrente
											LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS D ON A.CONTAID = D.CONTAID
											AND B.OPP_ID_POS_ATUAL = D.OportunidadeID -- Oportunidade posterior a atual
											AND A.COD_PRODUTO = D.COD_PRODUTO -- Produto da oportunidade recorrente = produto da oportunidade posterior a atual
WHERE	A.FASE = 'fechado_e_ganho'
		AND A.RECORRENTE = 1
		AND D.COD_PRODUTO IS NULL -- Pr�xima oportunidade n�o contenha o produto da oportunidade anterior, produtos que existem na 1� opp, que n�o existem na 2� opp
ORDER BY
		A.CONTA ASC ,
		A.DataFechamento ASC ;

INSERT INTO [VAGAS_DW].[OPORTUNIDADES] (CONTA,OPORTUNIDADE,FASE,OPORTUNIDADECATEGORIA,DATAFECHAMENTO,PROPOSTA,PRODUTO,VALORPRODUTOFINAL,OPORTUNIDADEID,PropostaPrincipal, RECORRENTE,DATACRIACAO,PRODUTO_RECORRENCIA,Proprietario,Campanha,Categoria,PRODUTO_GRUPO,GRUPO_VENDEDOR,ULTIMO_VALOR,CONTAID,PropostaValor,Negocio,ValorProduto,PropostaID,INSERT_MANUAL)
SELECT *
FROM	#TMP_REGISTROS AS A
WHERE	A.OPORTUNIDADE NOT IN (/*'Drogaria Onofre 08',*/ 'Claro 04') ;

-- Novo Cat�logo de produtos:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		COD_PRODUTO =	CASE
							WHEN A.PRODUTO IN ('FIT', 'VAGAS FIT ANUID', 'VAGAS FIT LIC')
								THEN 'FIT'
							WHEN A.PRODUTO IN ('CRED.VAGAS', 'VAGAS PONTUAL')
								THEN 'VAGAS PONTUAL'
							WHEN A.PRODUTO IN ('VETM', 'COMPL AVALIACAOM')
								THEN 'COMPL AVALIACAOM'
							WHEN A.PRODUTO IN ('VETP', 'COMPL AVALIACAOP')
								THEN 'COMPL AVALIACAOP'
							WHEN A.PRODUTO IN ('COMPL EBPORT', 'COMPL PORTAL')
								THEN 'COMPL PORTAL'
							WHEN A.PRODUTO IN ('SMS', 'COMPL SMSM', 'COMPL SMS')
								THEN 'COMPL SMS'
							WHEN A.PRODUTO IN ('PET', 'VAGAS PETM', 'VAGAS PETP')
								THEN 'VAGAS PETP'
							WHEN A.PRODUTO IN ('PUBL.ADNETWORK', 'PUBL ADNETWORK')
								THEN 'PUBL ADNETWORK'
							WHEN A.PRODUTO IN ('PUBL.BANNER', 'PUBL BANNER', 'PUBL.EDITORIAL')
								THEN 'PUBL BANNER'
							WHEN A.PRODUTO IN ('PUBL.MAILMKT', 'PUBL MAILMKT')
								THEN 'PUBL MAILMKT'
							WHEN A.PRODUTO IN ('PUBL.POST', 'PUBL POST')
								THEN 'PUBL POST'
							WHEN A.PRODUTO IN ('DSMCORT', 'SERV DSM CORTESIA')
								THEN 'SERV DSM CORTESIA'
							WHEN A.PRODUTO IN ('DSMFRANQ', 'SERV DSM FRANQUIA')
								THEN 'SERV DSM FRANQUIA'
							WHEN A.PRODUTO IN ('EI', 'VAGAS FIT EI')
								THEN 'VAGAS FIT EI'
							WHEN A.PRODUTO IN ('REV')
								THEN 'REV'
							WHEN A.PRODUTO IN ('VREDES', 'VAGAS REDES')
								THEN 'VAGAS REDES'
							WHEN A.PRODUTO IN ('COMPL HOMEPAGE', 'COMPL HOMEPAGE')
								THEN 'COMPL HOMEPAGE'
							ELSE A.PRODUTO
						END
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A ;

-- Subir registros da tabela de oportunidades:
-- DROP TABLE #TMP_REGISTROS_CONTROLE_2 ;
SELECT	*
INTO	#TMP_REGISTROS_CONTROLE_2
FROM	[VAGAS_DW].[OPORTUNIDADES] ;

-- TRUNCAR REGISTROS p/ subir sequencial:
TRUNCATE TABLE [VAGAS_DW].[OPORTUNIDADES] ;

-- Sequencial p/ produtos que se repetem em uma mesma proposta:
INSERT INTO [VAGAS_DW].[OPORTUNIDADES]
SELECT	
Conta, Categoria, Negocio, Perfil, ContaPAI, Oportunidade, Fase, OportunidadeCategoria, PropostaValor, DataCriacao, DataFechamento, Proprietario, Proposta, Produto, ValorProduto, Desconto, Quantidade, ValorProdutoFINAL, OportunidadeValor, PropostaPrincipal, DIAS_MEDIA, FIT, FECHADO_GANHO, REVISAO_FIT, ULTIMO_VALOR, PRODUTO_GRUPO, PESO_GRUPO, VALOR_REAL, CONTRIB, REVISAO_COM_VALOR_ANTERIOR, VALOR_POSIT, VALOR_NEGAT, GRUPO_VENDEDOR, PRODUTO_RECORRENCIA, RECORRENTE, PRODUTO_RECORRENTE, PROPOSTA_ID, VALOR_RANKING_CLIENTE, MESANO_FECHAMENTO, CLIENTE, OportunidadeID, PropostaID, ID_HSYS, REVISAO, LeadCampanha, ID_VAGAS, CONTAID, ContaValorPrincipal, ContaPropostaAprov, ContaProprietario, ContaValorPropAprov, FATURA_ERP, CNPJ, TIPO_CONTA, CriadorOportunidade, CONTEM_REDES, CONTEM_FIT, GRUPO_OPORTUNIDADE, ContaUsuarioAlteracao, DataAlteracaoConta, IGPM_MES, Campanha, POSSUI_CONTA_MEMBRO, CNAE_SECAO_ID, CNAE_SECAO, CNAE_DIVISAO_ID, CNAE_DIVISAO, CNAE_CLASSE_ID, CNAE_CLASSE, CNAE_FAIXA_FUNCIONARIOS, CNAE_SUBCLASSE_ID_C, CNAE_SUBCLASSE_DESCR_C, POSICOES_MES, TOTAL_UNIDADES, POSICOES_POR_UNIDADE, CONTEM_CREDITO_OFFLINE, ID_CONTATO, EMAIL_CONTATO, MOTIVO_FECHAMENTO, MOTIVO_FECHAMENTO_DETALHE, MOTIVO_CONCORRENTE, MOTIVO_PERFIL_ESPECIFICO, SEGMENTO_COMERC, INSERT_MANUAL, COD_PRODUTO
, CONCAT(COD_PRODUTO, ' ', ROW_NUMBER() OVER(PARTITION BY CONTA, OPORTUNIDADE, PROPOSTA, PRODUTO ORDER BY PRODUTO, VALORPRODUTO ASC)) AS CONTROLE_OPP_PROD, 
 (SELECT SUM(A1.VALORPRODUTOFINAL) AS SOMA
  FROM	#TMP_REGISTROS_CONTROLE_2 AS A1
  WHERE	A.CONTAID = A1.CONTAID
		AND A.OportunidadeID =  A1.OportunidadeID
		AND A.PropostaID = A1.PropostaID
		AND A.COD_PRODUTO = A1.COD_PRODUTO ) AS SOMA,
NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO
FROM	#TMP_REGISTROS_CONTROLE_2 AS A ;

-- var Prod /  Contr% 
UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_GRUPO = B.GRUPO,PESO_GRUPO = B.PESO
FROM VAGAS_DW.OPORTUNIDADES A
INNER JOIN VAGAS_DW.GRUPO_PRODUTOS B ON B.PRODUTO = A.PRODUTO

-- var �FechGan 
UPDATE VAGAS_DW.OPORTUNIDADES SET FECHADO_GANHO = CASE WHEN Fase = 'fechado_e_ganho' AND PropostaPrincipal = 1 THEN 1 ELSE 0 END

-- var �FGFit  
-- UPDATE VAGAS_DW.OPORTUNIDADES SET FIT = CASE WHEN FECHADO_GANHO = 1 AND Produto = 'FIT' THEN 1 ELSE 0 END  
UPDATE VAGAS_DW.OPORTUNIDADES SET FIT = CASE WHEN FECHADO_GANHO = 1 AND COD_PRODUTO = 'FIT' THEN 1 ELSE 0 END

-- var �FGRevFit 
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO_FIT = CASE WHEN FIT = 1 AND OportunidadeCategoria IN ('renovacao','retencao','revisao_de_perfil') THEN 1 ELSE 0 END

-- var new �Rev
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO = 1 
WHERE OportunidadeCategoria IN ('renovacao','retencao','revisao_de_perfil','rescisao')

-- var Rec
UPDATE VAGAS_DW.OPORTUNIDADES SET RECORRENTE = CASE WHEN PRODUTO_RECORRENCIA = 'monthly' THEN 1 ELSE 0 END 

-- var  ValAntFit 
--UPDATE VAGAS_DW.OPORTUNIDADES SET ULTIMO_VALOR = ULT.ValorProdutoFINAL
--FROM VAGAS_DW.OPORTUNIDADES A
--OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES 
--			  WHERE FIT = 1
--			    AND PropostaPrincipal = 1
--				AND Conta = A.Conta
--				AND Fase = 'fechado_e_ganho'
--				AND (    ( DataFechamento < A.DataFechamento )
--					  OR ( DataFechamento = A.DataFechamento AND DataCriacao < A.DataCriacao ) )
--			  ORDER BY DataFechamento DESC,DataCriacao DESC) ULT
--WHERE A.FIT = 1

---- ALTERA��O LUIZ (17/11/2015 - Ultimo Valor para qualquer produto recorrente)
--UPDATE VAGAS_DW.OPORTUNIDADES SET ULTIMO_VALOR = ULT.ValorProdutoFINAL
--FROM VAGAS_DW.OPORTUNIDADES A
--OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES 
--			  WHERE COD_PRODUTO = A.COD_PRODUTO
--			   -- AND CONTROLE_OPP_PROD = A.CONTROLE_OPP_PROD
--			    AND PropostaPrincipal = 1
--				AND Conta = A.Conta
--				AND RECORRENTE = 1
--				AND Fase = 'fechado_e_ganho'
--				AND (    ( DataFechamento < A.DataFechamento )
--					  OR ( DataFechamento = A.DataFechamento AND DataCriacao < A.DataCriacao ) )
--			  ORDER BY DataFechamento DESC,DataCriacao DESC) ULT
--WHERE A.RECORRENTE = 1 -- apenas produtos recorrentes

-- ALTERA��O FIAMA (25/04/2018 - Ultimo Valor para qualquer produto recorrente)
UPDATE VAGAS_DW.OPORTUNIDADES SET ULTIMO_VALOR = ULT.SOMA_PRODUTOS_OPP
FROM VAGAS_DW.OPORTUNIDADES A
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES 
			  WHERE COD_PRODUTO = A.COD_PRODUTO
			    AND PropostaPrincipal = 1
				AND Conta = A.Conta
				AND RECORRENTE = 1
				AND Fase = 'fechado_e_ganho'
				AND (    ( DataFechamento < A.DataFechamento )
					  OR ( DataFechamento = A.DataFechamento AND DataCriacao < A.DataCriacao ) )
			  ORDER BY DataFechamento DESC,DataCriacao DESC) ULT
WHERE A.RECORRENTE = 1 -- apenas produtos recorrentes


-- atualiza��o "Grupo Votorantim" (segmenta��o de conta) [processo acordado com Tati Pires e Baraza]
UPDATE VAGAS_DW.OPORTUNIDADES SET ULTIMO_VALOR = 10738.30
FROM VAGAS_DW.OPORTUNIDADES 
WHERE Oportunidade = 'Votorantim 04'

-- var �RevFitRev 
--UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO_COM_VALOR_ANTERIOR = CASE WHEN REVISAO_FIT = 1 
																    --AND ULTIMO_VALOR IS NOT NULL AND ULTIMO_VALOR <> 0 THEN 1 ELSE 0 END 

-- ALTERA��O LUIZ (17/11/2015 - marcar qualquer um com revis�o)
UPDATE VAGAS_DW.OPORTUNIDADES SET REVISAO_COM_VALOR_ANTERIOR = CASE WHEN REVISAO = 1 
																    AND ULTIMO_VALOR IS NOT NULL AND ULTIMO_VALOR <> 0 THEN 1 ELSE 0 END 

---- var  ValorReal  
--UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_REAL = CASE WHEN REVISAO_COM_VALOR_ANTERIOR = 1 
--													THEN ValorProdutoFINAL - ULTIMO_VALOR
--													ELSE CASE WHEN ISNULL(ValorProdutoFINAL,0) > 0 THEN ValorProdutoFINAL ELSE 0 END
--													END

-- ALTERA��O FIAMA 25/04/2018
-- var  ValorReal  
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_REAL = CASE WHEN REVISAO_COM_VALOR_ANTERIOR = 1 
													THEN SOMA_PRODUTOS_OPP - ULTIMO_VALOR
													ELSE CASE WHEN ISNULL(SOMA_PRODUTOS_OPP,0) > 0 THEN SOMA_PRODUTOS_OPP ELSE 0 END
													END
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A
WHERE	SUBSTRING(REVERSE(A.CONTROLE_OPP_PROD), 1, CHARINDEX(' ', REVERSE(A.CONTROLE_OPP_PROD))) = 
									( SELECT MAX(SUBSTRING(REVERSE(A1.CONTROLE_OPP_PROD), 1, CHARINDEX(' ', REVERSE(A1.CONTROLE_OPP_PROD))))
									  FROM	[VAGAS_DW].[OPORTUNIDADES] AS A1
									  WHERE	A.CONTAID = A1.CONTAID
											AND A.OPORTUNIDADEID = A1.OPORTUNIDADEID
											AND A.PRODUTO = A1.PRODUTO )

-- var  ValPos 
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_POSIT = CASE WHEN VALOR_REAL >= 0 THEN VALOR_REAL ELSE 0 END

-- var ValNeg
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_NEGAT = VALOR_REAL - VALOR_POSIT 


-- var  ProdRec 
--UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_RECORRENTE = CASE WHEN Produto = 'FIT' /*FIT = 1 */ AND RECORRENTE = 1 THEN
--															CASE WHEN REVISAO_COM_VALOR_ANTERIOR = 1 THEN 'FIT-REV' 
--																  ELSE 'FIT-NOV' END
--														ELSE PRODUTO_GRUPO END

-- ALTERA��O LUIZ (17/11/2015 - marcar qualquer produto recorrente)
--UPDATE VAGAS_DW.OPORTUNIDADES SET PRODUTO_RECORRENTE = CASE WHEN RECORRENTE = 1 THEN
--															CASE WHEN REVISAO_COM_VALOR_ANTERIOR = 1 THEN PRODUTO_GRUPO + '-REV' 
--																  ELSE PRODUTO_GRUPO + '-NOV' END
--														ELSE PRODUTO_GRUPO END

-- ALTERA��O LUIZ (07/03/2016 - marcar qualquer produto recorrente)
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

-- Agrupamento do FIT e REDES para possibilitar an�lises em conjunto
UPDATE VAGAS_DW.OPORTUNIDADES SET CONTEM_FIT = CASE WHEN TAB_FIT.PRODUTO_GRUPO = 'FIT' OR A.PRODUTO_GRUPO = 'FIT' THEN 1 ELSE 0 END ,
	   CONTEM_REDES = CASE WHEN TAB_REDES.PRODUTO_GRUPO = 'VREDES' OR A.PRODUTO_GRUPO = 'VREDES' THEN 1 ELSE 0 END 
FROM VAGAS_DW.OPORTUNIDADES A
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			  WHERE OportunidadeID = A.OportunidadeID
			  AND PRODUTO_GRUPO = 'VREDES'
			  AND PRODUTO_GRUPO <> A.PRODUTO_GRUPO ) TAB_REDES
OUTER APPLY ( SELECT TOP 1 * FROM VAGAS_DW.OPORTUNIDADES
			  WHERE OportunidadeID = A.OportunidadeID
			  AND PRODUTO_GRUPO = 'FIT'
			  AND PRODUTO_GRUPO <> A.PRODUTO_GRUPO ) TAB_FIT
WHERE A.RECORRENTE = 1
--AND A.Fase = 'fechado_e_ganho' 
--AND A.PRODUTO_GRUPO IN ('VREDES','FIT')

-- ajuste de inconsistencia em Out/15 (aguardar Marina com carga das rescis�es que faltaram para remover este trecho_
UPDATE VAGAS_DW.OPORTUNIDADES SET MESANO_FECHAMENTO = '20151001',DATAFECHAMENTO = '20151001', VALOR_REAL = -6000,PRODUTO_RECORRENTE = 'FIT-REV',VALOR_NEGAT = -6000,OPORTUNIDADECATEGORIA = 'parceiro',FECHADO_GANHO = 1
FROM VAGAS_DW.OPORTUNIDADES 
WHERE Conta = 'Ficticia'

-- Altera��o solicitada pela Mari (22/04/2016) para cria��o de campo "AgrupamentoOportunidade" 
UPDATE VAGAS_DW.OPORTUNIDADES SET GRUPO_OPORTUNIDADE = CASE 
			WHEN OPORTUNIDADECATEGORIA = 'rescisao' THEN 'Rescis�es'  
			WHEN OPORTUNIDADECATEGORIA = 'cliente_potencial' THEN 'Novos'
			WHEN OPORTUNIDADECATEGORIA = 'produtos_complementares' 
				 OR PRODUTO_RECORRENTE IN ('FIT-REV-POS','PROD COMP-NOV','VET-NOV') THEN 'Rev Positiva'
			WHEN OPORTUNIDADECATEGORIA = 'renovacao' THEN 'Renova��es'
			WHEN OPORTUNIDADECATEGORIA = 'retencao' 
				 OR PRODUTO_RECORRENTE IN ('FIT-REV-NEG') THEN 'Rev Negativa'
			END
FROM VAGAS_DW.OPORTUNIDADES 
WHERE RECORRENTE = 1 

-- Atualiza��o no caso que est�o com o ID_VAGAS = ""
UPDATE VAGAS_DW.OPORTUNIDADES SET ID_VAGAS = CONTA
FROM VAGAS_DW.OPORTUNIDADES
WHERE RTRIM(LTRIM(ID_VAGAS)) = '' 

-- ATUALIZAR DATA DE FECHAMENTO DAS OPORTUNIDADES DE RENOVA��O QUE FORAM INCLU�DAS NO M�S ERRADO
--UPDATE VAGAS_DW.OPORTUNIDADES SET DATAFECHAMENTO = CONVERT(SMALLDATETIME,RIGHT([M�S],4) + SUBSTRING([M�S],4,2) + LEFT([M�S],2)) 
--FROM VAGAS_DW.OPORTUNIDADES A
--INNER JOIN VAGAS_DW.TMP_CONTRATOS_DATA_FECHAMENTO_20160701 B ON B.CNPJ = A.CNPJ
--WHERE A.OPORTUNIDADECATEGORIA = 'renovacao'
--AND DATAFECHAMENTO = ( SELECT MAX(DATAFECHAMENTO) FROM VAGAS_DW.OPORTUNIDADES 
--						WHERE CONTA = A.CONTA
--						AND OPORTUNIDADECATEGORIA = 'renovacao'
--						AND Fase = 'fechado_e_ganho' )
--AND MONTH(CONVERT(SMALLDATETIME,RIGHT([M�S],4) + SUBSTRING([M�S],4,2) + LEFT([M�S],2))) <> MONTH(DATAFECHAMENTO )
--AND NOT EXISTS ( SELECT 1 FROM VAGAS_DW.OPORTUNIDADES 
--				 WHERE CONTA = A.CONTA
--				 AND OPORTUNIDADECATEGORIA = 'revisao_de_perfil'
--				 AND DATAFECHAMENTO > A.DATAFECHAMENTO
--				 AND Fase = 'fechado_e_ganho' )
--AND A.Categoria = 'cliente_fit'
--AND A.Fase = 'fechado_e_ganho'

-- adicionado em 17/06/2016 (para relat�rio de renova��es de contratos)
UPDATE VAGAS_DW.OPORTUNIDADES SET IGPM_MES = B.INDICE_ACUM_12_MESES_IGPM
FROM VAGAS_DW.OPORTUNIDADES A
INNER JOIN VAGAS_DW.INDICADORES_ECONOMICOS_MENSAL B ON DATEADD(MONTH,-1,A.DATAFECHAMENTO) >= B.DATA 
													AND DATEADD(MONTH,-1,A.DATAFECHAMENTO) < DATEADD(MONTH,1,B.DATA)
WHERE OPORTUNIDADECATEGORIA = 'renovacao' 
AND FECHADO_GANHO = 1 
AND IGPM_MES IS NULL

-- Controle para sabermos se a oportunidade est� atrelada � um cr�dito que foi vendido "online" (via pagseguro)
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

-- 20170403 BRAZ: ATUALIZA��O NA OPORTUNIDADE DA DROGARIA ONOFRE CONFORME ORIENTA��O DO COMERCIAL [PABLO]
-- NA VERDADE HOUVE UMA "MIGRA��O DE PRODUTO" POR ISSO A ATUALIZA��O
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_REAL = 0,VALOR_NEGAT = -3990.96 
FROM VAGAS_DW.OPORTUNIDADES 
WHERE OPORTUNIDADE = 'Drogaria Onofre 08'

-- 20170522: ATUALIZA��O NA CLARO CONFORME ORIENTA��O DO COMERCIAL [E-MAIL PABLO]
-- OBS PABLO: Foi necess�rio cadastrar essa opt para realiza��o de tramites contratuais, mas na pr�tica n�o foi gerada receita adicional - valor real deve ser zero.
UPDATE VAGAS_DW.OPORTUNIDADES SET VALOR_REAL = 0
FROM VAGAS_DW.OPORTUNIDADES 
WHERE OPORTUNIDADE = 'Claro 04'

-- PROCESSO DE "CONGELAMENTO" PARA IDENTIFICARMOS INCONSIST�NCIAS QUE POSSAM OCORRER NO PE
-- GRAVAMOS AT� O DIA 06 DE CADA M�S
DECLARE @DATA_REFERENCIA SMALLDATETIME
SET @DATA_REFERENCIA = CONVERT(SMALLDATETIME, CONVERT(VARCHAR,GETDATE(),112))


-- Ajustes do GRUPO_VENDEDOR:
EXEC [VAGAS_DW].[SPR_OLAP_Carga_Oportunidades_Ajustes_GRUPO_VENDEDOR] ;


-- Negocia��es que comp�em o MRR:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		NEGOCIACAO_MRR = CASE
							WHEN A.OportunidadeCategoria IN ('cliente_potencial','cliente_cotacao')
							AND A.RECORRENTE = 1
								THEN 'NOVO'
							WHEN A.OportunidadeCategoria IN ('revisao_de_perfil','retencao')
							AND A.VALOR_REAL >= 0
							AND A.RECORRENTE = 1
								THEN 'UPSELL'
							WHEN A.OportunidadeCategoria IN ('revisao_de_perfil','retencao')
							AND A.VALOR_REAL < 0
							AND A.RECORRENTE = 1
								THEN 'DOWNSELL'
							WHEN A.OportunidadeCategoria IN ('rescisao')
							AND A.RECORRENTE = 1
								THEN 'CHURN'
							WHEN A.OportunidadeCategoria IN ('venda_pontual','projeto')
							AND A.PRODUTO_GRUPO IN ('DSM', 'PROD COMP')
							AND A.RECORRENTE = 0
								THEN 'CROSS SELL'
							WHEN A.OportunidadeCategoria = 'renovacao'
							AND A.RECORRENTE = 1
								THEN 'RENEWAL'
							ELSE NULL
						END
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A ;


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
Campanha,POSSUI_CONTA_MEMBRO,DATA_REFERENCIA,INSERT_MANUAL,NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO)
	SELECT Conta,Categoria,Negocio,Perfil,ContaPAI,Oportunidade,Fase,OportunidadeCategoria,PropostaValor,DataCriacao,DataFechamento,
Proprietario,Proposta,Produto,ValorProduto,Desconto,Quantidade,ValorProdutoFINAL,OportunidadeValor,PropostaPrincipal,DIAS_MEDIA,
FIT,FECHADO_GANHO,REVISAO_FIT,ULTIMO_VALOR,PRODUTO_GRUPO,PESO_GRUPO,VALOR_REAL,CONTRIB,REVISAO_COM_VALOR_ANTERIOR,VALOR_POSIT,
VALOR_NEGAT,GRUPO_VENDEDOR,PRODUTO_RECORRENCIA,RECORRENTE,PRODUTO_RECORRENTE,PROPOSTA_ID,VALOR_RANKING_CLIENTE,MESANO_FECHAMENTO,
CLIENTE,OportunidadeID,PropostaID,ID_HSYS,REVISAO,LeadCampanha,ID_VAGAS,CONTAID,ContaValorPrincipal,ContaPropostaAprov,ContaProprietario,
ContaValorPropAprov,FATURA_ERP,CNPJ,TIPO_CONTA,CriadorOportunidade,CONTEM_REDES,CONTEM_FIT,GRUPO_OPORTUNIDADE,ContaUsuarioAlteracao,
DataAlteracaoConta,IGPM_MES,Campanha,POSSUI_CONTA_MEMBRO,
@DATA_REFERENCIA AS DATA_REFERENCIA,INSERT_MANUAL,NEGOCIACAO_MRR,DATA_PROPOSTA,DATA_AVALIACAO_PROPOSTA,DATA_CONTRATO FROM VAGAS_DW.OPORTUNIDADES
END