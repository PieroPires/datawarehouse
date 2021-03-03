USE [vagas_dw] ;
GO

ALTER VIEW VAGAS_DW.VW_OPORTUNIDADES
AS

SELECT CONTAID AS CONTA_ID,
	   ISNULL(Conta,'') AS cntConta,
	   ISNULL(ID_HSYS,'') AS idhsys,	
	   ISNULL(ID_VAGAS,'') AS ID_VAGAS,	
	   ISNULL(Categoria,'') AS cntCategoria,
	   ISNULL(Negocio,'') AS [cntNegócio],
	   ISNULL(Perfil,'') AS cntPerfil,
	   ISNULL(ContaPAI,'') AS cntPai,
	   ISNULL(Oportunidade,'') AS oppOportunidade,
	   ISNULL(OportunidadeID,'') AS oppID,
	   ISNULL(Fase,'') AS oppFase,
	   ISNULL(OportunidadeCategoria,'') AS oppCategoria,
	   --ISNULL(REPLACE(CAST(OportunidadeValor AS VARCHAR(200)), '.', ','),'') AS oppValor,
	   ISNULL(OportunidadeValor,0) AS oppValor,
	   ISNULL(CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DataCriacao,112)),'') AS oppDataCriada,
	   ISNULL(CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DataFechamento,112)),'') AS oppDataFechamento,
	   ISNULL(Proprietario,'') AS [oppProprietário],
	   '' AS leadNome,
	   '' AS leadFonte,
	   ISNULL(Proposta,'') AS prpProposta,
	   PropostaID AS prpID,
	   --ISNULL(REPLACE(CAST(PropostaValor as VARCHAR(200)), '.', ','),'') AS prpValor,
	   ISNULL(PropostaValor ,0) AS prpValor,
	   ISNULL(CONVERT(INT,PropostaPrincipal),'') AS prpPrincipal,
	   ISNULL(Produto,'') AS prodCodProduto,
	   ISNULL(PRODUTO_RECORRENCIA,'') AS prodRecorrencia,
	   --ISNULL(REPLACE(CAST(ValorProduto as VARCHAR(200)), '.', ','),'') AS prodValor,
	   ISNULL(ValorProduto,0) AS prodValor,
	   ISNULL(Desconto,'') AS prodDesconto,
	   ISNULL(Quantidade,'') AS prodQuantidade,
	   --ISNULL(REPLACE(CAST(ValorProdutoFINAL AS VARCHAR(200)), '.', ','),'') AS prodValorFinal,
	   ValorProdutoFINAL AS prodValorFinal,
	   -- Formulas
	   ISNULL(PRODUTO_GRUPO,'') AS Prod,
	   CONVERT(BIT,ISNULL(FECHADO_GANHO,0)) AS [ÉFechGan],
	   CONVERT(BIT,ISNULL(FIT,0)) AS [ÉFGFit],
	   CONVERT(BIT,ISNULL(REVISAO_FIT,0)) AS [ÉFGRevFit],
	   ISNULL(ULTIMO_VALOR,'') AS ValAntFit,
	   '' AS ErrFit,
	   CONVERT(BIT,ISNULL(REVISAO_COM_VALOR_ANTERIOR,0)) AS [ÉRevFitRev],
	   ISNULL(VALOR_REAL,0) AS ValorReal,
	   ISNULL(VALOR_POSIT,0) AS ValPos,
	   ISNULL(VALOR_NEGAT,0) AS ValNeg,
	   CASE WHEN RECORRENTE = 1 THEN 'Recorrente' ELSE 'Pontual' END AS Rec,
	   ISNULL(PRODUTO_RECORRENTE,'') AS ProdRec,
	   ISNULL(PESO_GRUPO,0) AS [Contr%],
	   ISNULL(CONTRIB,'') AS Contrib,
	   ISNULL(CLIENTE,'') AS Cliente,
	   ISNULL(ROUND(VALOR_RANKING_CLIENTE,2),0) AS ValRankCli,
	   --ISNULL(MESANO_FECHAMENTO,'') AS MesAnoFech,
	   ISNULL(CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DataFechamento,112)),'') AS MesAnoFech,
	   ISNULL(DIAS_MEDIA,'') AS Dias,
	   ISNULL(LeadCampanha,'Sem Campanha') AS LeadCampanha,
	   ISNULL(GRUPO_VENDEDOR,'') AS Grupo,
	   ISNULL(CRIADOROPORTUNIDADE,'') AS [OppCriador],
	   ISNULL(CONTEM_FIT,0) AS CONTEM_FIT,
	   ISNULL(CONTEM_REDES,0) AS CONTEM_REDES,
	   GRUPO_OPORTUNIDADE,
	   ISNULL(CONTAUSUARIOALTERACAO,0) AS USUARIO_ALTERACAO_CONTA,
	   ISNULL(CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATAALTERACAOCONTA,112)),'') AS DataAlteracaoConta,
	   IGPM_MES AS IGPM_MES,
	   ISNULL(Campanha,'Sem Campanha') AS Campanha,
	   SEGMENTO_COMERC,
	   CONTEM_CREDITO_OFFLINE,
	   CNPJ,
	   EMAIL_CONTATO,
	   MOTIVO_FECHAMENTO,
  	   MOTIVO_FECHAMENTO_DETALHE,
	   MOTIVO_CONCORRENTE,
	   MOTIVO_PERFIL_ESPECIFICO,
	   NEGOCIACAO_MRR ,
