USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Variaveis_Perfil_Uso' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Variaveis_Perfil_Uso
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 07/04/2017
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- procedure criada baseado em script entregue pela Beth Nakano
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Variaveis_Perfil_Uso 
@DATA_INICIO SMALLDATETIME = NULL,
@DATA_FIM SMALLDATETIME = NULL

AS
SET NOCOUNT ON

DECLARE @DATA_REFERENCIA SMALLDATETIME
SET @DATA_REFERENCIA = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112))

IF @DATA_INICIO IS NULL
	SET @DATA_INICIO = DATEADD(YEAR,-1,@DATA_REFERENCIA)

IF @DATA_FIM IS NULL
	SET @DATA_FIM = @DATA_REFERENCIA

-- Requisições
-- 00:00:00
SELECT DISTINCT 
		codcli_rv AS COD_CLI, 
		COUNT(DISTINCT cod_rvw) AS QTD_REQUISICOES
INTO #TMP_REQUISICOES
FROM [hrh-data].dbo.[ReqVaga-workflow] 
INNER JOIN [hrh-data].dbo.[Reqvaga-controle]  ON Cod_rvc = CodRvc_rvw
INNER JOIN [hrh-data].dbo.[Reqvaga-gestores]  ON Cod_rv = CodRv_rvc
INNER JOIN [hrh-data].dbo.Clientes  ON Cod_Cli = Codcli_rv
WHERE Data_rvw >= @DATA_INICIO AND data_rvw < @DATA_FIM
GROUP BY codcli_rv
ORDER BY COUNT(DISTINCT COD_RVW) DESC

-- RI - vagas veiculadas na divisão de RI
-- 00:00:18
SELECT Cod_cli, 
	   COUNT(DISTINCT cod_vaga) AS QTD_VAGAS_RI
INTO #TMP_VAGAS_RI
FROM [hrh-data].dbo.Clientes 
INNER JOIN [hrh-data].dbo.Divisoes ON CodCli_div = Cod_cli 
								   AND CodNavex_div = 300
LEFT JOIN [hrh-data].dbo.Vagas ON Cod_div = CodDivVeic_vaga 
								   AND DtCriacao_vaga >= @DATA_INICIO
								   AND DtCriacao_vaga < @DATA_FIM
								   AND Vagamodelo_vaga = 0 
								   AND ColetaCur_vaga = 0 
								   AND VagaComExt_vaga = 0
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli NOT LIKE '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0 AND sobdemanda_cli = 0) OR sobdemanda_cli = 1)	-- FIT e FLEX
GROUP BY Cod_cli
ORDER BY COUNT(DISTINCT COD_VAGA) DESC

-- testes VAGAS na candidatura
-- esta consulta pode mudar pois depende da identificação da ficha
-- 00:00:40
SELECT cod_cli, 
	   COUNT(DISTINCT cod_vaga) AS QTD_VAGAS_COM_TESTES_NA_CANDIDATURA
INTO #TMP_VAGAS_COM_TESTES_NA_CANDIDATURA
FROM [hrh-data].dbo.Clientes  
INNER JOIN [hrh-data].dbo.Vagas ON Cod_Cli = CodCliente_vaga
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS A  ON CodFicha1_vaga = A.Cod_fic 
												   AND A.ident_fic LIKE '%vagas%' 
												   AND A.ident_fic NOT LIKE '%vagas pontuais%'
												   AND A.teste_fic = 4
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS B  ON CodFicha2_vaga = B.Cod_fic 
												   AND B.ident_fic LIKE '%vagas%' 
												   AND B.ident_fic NOT LIKE '%vagas pontuais%'
												   AND B.teste_fic = 4
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS C  ON CodFicha3_vaga = C.Cod_fic 
												   AND C.ident_fic LIKE '%vagas%' 
												   AND C.ident_fic NOT LIKE '%vagas pontuais%'
												   AND C.teste_fic = 4
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS D  ON CodFicha4_vaga = D.Cod_fic 
												   AND D.ident_fic LIKE '%vagas%' 
												   AND D.ident_fic NOT LIKE '%vagas pontuais%'
												   AND D.teste_fic = 4
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli NOT LIKE '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0  and sobdemanda_cli = 0) OR sobdemanda_cli = 1)
AND DtCriacao_vaga >= @DATA_INICIO AND dtcriacao_vaga < @DATA_FIM
AND Vagamodelo_vaga = 0 and ColetaCur_vaga = 0
AND VagaComExt_vaga = 0
AND (A.Cod_fic IS NOT NULL OR B.Cod_fic IS NOT NULL OR C.Cod_fic IS NOT NULL OR D.Cod_fic IS NOT NULL)
GROUP BY Cod_cli
ORDER BY COUNT(DISTINCT COD_VAGA) DESC


