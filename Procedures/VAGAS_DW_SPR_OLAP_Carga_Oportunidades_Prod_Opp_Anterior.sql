-- =============================================
-- Author: Fiama
-- Create date: 18/11/2020
-- Description: Insere produto recorrente da Oportunidade anterior que não existe na oportunidade recorrente seguinte.
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Prod_Opp_Anterior' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Prod_Opp_Anterior]
GO

CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Prod_Opp_Anterior]
AS
SET NOCOUNT ON 

-- Oportunidades com oportunidade anterior carimbada no CRM:
SELECT	*  
INTO	#OppCarimbo
FROM OPENQUERY(MYSQLPROVIDER, 'SELECT	id_c AS OportunidadeID,
										opportunity_id_c AS OportunidadeID_Anterior,
										opp_anterior.name AS Oportunidade
								FROM		sugarcrm.opportunities_cstm		INNER JOIN sugarcrm.opportunities
																		ON id_c = id
																		INNER JOIN sugarcrm.opportunities AS opp_anterior
																		ON opportunity_id_c = opp_anterior.id
								WHERE		opp_anterior.deleted = 0' ) AS Opp_Anterior ;



-- Insere registros inexistentes na oportunidade seguinte a oportunidade carimbada no CRM:
INSERT INTO [VAGAS_DW].[OPORTUNIDADES] (CONTA,OPORTUNIDADE,FASE,OPORTUNIDADECATEGORIA,DATAFECHAMENTO,PROPOSTA,PRODUTO,VALORPRODUTOFINAL,OPORTUNIDADEID,PropostaPrincipal, RECORRENTE,DATACRIACAO,PRODUTO_RECORRENCIA,Proprietario,Campanha,Categoria,PRODUTO_GRUPO,GRUPO_VENDEDOR,ULTIMO_VALOR,CONTAID,PropostaValor,Negocio,ValorProduto,PropostaID,INSERT_MANUAL)
SELECT	DISTINCT Opp_Anterior.Conta ,
		Opp_Prox.Oportunidade ,
		Opp_Prox.Fase ,
		Opp_Prox.OportunidadeCategoria ,
		Opp_Prox.DataFechamento ,
		Opp_Prox.Proposta ,
		Opp_Anterior.Produto ,
		0.00 AS ValorProdutoFINAL ,
		Opp_Prox.OportunidadeID ,
		Opp_Prox.PropostaPrincipal ,
		1 AS RECORRENTE ,
		Opp_Prox.DataCriacao ,
		Opp_Prox.PRODUTO_RECORRENCIA ,
		Opp_Prox.Proprietario,
		Opp_Prox.Campanha ,
		Opp_Prox.Categoria ,
		NULL AS PRODUTO_GRUPO ,
		Opp_Prox.GRUPO_VENDEDOR ,
		NULL AS ULTIMO_VALOR ,
		Opp_Prox.CONTAID ,
		Opp_Prox.PropostaValor ,
		Opp_Prox.Negocio ,
		0.00 AS ValorProduto ,
		Opp_Prox.PropostaID ,
		'SIM' AS INSERT_MANUAL
FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp_Anterior		INNER JOIN #OppCarimbo AS Rel_OppAnterior_Prox
														ON Opp_Anterior.OportunidadeID = Rel_OppAnterior_Prox.OportunidadeID_Anterior COLLATE SQL_Latin1_General_CP1_CI_AI
														LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS Opp_Prox
														ON Rel_OppAnterior_Prox.OportunidadeID = Opp_Prox.OportunidadeID COLLATE SQL_Latin1_General_CP1_CI_AI
														AND Opp_Prox.PRODUTO_RECORRENCIA IN ('monthly', 'annually') -- Dados da próxima opp (carimbada) com prod rec
														AND Opp_prox.Fase = 'fechado_e_ganho'
WHERE	NOT EXISTS (SELECT *
					FROM	#OppCarimbo AS Opp_A1	LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS Opp_Prox_A1
													ON Opp_A1.OportunidadeID = Opp_Prox_A1.OportunidadeID COLLATE SQL_Latin1_General_CP1_CI_AI
													AND Opp_Prox_A1.PRODUTO_RECORRENCIA IN ('monthly', 'annually') -- Dados da próxima opp (carimbada) com prod rec
					WHERE	Opp_Anterior.OportunidadeID = Opp_A1.OportunidadeID_Anterior COLLATE SQL_Latin1_General_CP1_CI_AI
							AND Opp_Anterior.Produto = Opp_Prox_A1.Produto
							AND Opp_Prox_A1.Fase = 'fechado_e_ganho')		
		AND Opp_Anterior.Fase = 'fechado_e_ganho'
		AND Opp_Anterior.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
		AND Opp_Prox.OportunidadeID IS NOT NULL
ORDER BY
		Opp_Prox.Oportunidade,
		Opp_Anterior.Produto ;

-- Insere produto recorrente da Oportunidade anterior que não existe na Oportunidade recorrente seguinte (Oportunidade recorrente é a que possui no mínimo 1 produto recorrente):
INSERT INTO [VAGAS_DW].[OPORTUNIDADES] (CONTA,OPORTUNIDADE,FASE,OPORTUNIDADECATEGORIA,DATAFECHAMENTO,PROPOSTA,PRODUTO,VALORPRODUTOFINAL,OPORTUNIDADEID,PropostaPrincipal, RECORRENTE,DATACRIACAO,PRODUTO_RECORRENCIA,Proprietario,Campanha,Categoria,PRODUTO_GRUPO,GRUPO_VENDEDOR,ULTIMO_VALOR,CONTAID,PropostaValor,Negocio,ValorProduto,PropostaID,INSERT_MANUAL)
SELECT	Opp.Conta ,
		Prox_Opp.Oportunidade ,
		Prox_Opp.Fase ,
		Prox_Opp.OportunidadeCategoria ,
		Prox_Opp.DataFechamento ,
		Prox_Opp.Proposta ,
		Opp.Produto ,
		0.00 AS ValorProdutoFINAL ,
		Prox_Opp.OportunidadeID ,
		Prox_Opp.PropostaPrincipal ,
		1 AS RECORRENTE ,
		Prox_Opp.DataCriacao ,
		Prox_Opp.PRODUTO_RECORRENCIA ,
		Prox_Opp.Proprietario,
		Prox_Opp.Campanha ,
		Prox_Opp.Categoria ,
		Prox_Opp.PRODUTO_GRUPO ,
		Prox_Opp.GRUPO_VENDEDOR ,
		Prox_Opp.ULTIMO_VALOR ,
		Prox_Opp.CONTAID ,
		Prox_Opp.PropostaValor ,
		Prox_Opp.Negocio ,
		0.00 AS ValorProduto ,
		Prox_Opp.PropostaID ,
		'SIM' AS INSERT_MANUAL
FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp		CROSS APPLY (SELECT TOP 1 *
															 FROM	[VAGAS_DW].[OPORTUNIDADES] AS Opp_A1
															 WHERE	Opp.CONTAID = Opp_A1.CONTAID
																	AND Opp_A1.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
																	AND Opp_A1.Fase = 'fechado_e_ganho'
																	AND Opp_A1.INSERT_MANUAL IS NULL
																	AND Opp_A1.DataFechamento > Opp.DataFechamento
															 ORDER BY
																	Opp_A1.DataFechamento ASC) AS Prox_Opp
												LEFT OUTER JOIN [VAGAS_DW].[OPORTUNIDADES] AS Prox_Opp_Prod -- Registros da próxima oportunidade, no outer apply tenho o oportunidadeid da próxima oportunidade
												ON Prox_Opp.OportunidadeID = Prox_Opp_Prod.OportunidadeID
												AND Prox_Opp_Prod.INSERT_MANUAL IS NULL
												AND Opp.Produto = Prox_Opp_Prod.Produto -- Produto da oportunidade anterior = Produto da próxima oportunidade
WHERE	Opp.Fase = 'fechado_e_ganho'
		AND Opp.PRODUTO_RECORRENCIA IN ('monthly', 'annually')
		AND Opp.INSERT_MANUAL IS NULL
		AND Prox_Opp_Prod.Produto IS NULL
		AND NOT EXISTS (SELECT *
						FROM	#OppCarimbo AS Opp_A1
						WHERE	Prox_Opp.OportunidadeID = Opp_A1.OportunidadeID COLLATE SQL_Latin1_General_CP1_CI_AI)
ORDER BY 
		Opp.Oportunidade,
		Opp.Produto ;