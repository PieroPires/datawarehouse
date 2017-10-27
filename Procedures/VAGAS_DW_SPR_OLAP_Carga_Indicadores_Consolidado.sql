-- select * from vagas_dw.TMP_VAGAS
-- EXEC VAGAS_DW.SPR_OLAP_Carga_Indicadores_Consolidado '20150101'
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Indicadores_Consolidado' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Indicadores_Consolidado
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 12/05/2017
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Indicadores_Consolidado @DATA SMALLDATETIME = NULL

AS
SET NOCOUNT ON

IF @DATA IS NULL
	-- carregar 5 dias anterior a ultima data j� carregada (para evitar poss�veis inconsistencias)
	SELECT @DATA = MAX(DATA) - 5 FROM VAGAS_DW.INDICADORES_CONSOLIDADO 

------------------- INICIO DUPLICIDADES --------------------------------------------

-- carregar todos os curriculos e cadastros do BCC
SELECT COD_CAND,
	   DATA_CADASTRO,
	   CPF
INTO #TMP_CADASTRO_UNICO   
FROM VAGAS_DW.CANDIDATOS A
WHERE FEZ_ACESSO_IRRESTRITO = 1

-- Limpar cadastros sem CPF
DELETE #TMP_CADASTRO_UNICO WHERE CPF IS NULL

CREATE CLUSTERED INDEX IDX_CPF ON #TMP_CADASTRO_UNICO (CPF) 

SELECT COD_CAND,
	   DATA_CADASTRO,
	   CPF,
		CASE WHEN EXISTS ( SELECT * 
							FROM #TMP_CADASTRO_UNICO 
							WHERE CPF = A.CPF
							AND COD_CAND <> A.COD_CAND
							AND DATA_CADASTRO < A.DATA_CADASTRO ) THEN 'SIM' ELSE 'N�O' END AS DUPLICADO
INTO #TMP_DETALHE_DUPLICADO
FROM #TMP_CADASTRO_UNICO A
WHERE A.DATA_CADASTRO >= @DATA