-- Testes VAGAS após candidatura
-- esta consulta pode mudar pois depende da identificação da ficha
-- 00:00:46
SELECT Cod_cli, 
	   COUNT(DISTINCT codvagactxt_ficpend) AS QTD_VAGAS_COM_TESTES_POS_CANDIDATURA
INTO #TMP_VAGAS_COM_TESTES_POS_CANDIDATURA
FROM [hrh-data].dbo.[Cand-fichaspend]  
INNER JOIN [hrh-data].dbo.[Fichas-descrgeral]  ON Cod_fic = CodFicha_ficpend
INNER JOIN [hrh-data].dbo.Clientes ON Cod_Cli = CodCli_fic
WHERE dataped_ficpend >= @DATA_INICIO AND dataped_ficpend < @DATA_FIM
AND ident_fic like '%vagas%' 
AND ident_fic not like '%vagas pontuais%'
AND teste_fic = 4
GROUP BY Cod_cli, ident_cli
ORDER BY COUNT(DISTINCT CODVAGACTXT_FICPEND) DESC

--- Testes customizados na candidatura
-- esta consulta pode mudar pois depende da identificação da ficha
-- 00:00:23
SELECT cod_cli, 
	   COUNT(DISTINCT COD_VAGA) AS QTD_VAGAS_COM_TESTES_CUSTOMIZADOS_NA_CANDIDATURA
INTO #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_NA_CANDIDATURA
FROM [hrh-data].dbo.Clientes 
INNER JOIN [hrh-data].dbo.Vagas ON (Cod_Cli = CodCLiente_vaga)
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS A ON CodFicha1_vaga = A.Cod_fic 
												  AND A.ident_fic NOT LIKE '%vagas%' 
												  AND A.teste_fic = 4
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS B ON CodFicha2_vaga = B.Cod_fic 
												  AND B.ident_fic NOT LIKE '%vagas%' 
												  AND B.teste_fic = 4
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS C ON CodFicha3_vaga = C.Cod_fic 
												  AND C.ident_fic NOT LIKE '%vagas%' 
												  AND C.teste_fic = 4
LEFT JOIN [hrh-data].dbo.[Fichas-descrgeral] AS D ON CodFicha4_vaga = D.Cod_fic 
												  AND D.ident_fic NOT LIKE '%vagas%' 
												  AND D.teste_fic = 4
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli NOT LIKE '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0  AND sobdemanda_cli = 0) OR sobdemanda_cli = 1)
AND DtCriacao_vaga >= @DATA_INICIO AND dtcriacao_vaga < @DATA_FIM 
AND Vagamodelo_vaga = 0 
AND ColetaCur_vaga = 0
AND VagaComExt_vaga = 0
AND (A.Cod_fic IS NOT NULL OR B.Cod_fic IS NOT NULL OR C.Cod_fic IS NOT NULL OR D.Cod_fic IS NOT NULL)
GROUP BY Cod_Cli
ORDER BY COUNT(DISTINCT COD_VAGA) DESC

-- Testes Customizados Pós Candidatura
-- esta consulta pode mudar pois depende da identificação da ficha
-- 00:00:53
SELECT cod_cli, 
	   COUNT(DISTINCT CODVAGACTXT_FICPEND) QTD_VAGAS_COM_TESTES_CUSTOMIZADOS_POS_CANDIDATURA