CASE 
	WHEN A.Fase = 'projeto_suspenso' THEN NULL
	WHEN A.Fase = 'prospeccao' THEN DATEDIFF(DAY, A.DataCriacao, CONVERT(DATE, GETDATE()))
	WHEN A.Fase NOT IN ('projeto_suspenso', 'prospeccao') THEN DATEDIFF(DAY, A.DataCriacao, A.DATA_PROPOSTA)
	ELSE NULL
END AS [DiasFase10Prospecção] ,
CASE
	WHEN A.Fase = 'projeto_suspenso' OR A.Fase = 'prospeccao' THEN NULL
	WHEN A.Fase = 'proposta_comercial' THEN DATEDIFF(DAY, A.DATA_PROPOSTA, CONVERT(DATE, GETDATE()))
	WHEN A.Fase NOT IN ('projeto_suspenso','prospeccao', 'proposta_comercial') THEN DATEDIFF(DAY, DATA_PROPOSTA, DATA_AVALIACAO_PROPOSTA)
	ELSE NULL
END AS [DiasFase40PropostaComercial] ,
CASE
	WHEN A.Fase = 'projeto_suspenso' OR A.Fase = 'prospeccao' OR A.Fase = 'proposta_comercial' THEN NULL
	WHEN A.Fase = 'avaliacao_interna' THEN DATEDIFF(DAY, DATA_PROPOSTA, CONVERT(DATE, GETDATE()))
	WHEN A.Fase NOT IN ('projeto_suspenso', 'prospeccao', 'proposta_comercial', 'avaliacao_interna') THEN DATEDIFF(DAY, DATA_PROPOSTA, DATA_AVALIACAO_PROPOSTA)
	ELSE NULL
END AS [DiasFase60AnaliseInterna] ,
CASE
	WHEN A.Fase = 'projeto_suspenso' OR A.Fase = 'prospeccao' OR A.Fase = 'proposta_comercial' OR A.Fase = 'avaliacao_interna' THEN NULL
	WHEN A.Fase = 'contrato' THEN DATEDIFF(DAY, A.DATA_AVALIACAO_PROPOSTA, CONVERT(DATE, GETDATE()))
	WHEN A.Fase NOT IN ('projeto_suspenso', 'prospeccao', 'proposta_comercial', 'avaliacao_interna', 'contrato') THEN DATEDIFF(DAY, A.DATA_AVALIACAO_PROPOSTA, A.DATA_CONTRATO)
	ELSE NULL
END AS [DiasFase80Contrato] ,
CASE
	WHEN A.Fase = 'projeto_suspenso' OR A.Fase = 'fechado_e_ganho' OR A.Fase = 'fechado_e_perdido' THEN NULL
	WHEN A.Fase = 'prospeccao' THEN CASE 
										WHEN A.Fase = 'projeto_suspenso' THEN NULL
										WHEN A.Fase = 'prospeccao' THEN DATEDIFF(DAY, A.DataCriacao, CONVERT(DATE, GETDATE()))
										WHEN A.Fase NOT IN ('projeto_suspenso', 'prospeccao') THEN DATEDIFF(DAY, A.DataCriacao, A.DATA_PROPOSTA)
										ELSE NULL
									END -- DiasFase10Prospecção
	WHEN A.Fase = 'proposta_comercial'	THEN CASE
												WHEN A.Fase = 'projeto_suspenso' OR A.Fase = 'prospeccao' THEN NULL
												WHEN A.Fase = 'proposta_comercial' THEN DATEDIFF(DAY, A.DATA_PROPOSTA, CONVERT(DATE, GETDATE()))
												WHEN A.Fase NOT IN ('projeto_suspenso','prospeccao', 'proposta_comercial') THEN DATEDIFF(DAY, DATA_PROPOSTA, DATA_AVALIACAO_PROPOSTA)
												ELSE NULL
											END -- DiasFase40PropostaComercial
	WHEN A.Fase = 'avaliacao_interna' THEN CASE
											WHEN A.Fase = 'projeto_suspenso' OR A.Fase = 'prospeccao' OR A.Fase = 'proposta_comercial' THEN NULL
											WHEN A.Fase = 'avaliacao_interna' THEN DATEDIFF(DAY, DATA_PROPOSTA, CONVERT(DATE, GETDATE()))
											WHEN A.Fase NOT IN ('projeto_suspenso', 'prospeccao', 'proposta_comercial', 'avaliacao_interna') THEN DATEDIFF(DAY, DATA_PROPOSTA, DATA_AVALIACAO_PROPOSTA)
											ELSE NULL
										END -- DiasFase60AnaliseInterna
	WHEN A.Fase = 'contrato' THEN CASE
									WHEN A.Fase = 'projeto_suspenso' OR A.Fase = 'prospeccao' OR A.Fase = 'proposta_comercial' OR A.Fase = 'avaliacao_interna' THEN NULL
									WHEN A.Fase = 'contrato' THEN DATEDIFF(DAY, A.DATA_AVALIACAO_PROPOSTA, CONVERT(DATE, GETDATE()))
									WHEN A.Fase NOT IN ('projeto_suspenso', 'prospeccao', 'proposta_comercial', 'avaliacao_interna', 'contrato') THEN DATEDIFF(DAY, A.DATA_AVALIACAO_PROPOSTA, A.DATA_CONTRATO)
									ELSE NULL
								END
	ELSE NULL
END AS [DiasFaseAtual],
DATA_PROPOSTA,
DATA_AVALIACAO_PROPOSTA,
DATA_CONTRATO,
PLANO
FROM VAGAS_DW.OPORTUNIDADES AS A ;
--WHERE DataCriacao < CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112))