-- LIMPAR DATAS EXISTENTES
DELETE VAGAS_DW.INDICADORES_CONSOLIDADO 
FROM VAGAS_DW.INDICADORES_CONSOLIDADO A
WHERE EXISTS ( SELECT * FROM #TMP_DETALHE_DUPLICADO WHERE DATA_CADASTRO = A.DATA )

-- INSERIR NA TABELA FATO
INSERT INTO VAGAS_DW.INDICADORES_CONSOLIDADO (DATA,QTD_CADASTROS_COM_DUPLICIDADE,QTD_CADASTROS_SEM_DUPLICIDADE)
SELECT DATA_CADASTRO,
	   ( SELECT COUNT(*) FROM #TMP_DETALHE_DUPLICADO WHERE DATA_CADASTRO = A.DATA_CADASTRO AND DUPLICADO = 'SIM' ) AS QTD_CADASTROS_COM_DUPLICIDADE,
	   ( SELECT COUNT(*) FROM #TMP_DETALHE_DUPLICADO WHERE DATA_CADASTRO = A.DATA_CADASTRO AND DUPLICADO = 'N�O' ) AS QTD_CADASTROS_SEM_DUPLICIDADE
FROM #TMP_DETALHE_DUPLICADO A
GROUP BY DATA_CADASTRO

------------------- FIM DUPLICIDADES --------------------------------------------


------------------- INICIO CAC --------------------------------------------
	-- ATUALIZAR DADOS DO CAC
	-- DROP TABLE #TMP_CLIENTES_NOVOS
	SELECT DATA_REFERENCIA,	
		   MERCADO,
		   COUNT(*) AS QTD
	INTO #TMP_CLIENTES_NOVOS
	FROM VAGAS_DW.LTV A
	WHERE DATA_REFERENCIA >= '20170101'
	AND NOT EXISTS ( SELECT * 
					 FROM VAGAS_DW.LTV
					 WHERE DATA_REFERENCIA >= DATEADD(DAY,-40,A.DATA_REFERENCIA)
					 AND DATA_REFERENCIA < A.DATA_REFERENCIA 
					 AND CLIENTE = A.CLIENTE ) -- NOVOS CLIENTES 
	GROUP BY DATA_REFERENCIA,MERCADO
	ORDER BY 1

	-- ATUALIZAR CLIENTES ATIVOS E VALOR DO CAC MENSAL
	UPDATE VAGAS_DW.INDICADORES_CONSOLIDADO SET QTD_CLIENTES_ATIVOS = B.QTD_CLIENTES_ATIVOS,
												VALOR_MES_CAC_SUPERA = C.TOTAL_CAC_SUPERA,
												VALOR_MES_CAC_SIMPLIFICA = C1.TOTAL_CAC_SIMPLIFICA,
												QTD_CLIENTES_ATIVOS_SUPERA = ISNULL(D.QTD_CLIENTES_ATIVOS_SUPERA,0), 
												QTD_CLIENTES_NOVOS_SUPERA = ISNULL(F.QTD_CLIENTES_NOVOS_SUPERA,0), 
												QTD_CLIENTES_ATIVOS_SIMPLIFICA = ISNULL(E.QTD_CLIENTES_ATIVOS_SIMPLIFICA,0),
												QTD_CLIENTES_NOVOS_SIMPLIFICA = ISNULL(G.QTD_CLIENTES_NOVOS_SIMPLIFICA,0),
												QTD_CLIENTES_NOVOS = ISNULL(H.QTD_CLIENTES_NOVOS,0), 
												LTV_SUPERA = I.LTV_SUPERA,
												LTV_SIMPLIFICA = J.LTV_SIMPLIFICA,
												FECHAMENTO_MES = 'S' , -- INDICA QUE � O ULTIMO DIA DO M�S
												QTD_CLIENTES_ATIVOS_S_MERCADO = D1.QTD_CLIENTES_ATIVOS_S_MERCADO,
												LTV_S_MERCADO = I1.LTV_S_MERCADO ,
												QTD_CLIENTES_NOVOS_S_MERCADO = F1.QTD_CLIENTES_NOVOS_S_MERCADO

	FROM VAGAS_DW.INDICADORES_CONSOLIDADO A
	OUTER APPLY ( SELECT COUNT(*) AS QTD_CLIENTES_ATIVOS
				  FROM VAGAS_DW.LTV
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA) ) B
	OUTER APPLY ( SELECT SUM(TOTAL_CAC_SUPERA) / 12 AS TOTAL_CAC_SUPERA
				  FROM VAGAS_DW.CAC_DETALHE_DESPESA ) C
	OUTER APPLY ( SELECT SUM(TOTAL_CAC_SIMPLIFICA) / 12 AS TOTAL_CAC_SIMPLIFICA
				  FROM VAGAS_DW.CAC_DETALHE_DESPESA ) C1
	OUTER APPLY ( SELECT COUNT(*) AS QTD_CLIENTES_ATIVOS_SUPERA
				  FROM VAGAS_DW.LTV
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SUPERA' ) D
	OUTER APPLY ( SELECT COUNT(*) AS QTD_CLIENTES_ATIVOS_S_MERCADO
				  FROM VAGAS_DW.LTV
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SEM MERCADO' ) D1
	OUTER APPLY ( SELECT COUNT(*) AS QTD_CLIENTES_ATIVOS_SIMPLIFICA
				  FROM VAGAS_DW.LTV
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SIMPLIFICA' ) E
	OUTER APPLY ( SELECT TOP 1 QTD AS QTD_CLIENTES_NOVOS_SUPERA 
				  FROM #TMP_CLIENTES_NOVOS 
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SUPERA' ) F
	OUTER APPLY ( SELECT TOP 1 QTD AS QTD_CLIENTES_NOVOS_S_MERCADO 
				FROM #TMP_CLIENTES_NOVOS 
				WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				AND MERCADO = 'SEM MERCADO' ) F1
	OUTER APPLY ( SELECT TOP 1 QTD AS QTD_CLIENTES_NOVOS_SIMPLIFICA 
				  FROM #TMP_CLIENTES_NOVOS 
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SIMPLIFICA' ) G
	OUTER APPLY ( SELECT TOP 1 SUM(QTD) AS QTD_CLIENTES_NOVOS 
				  FROM #TMP_CLIENTES_NOVOS 
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)) H
	OUTER APPLY ( SELECT AVG(LTV_MERCADO) AS LTV_SUPERA 
				  FROM VAGAS_DW.LTV
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SUPERA' ) I
	OUTER APPLY ( SELECT AVG(LTV_MERCADO) AS LTV_S_MERCADO
				  FROM VAGAS_DW.LTV
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SEM MERCADO' ) I1
	OUTER APPLY ( SELECT AVG(LTV_MERCADO) AS LTV_SIMPLIFICA
				  FROM VAGAS_DW.LTV
				  WHERE MONTH(DATA_REFERENCIA) = MONTH(A.DATA)
				  AND YEAR(DATA_REFERENCIA) = YEAR(A.DATA)
				  AND MERCADO = 'SIMPLIFICA' ) J
	WHERE (    ( YEAR(A.DATA) = ( SELECT MAX(YEAR(ANO_REFERENCIA)) FROM VAGAS_DW.CAC_DETALHE_DESPESA ) ) -- ANO ATUAL
			OR ( MONTH(A.DATA) = 12 AND YEAR(A.DATA) = ( SELECT MAX(YEAR(ANO_REFERENCIA)) - 1 FROM VAGAS_DW.CAC_DETALHE_DESPESA ) ) ) -- OU QUE SEJA O ULTIMO MES DO ANO ANTERIOR
	AND A.DATA = DATEADD(MONTH,1,A.DATA) - DAY(DATEADD(MONTH,1,A.DATA)) -- SEMPRE O �LTIMO DIA DO M�S (MESMA REGRA DO LTV)
	
	UPDATE VAGAS_DW.INDICADORES_CONSOLIDADO SET FECHAMENTO_MES = 'N' WHERE FECHAMENTO_MES IS NULL

	-- C�LCULO DO CAC
	UPDATE VAGAS_DW.INDICADORES_CONSOLIDADO SET CAC_SUPERA = CASE WHEN A.QTD_CLIENTES_NOVOS_SUPERA = 0 
																  THEN A.VALOR_MES_CAC_SUPERA  
																  ELSE A.VALOR_MES_CAC_SUPERA / A.QTD_CLIENTES_NOVOS_SUPERA END,
												CAC_SIMPLIFICA = CASE WHEN A.QTD_CLIENTES_NOVOS_SIMPLIFICA = 0 
																  THEN A.VALOR_MES_CAC_SIMPLIFICA  
																  ELSE A.VALOR_MES_CAC_SIMPLIFICA / A.QTD_CLIENTES_NOVOS_SIMPLIFICA END,
												QTD_CLIENTES_SAIRAM_SUPERA = ISNULL(A.QTD_CLIENTES_NOVOS_SUPERA - (A.QTD_CLIENTES_ATIVOS_SUPERA - B.QTD_CLIENTES_ATIVOS_SUPERA),0),
												QTD_CLIENTES_SAIRAM_SIMPLIFICA = ISNULL(A.QTD_CLIENTES_NOVOS_SIMPLIFICA - (A.QTD_CLIENTES_ATIVOS_SIMPLIFICA - B.QTD_CLIENTES_ATIVOS_SIMPLIFICA),0),

												QTD_CLIENTES_SAIRAM_S_MERCADO = ISNULL(A.QTD_CLIENTES_NOVOS_S_MERCADO - (A.QTD_CLIENTES_ATIVOS_S_MERCADO - B.QTD_CLIENTES_ATIVOS_S_MERCADO),0)
	FROM VAGAS_DW.INDICADORES_CONSOLIDADO A
	OUTER APPLY ( SELECT TOP 1 * 
				  FROM VAGAS_DW.INDICADORES_CONSOLIDADO 
				  WHERE FECHAMENTO_MES = 'S'
				  AND DATA < A.DATA
				  ORDER BY 1 DESC ) B
	WHERE A.FECHAMENTO_MES = 'S'
------------------- FIM CAC --------------------------------------------

-------- INICIO CHURN

UPDATE VAGAS_DW.INDICADORES_CONSOLIDADO SET CHURN_RATE_SUPERA = 
		CASE WHEN ISNULL(B.QTD_CLIENTES_ATIVOS_SUPERA,0) <> 0 
			THEN CONVERT(FLOAT,ISNULL(A.QTD_CLIENTES_SAIRAM_SUPERA,0)) / CONVERT(FLOAT,ISNULL(B.QTD_CLIENTES_ATIVOS_SUPERA,0))
			ELSE NULL END,
	   NEW_CUSTOMER_AQUISITION_SUPERA = CASE WHEN ISNULL(B.QTD_CLIENTES_ATIVOS_SUPERA,0) <> 0 
			THEN CONVERT(FLOAT,ISNULL(A.QTD_CLIENTES_NOVOS_SUPERA,0)) / CONVERT(FLOAT,ISNULL(B.QTD_CLIENTES_ATIVOS_SUPERA,0))
			ELSE NULL END,
	   CHURN_RATE_SIMPLIFICA = CASE WHEN ISNULL(B.QTD_CLIENTES_ATIVOS_SIMPLIFICA,0) <> 0 
			THEN CONVERT(FLOAT,ISNULL(A.QTD_CLIENTES_SAIRAM_SIMPLIFICA,0)) / CONVERT(FLOAT,ISNULL(B.QTD_CLIENTES_ATIVOS_SIMPLIFICA,0))
			ELSE NULL END,
	   NEW_CUSTOMER_AQUISITION_SIMPLIFICA = CASE WHEN ISNULL(B.QTD_CLIENTES_ATIVOS_SIMPLIFICA,0) <> 0 
			THEN CONVERT(FLOAT,ISNULL(A.QTD_CLIENTES_NOVOS_SIMPLIFICA,0)) / CONVERT(FLOAT,ISNULL(B.QTD_CLIENTES_ATIVOS_SIMPLIFICA,0))
			ELSE NULL END
FROM VAGAS_DW.INDICADORES_CONSOLIDADO A 
OUTER APPLY ( SELECT TOP 1 * 
			  FROM VAGAS_DW.INDICADORES_CONSOLIDADO 
			  WHERE DATA < A.DATA
			  AND FECHAMENTO_MES = 'S'
			  ORDER BY DATA DESC ) B
WHERE A.FECHAMENTO_MES = 'S'

UPDATE VAGAS_DW.INDICADORES_CONSOLIDADO SET NET_CUSTOMER_CHURN_RATE_SUPERA = CHURN_RATE_SUPERA - NEW_CUSTOMER_AQUISITION_SUPERA,
											NET_CUSTOMER_CHURN_RATE_SIMPLIFICA = CHURN_RATE_SIMPLIFICA - NEW_CUSTOMER_AQUISITION_SIMPLIFICA
FROM VAGAS_DW.INDICADORES_CONSOLIDADO A 
WHERE A.FECHAMENTO_MES = 'S'

--SELECT * FROM VAGAS_DW.INDICADORES_CONSOLIDADO WHERE FECHAMENTO_MES = 'S'

-------- FIM CHURN

DROP TABLE #TMP_CADASTRO_UNICO
DROP TABLE #TMP_DETALHE_DUPLICADO
DROP TABLE #TMP_CLIENTES_NOVOS