INTO #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_POS_CANDIDATURA
FROM [hrh-data].dbo.[Cand-fichaspend]  
INNER JOIN [hrh-data].dbo.[Fichas-descrgeral]  ON Cod_fic = CodFicha_ficpend
INNER JOIN [hrh-data].dbo.Clientes ON Cod_cli = CodCli_fic
WHERE dataped_ficpend >= @DATA_INICIO AND dataped_ficpend < @DATA_FIM
AND teste_fic = 4 
AND ident_fic NOT LIKE '%vagas%'
GROUP BY Cod_cli
ORDER BY COUNT (DISTINCT CODVAGACTXT_FICPEND) DESC


-- Vagas Etalent
-- 00:00:21
select cod_cli, 
	   COUNT(DISTINCT COD_VAGA) AS QTD_VAGAS_ETALENT
INTO #TMP_VAGAS_ETALENT
FROM [hrh-data].dbo.Clientes 
INNER JOIN [hrh-data].dbo.Vagas ON Cod_Cli = CodCLiente_vaga
INNER JOIN [hrh-data].dbo.divisoes ON Cod_div = CodDivVeic_vaga
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli NOT LIKE '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0 AND sobdemanda_cli = 0) OR sobdemanda_cli = 1)
AND DtCriacao_vaga >= @DATA_INICIO AND dtcriacao_vaga < @DATA_FIM 
AND Vagamodelo_vaga = 0 
AND ColetaCur_vaga = 0
AND VagaComExt_vaga = 0
--AND TipoProcesso_vaga <> 4		-- depende se considera ou não vagas do tipo Redes
AND VAGASetalent_vaga = 1		-- obrigatória
GROUP BY Cod_cli
ORDER BY COUNT(DISTINCT COD_VAGA) DESC

-- tem duas ou mais fases cadastradas
-- não significa que a empresa utilizou as fases, apenas que cadastrou as fases na vaga
-- 00:00:30
SELECT Cod_vaga AS CodVaga, 
	   COUNT(Cod_fasevaga) AS QtdeFases
INTO #TEMP
FROM [hrh-data].dbo.Clientes  
INNER JOIN [hrh-data].dbo.Vagas ON Cod_Cli = CodCliente_vaga
INNER JOIN [hrh-data].dbo.[Vagas-fases] ON Cod_vaga = Codvaga_fasevaga
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli not like '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0 AND sobdemanda_cli = 0) OR sobdemanda_cli = 1)
AND DtCriacao_vaga >= @DATA_INICIO AND dtcriacao_vaga < @DATA_FIM
AND Vagamodelo_vaga = 0 
AND ColetaCur_vaga = 0
AND VagaComExt_vaga = 0
GROUP BY Cod_vaga
HAVING count(Cod_fasevaga) >= 2

SELECT COD_CLI, 
	   COUNT(DISTINCT cod_vaga) AS QTD_VAGAS_MAIS_1_FASE
INTO #TMP_VAGAS_COM_MAIS_DE_UMA_FASE
FROM #TEMP
INNER JOIN [hrh-data].dbo.Vagas on (Cod_vaga = Codvaga)
INNER JOIN [hrh-data].dbo.CLientes on (Cod_Cli = CodCliente_vaga)
GROUP BY Cod_cli
ORDER BY  COUNT(DISTINCT COD_VAGA) DESC


-- Triagens de Vagas
-- 00:00:23
SELECT Cod_Cli, 
	   COUNT(DISTINCT COD_DEBTRI) AS QTD_TRIAGEM, 
	   SUM(CASE WHEN (VersaoTriagem_debTri IS NULL) THEN 1 ELSE 0 END) AS QTD_TRIAGEM_1,
	   SUM(CASE WHEN (VersaoTriagem_debTri = 2) THEN 1 ELSE 0 END) AS  QTD_TRIAGEM_2
INTO #TMP_TRIAGEM_GERAL
FROM [hrh-data].dbo.debugtriagem 
INNER JOIN [hrh-data].dbo.Vagas ON Cod_vaga = Codvaga_debTri 
								AND Coletacur_vaga = 0 
								AND VagaComExt_vaga = 0
