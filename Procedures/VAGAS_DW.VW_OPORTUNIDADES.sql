ALTER VIEW VAGAS_DW.VW_OPORTUNIDADES
AS

SELECT CONTAID AS CONTA_ID,
	   ISNULL(Conta,'') AS cntConta,
	   ISNULL(ID_HSYS,'') AS idhsys,	
	   ISNULL(ID_VAGAS,'') AS ID_VAGAS,	
	   ISNULL(Categoria,'') AS cntCategoria,
	   ISNULL(Negocio,'') AS [cntNeg�cio],
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
	   ISNULL(Proprietario,'') AS [oppPropriet�rio],
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
	   CONVERT(BIT,ISNULL(FECHADO_GANHO,0)) AS [�FechGan],
	   CONVERT(BIT,ISNULL(FIT,0)) AS [�FGFit],
	   CONVERT(BIT,ISNULL(REVISAO_FIT,0)) AS [�FGRevFit],
	   ISNULL(ULTIMO_VALOR,'') AS ValAntFit,
	   '' AS ErrFit,
	   CONVERT(BIT,ISNULL(REVISAO_COM_VALOR_ANTERIOR,0)) AS [�RevFitRev],
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
	   MOTIVO_PERFIL_ESPECIFICO
FROM VAGAS_DW.OPORTUNIDADES
--WHERE DataCriacao < CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112))