INNER JOIN [hrh-data].dbo.Funcionarios ON Cod_func = CodUsu_debTri
INNER JOIN [hrh-data].dbo.CLientes ON Cod_cli = CodCli_func
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli not like '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0 AND sobdemanda_cli = 0) OR sobdemanda_cli = 1)
AND Data_debTri >= @DATA_INICIO AND Data_debTri < @DATA_FIM 
AND SenhaMestre_debTri = 0
GROUP BY Cod_cli
ORDER BY COUNT(DISTINCT COD_DEBTRI)  DESC, COD_CLI

-- Triagens no BCE,   Triagens no BCC
-- 00:00:06
SELECT Cod_Cli, 
	   COUNT(DISTINCT cod_debTri) AS QTD_TRIAGEM_BCC_BCE, 
	   SUM(CASE WHEN (VersaoTriagem_debTri IS NULL) THEN 1 ELSE 0 END) AS  QTD_TRIAGEM_1_BCC_BCE,
	   SUM(CASE WHEN (VersaoTriagem_debTri = 2) THEN 1 ELSE 0 END) AS QTD_TRIAGEM_2_BCC_BCE
INTO #TMP_TRIAGEM_BCE_BCC
FROM [hrh-data].dbo.debugtriagem 
INNER JOIN [hrh-data].dbo.Funcionarios ON Cod_func = CodUsu_debTri
INNER JOIN [hrh-data].dbo.Clientes ON Cod_cli = CodCli_func
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli NOT LIKE '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0 AND sobdemanda_cli = 0) OR sobdemanda_cli = 1)
AND Data_debTri >= @DATA_INICIO AND Data_debTri < @DATA_FIM
AND SenhaMestre_debTri = 0
--AND BCA_debTRi = 1
AND BCC_debtri = 1
GROUP BY Cod_cli
ORDER BY COUNT(DISTINCT COD_DEBTRI)  DESC

-- envio de mensagens 
-- inclui envio de mensagem para solicitação de preenchimento de teste e solicitação de agendamento
-- dá para subtrair olhando as tabelas de solicitações
SELECT Cod_cli, 
	   COUNT(DISTINCT Codvaga_hist) AS QTD_VAGAS_COM_ENVIO_MSG, 
	   COUNT(chavesql_hist) AS QTD_MSG
INTO #TMP_ENVIO_MSG
FROM [hrh-data].dbo.Historico 
INNER JOIN [hrh-data].dbo.Clientes on (Cod_Cli = CodCliente_hist)
WHERE Bloqueado_cli = 0 
AND Ficticio_cli  = 0 
AND nome_cli NOT LIKE '%fict%cia%'  
AND CapacidadeBCAAtual_cli > 10
AND ( (Restrito_cli = 0 AND sobdemanda_cli = 0) OR sobdemanda_cli = 1)
AND dt_hist >= @DATA_INICIO AND dt_hist < @DATA_FIM 
AND tipo_hist = -107
AND chavesql_hist >= 1216250094 -- Acima de 2016 (performance)
GROUP BY Cod_cli
ORDER BY COUNT(chavesql_hist) DESC

-- CONSOLIDAR CLIENTES
SELECT Cod_Cli INTO #TMP_CLIENTES FROM #TMP_REQUISICOES
UNION 
SELECT Cod_Cli FROM #TMP_VAGAS_RI
UNION 
SELECT Cod_Cli FROM #TMP_VAGAS_COM_TESTES_NA_CANDIDATURA
UNION 
SELECT Cod_Cli FROM #TMP_VAGAS_COM_TESTES_POS_CANDIDATURA
UNION 
SELECT Cod_Cli FROM #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_NA_CANDIDATURA
UNION 
SELECT Cod_Cli FROM #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_POS_CANDIDATURA
UNION 
SELECT Cod_Cli FROM #TMP_VAGAS_ETALENT
UNION 
SELECT Cod_Cli FROM #TMP_VAGAS_COM_MAIS_DE_UMA_FASE
UNION 
SELECT Cod_Cli FROM #TMP_TRIAGEM_GERAL
UNION 
SELECT Cod_Cli FROM #TMP_TRIAGEM_BCE_BCC
UNION 
SELECT Cod_Cli FROM #TMP_ENVIO_MSG

TRUNCATE TABLE VAGAS_DW.TMP_CLIENTES_PERFIL_USO

INSERT INTO VAGAS_DW.TMP_CLIENTES_PERFIL_USO
SELECT A.COD_CLI,
	   @DATA_REFERENCIA,
	   @DATA_INICIO,
	   @DATA_FIM,
	   ISNULL(B.QTD_REQUISICOES,0) AS QTD_REQUISICOES, 
	   ISNULL(C.QTD_VAGAS_RI,0) AS QTD_VAGAS_RI,
	   ISNULL(D.QTD_VAGAS_COM_TESTES_NA_CANDIDATURA,0) AS QTD_VAGAS_COM_TESTES_NA_CANDIDATURA,
	   ISNULL(E.QTD_VAGAS_COM_TESTES_POS_CANDIDATURA,0) AS QTD_VAGAS_COM_TESTES_POS_CANDIDATURA,
	   ISNULL(F.QTD_VAGAS_COM_TESTES_CUSTOMIZADOS_NA_CANDIDATURA,0) AS QTD_VAGAS_COM_TESTES_CUSTOMIZADOS_NA_CANDIDATURA,
	   ISNULL(G.QTD_VAGAS_COM_TESTES_CUSTOMIZADOS_POS_CANDIDATURA,0) AS QTD_VAGAS_COM_TESTES_CUSTOMIZADOS_POS_CANDIDATURA,
	   ISNULL(H.QTD_VAGAS_ETALENT,0) AS QTD_VAGAS_ETALENT,
	   ISNULL(I.QTD_VAGAS_MAIS_1_FASE,0) AS QTD_VAGAS_MAIS_1_FASE,
	   ISNULL(J.QTD_TRIAGEM,0) AS QTD_TRIAGEM,
	   ISNULL(J.QTD_TRIAGEM_1,0) AS QTD_TRIAGEM_1,
	   ISNULL(J.QTD_TRIAGEM_2,0) AS QTD_TRIAGEM_2,
	   ISNULL(L.QTD_TRIAGEM_BCC_BCE,0) AS QTD_TRIAGEM_BCC_BCE,
	   ISNULL(L.QTD_TRIAGEM_1_BCC_BCE,0) AS QTD_TRIAGEM_1_BCC_BCE,
	   ISNULL(L.QTD_TRIAGEM_2_BCC_BCE,0) AS QTD_TRIAGEM_2_BCC_BCE,
	   ISNULL(M.QTD_VAGAS_COM_ENVIO_MSG,0) AS QTD_VAGAS_COM_ENVIO_MSG,
	   ISNULL(M.QTD_MSG,0) AS QTD_MSG 
FROM #TMP_CLIENTES A
LEFT OUTER JOIN #TMP_REQUISICOES B ON B.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_VAGAS_RI C ON C.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_VAGAS_COM_TESTES_NA_CANDIDATURA D ON D.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_VAGAS_COM_TESTES_POS_CANDIDATURA E ON E.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_NA_CANDIDATURA F ON F.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_POS_CANDIDATURA G ON G.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_VAGAS_ETALENT H ON H.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_VAGAS_COM_MAIS_DE_UMA_FASE I ON I.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_TRIAGEM_GERAL J ON J.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_TRIAGEM_BCE_BCC L ON L.COD_CLI = A.COD_CLI
LEFT OUTER JOIN #TMP_ENVIO_MSG M ON M.COD_CLI = A.COD_CLI

DROP TABLE #TEMP
DROP TABLE #TMP_REQUISICOES
DROP TABLE #TMP_VAGAS_RI
DROP TABLE #TMP_VAGAS_COM_TESTES_NA_CANDIDATURA
DROP TABLE #TMP_VAGAS_COM_TESTES_POS_CANDIDATURA
DROP TABLE #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_NA_CANDIDATURA
DROP TABLE #TMP_VAGAS_COM_TESTES_CUSTOMIZADOS_POS_CANDIDATURA
DROP TABLE #TMP_VAGAS_ETALENT
DROP TABLE #TMP_VAGAS_COM_MAIS_DE_UMA_FASE
DROP TABLE #TMP_TRIAGEM_GERAL
DROP TABLE #TMP_TRIAGEM_BCE_BCC
DROP TABLE #TMP_ENVIO_MSG

