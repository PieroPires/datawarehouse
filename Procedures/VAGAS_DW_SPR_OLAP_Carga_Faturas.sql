-- EXEC VAGAS_DW.SPR_OLAP_Carga_Faturas
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Faturas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Faturas
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 21/01/2016
-- Description: Procedure para alimenta��o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Faturas

AS
SET NOCOUNT ON

DELETE VAGAS_DW.FATURAS 
FROM VAGAS_DW.FATURAS A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_FATURAS
				WHERE DATA_REFERENCIA = A.DATA_REFERENCIA )

DECLARE @DATA_VENCIMENTO_ORIGINAL SMALLDATETIME

SELECT @DATA_VENCIMENTO_ORIGINAL = MIN(DATA_VENCIMENTO_ORIGINAL) 
FROM VAGAS_DW.TMP_FATURAS 

;WITH CTE_DATAS AS
		( SELECT @DATA_VENCIMENTO_ORIGINAL AS DATA -- INICIO DO ANO CORRENTE
		  UNION ALL
		  SELECT DATEADD(DAY,1,DATA) FROM CTE_DATAS
		  WHERE YEAR(DATA) < YEAR(DATEADD(YEAR,1,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,YEAR(GETDATE())) + '0101')))
		   )

SELECT * 
INTO #TMP_DATAS_UTEIS
FROM CTE_DATAS CTE
WHERE NOT EXISTS ( SELECT 1 FROM VAGAS_DW.FERIADOS_NACIONAIS 
					WHERE DATA = CTE.DATA AND FLAG_MUNICIPAL IS NULL ) -- N�o seja um feriado
AND DATEPART(WEEKDAY,DATA) NOT IN (7,1) -- N�o seja s�b ou dom.
OPTION (MAXRECURSION 8000);

-- Atualizar DATA VENCIMENTO ORIGINAL REAL descontando finais de semana e feriados
UPDATE VAGAS_DW.TMP_FATURAS SET DATA_VENCIMENTO_REAL_ORIGINAL = TAB.DATA 
FROM VAGAS_DW.TMP_FATURAS A
OUTER APPLY ( SELECT TOP 1 * 
				FROM #TMP_DATAS_UTEIS
				WHERE DATA >= A.DATA_VENCIMENTO_ORIGINAL 
			  ORDER BY DATA ASC ) TAB
WHERE DATEPART(WEEKDAY,DATA_VENCIMENTO_ORIGINAL) IN (7,1) -- s�b ou dom.
OR EXISTS ( SELECT 1 
			FROM VAGAS_DW.FERIADOS_NACIONAIS 
			WHERE DATA = A.DATA_VENCIMENTO_ORIGINAL
			AND FLAG_MUNICIPAL IS NULL ) -- um feriado

UPDATE VAGAS_DW.TMP_FATURAS SET DATA_VENCIMENTO_REAL_ORIGINAL = DATA_VENCIMENTO_ORIGINAL
WHERE DATA_VENCIMENTO_REAL_ORIGINAL IS NULL

-- Atualizar dias em atraso e Faixa
UPDATE VAGAS_DW.TMP_FATURAS SET DIAS_ATRASO =  DATEDIFF(DAY,DATA_VENCIMENTO_REAL_ORIGINAL,
					CASE WHEN DATA_BAIXA_PAGTO = '1900-01-01 00:00:00' THEN GETDATE()
						 ELSE DATA_BAIXA_PAGTO END ),
					FLAG_PAGO = CASE WHEN DATA_BAIXA_PAGTO IS NOT NULL AND DATA_BAIXA_PAGTO > '1902-01-01 00:00:00' 
									 THEN 1 ELSE 0 END,
					FLAG_PAGO_INTEGRAL = CASE WHEN DATA_BAIXA_PAGTO IS NOT NULL 
												AND DATA_BAIXA_PAGTO > '1902-01-01 00:00:00' 
												AND SALDO = 0 THEN 1 ELSE 0 END,
					FLAG_PAGO_EM_ATRASO = CASE WHEN DATA_BAIXA_PAGTO > DATA_VENCIMENTO_REAL_ORIGINAL THEN 1 ELSE 0 END
FROM VAGAS_DW.TMP_FATURAS 

-- CALCULAR DATA DE AFASTAMENTO PARA PAGAMENTOS REALIZADOS
UPDATE VAGAS_DW.TMP_FATURAS SET PRAZO_PAGTO =  DATEDIFF(DAY,DATA_EMISSAO,DATA_BAIXA_PAGTO )
FROM VAGAS_DW.TMP_FATURAS 
WHERE DATA_BAIXA_PAGTO > '1902-01-01 00:00:00' AND DATA_BAIXA_PAGTO IS NOT NULL

UPDATE VAGAS_DW.TMP_FATURAS SET FAIXA_ATRASO = B.DESCRICAO_FAIXA
FROM VAGAS_DW.TMP_FATURAS A
INNER JOIN VAGAS_DW.FAIXAS B ON A.DIAS_ATRASO BETWEEN B.INICIO_FAIXA AND B.FIM_FAIXA
							AND B.ID_TIPO_FAIXA = 1 -- Faixa dias atraso

-- NORMALIZAR TODAS AS FATURAS ANTERIORES � 2016 
-- [COMBINADO COM O WESLEY QUE VAMOS CONSIDERAR ATRASOS APENAS A PARTIR DE 2016 POR CONTA DA MIGRA��O PARA O ERP]
UPDATE VAGAS_DW.TMP_FATURAS SET SALDO = 0,
								FAIXA_ATRASO = '0 - Em dia',
								DIAS_ATRASO = 0,
								FLAG_PAGO = 1,
								FLAG_PAGO_INTEGRAL = 1,
								FLAG_PAGO_EM_ATRASO = 0
WHERE DATA_VENCIMENTO_ORIGINAL < '20160101' 

-- REMOVER DATAS FUTURAS
DELETE FROM VAGAS_DW.TMP_FATURAS WHERE DATA_VENCIMENTO_REAL_ORIGINAL >= DATA_REFERENCIA

INSERT INTO VAGAS_DW.FATURAS (ID,NUM_PEDIDO,COD_CLI_CRM,COD_CLI,CLIENTE,NFE,DATA_VENCIMENTO,DATA_VENCIMENTO_REAL,DATA_VENCIMENTO_ORIGINAL,
DATA_BAIXA_PAGTO,VALOR,JUROS,VALOR_LIQUIDO,TIPO_ORIGEM,SALDO,STATUS_ORIGEM,ID_CNAB,DATA_VENCIMENTO_REAL_ORIGINAL,DIAS_ATRASO,FAIXA_ATRASO,
DATA_REFERENCIA,FLAG_PAGO,FLAG_PAGO_INTEGRAL,FLAG_PAGO_EM_ATRASO,DATA_EMISSAO,PRAZO_PAGTO,PRODUTO,CNPJ,COD_NATUREZA,NATUREZA)
SELECT ID,NUM_PEDIDO,COD_CLI_CRM,COD_CLI,CLIENTE,NFE,DATA_VENCIMENTO,DATA_VENCIMENTO_REAL,DATA_VENCIMENTO_ORIGINAL,
DATA_BAIXA_PAGTO,VALOR,JUROS,VALOR_LIQUIDO,TIPO_ORIGEM,SALDO,STATUS_ORIGEM,ID_CNAB ,
DATA_VENCIMENTO_REAL_ORIGINAL ,DIAS_ATRASO,FAIXA_ATRASO,DATA_REFERENCIA,FLAG_PAGO,FLAG_PAGO_INTEGRAL,FLAG_PAGO_EM_ATRASO,
DATA_EMISSAO,PRAZO_PAGTO,PRODUTO,CNPJ,COD_NATUREZA,NATUREZA
FROM VAGAS_DW.TMP_FATURAS

-- expurgar datas de referencia antigas (deixar apenas a �lt. de cada mes)
DELETE VAGAS_DW.FATURAS 
FROM VAGAS_DW.FATURAS A
WHERE DATA_REFERENCIA <> ( SELECT MAX(DATA_REFERENCIA)
						  FROM VAGAS_DW.FATURAS
						  WHERE YEAR(DATA_REFERENCIA) = YEAR(A.DATA_REFERENCIA)
						  AND MONTH(DATA_REFERENCIA) = MONTH(A.DATA_REFERENCIA) )

-- SELECIONAR AS DUPLICIDADES (PROCESSO A SER ANALISADO COM A MICHELE / WESLEY)
SELECT ID,NUM_PEDIDO,COD_CLI_CRM,COD_CLI,CLIENTE,NFE,DATA_VENCIMENTO,DATA_VENCIMENTO_REAL,DATA_VENCIMENTO_ORIGINAL,DATA_BAIXA_PAGTO,
VALOR,JUROS,VALOR_LIQUIDO,TIPO_ORIGEM,TIPO,SALDO,STATUS_ORIGEM,STATUS,ID_CNAB,DATA_VENCIMENTO_REAL_ORIGINAL,FAIXA_ATRASO,DIAS_ATRASO,
DATA_REFERENCIA,FLAG_PAGO,FLAG_PAGO_INTEGRAL,FLAG_PAGO_EM_ATRASO,DATA_EMISSAO,PRAZO_PAGTO,MAX(PRODUTO) AS PRODUTO,CNPJ,STATUS_INADIMPLENCIA,
COD_NATUREZA,NATUREZA
INTO #TMP_FATURAS_DUPLICADAS
FROM VAGAS_DW.FATURAS A
WHERE DATA_REFERENCIA = ( SELECT MAX(DATA_REFERENCIA) FROM VAGAS_DW.FATURAS
						WHERE ID = A.ID )
GROUP BY ID,NUM_PEDIDO,COD_CLI_CRM,COD_CLI,CLIENTE,NFE,DATA_VENCIMENTO,DATA_VENCIMENTO_REAL,DATA_VENCIMENTO_ORIGINAL,DATA_BAIXA_PAGTO,
VALOR,JUROS,VALOR_LIQUIDO,TIPO_ORIGEM,TIPO,SALDO,STATUS_ORIGEM,STATUS,ID_CNAB,DATA_VENCIMENTO_REAL_ORIGINAL,FAIXA_ATRASO,DIAS_ATRASO,
DATA_REFERENCIA,FLAG_PAGO,FLAG_PAGO_INTEGRAL,FLAG_PAGO_EM_ATRASO,DATA_EMISSAO,PRAZO_PAGTO,STATUS_INADIMPLENCIA,CNPJ,COD_NATUREZA,NATUREZA
HAVING COUNT(*) > 1
ORDER BY CLIENTE

-- APAGAR PEDIDOS COM DUPLICIDADE
DELETE VAGAS_DW.FATURAS
FROM VAGAS_DW.FATURAS A
WHERE DATA_REFERENCIA = ( SELECT MAX(DATA_REFERENCIA) FROM VAGAS_DW.FATURAS
							WHERE ID = A.ID )
AND EXISTS ( SELECT * FROM #TMP_FATURAS_DUPLICADAS
				WHERE ID = A.ID AND DATA_REFERENCIA = A.DATA_REFERENCIA )

-- REINSERIR PEDIDOS (AGORA SEM DUPLICIDADE)
INSERT INTO VAGAS_DW.FATURAS
SELECT * FROM #TMP_FATURAS_DUPLICADAS

DROP TABLE #TMP_FATURAS_DUPLICADAS

-- BLOQUEADOS
UPDATE VAGAS_DW.FATURAS SET STATUS_INADIMPLENCIA = 'Bloqueado'
FROM VAGAS_DW.FATURAS A
WHERE DATA_REFERENCIA = ( SELECT MAX(DATA_REFERENCIA) 
						  FROM VAGAS_DW.FATURAS
						  WHERE COD_CLI = A.COD_CLI ) -- �LTIMA DATA REF.
AND EXISTS ( SELECT * 
			  FROM VAGAS_DW.OPORTUNIDADES 
			  WHERE CONTAID = A.COD_CLI_CRM
			  AND TIPO_CONTA = 'cliente_bloqueado_inadimplencia' )
AND STATUS_INADIMPLENCIA IS NULL
AND FLAG_PAGO_INTEGRAL = 0

-- POTENCIAL BLOQUEIO
UPDATE VAGAS_DW.FATURAS SET STATUS_INADIMPLENCIA = 'Poss�vel Bloqueio'
FROM VAGAS_DW.FATURAS A
WHERE DATA_REFERENCIA = ( SELECT MAX(DATA_REFERENCIA) 
						  FROM VAGAS_DW.FATURAS
						  WHERE COD_CLI = A.COD_CLI) -- �LTIMA DATA REF.
AND SALDO > 0 
AND ( SELECT COUNT(DISTINCT NUM_PEDIDO) 
	  FROM VAGAS_DW.FATURAS 
	  WHERE COD_CLI = A.COD_CLI
	  AND TIPO_ORIGEM = 'NF'
	  AND PRODUTO IN ('VAGAS FIT ANUID','VAGAS FIT EI','VAGAS FIT LIC','VAGAS FIT REV')  
	  AND DATA_REFERENCIA = A.DATA_REFERENCIA
	  AND DATA_VENCIMENTO_REAL < GETDATE()
	  AND SALDO > 0
	  AND FLAG_PAGO = 0 ) > 1
AND STATUS_INADIMPLENCIA IS NULL
AND DATA_VENCIMENTO_REAL < GETDATE()
AND TIPO_ORIGEM = 'NF'
AND COD_NATUREZA <> '300014' -- Dep�sito a explicar (solicita��o Janice 20161011)
AND PRODUTO IN ('VAGAS FIT ANUID','VAGAS FIT EI','VAGAS FIT LIC','VAGAS FIT REV')
AND FLAG_PAGO = 0

--UPDATE VAGAS_DW.FATURAS SET STATUS_INADIMPLENCIA = 'Com Saldo Parcial Pendente'
--FROM VAGAS_DW.FATURAS A
--WHERE FLAG_PAGO = 1
--AND DATA_REFERENCIA = ( SELECT MAX(DATA_REFERENCIA) 
--						  FROM VAGAS_DW.FATURAS
--						  WHERE COD_CLI = A.COD_CLI) -- �LTIMA DATA REF.
--AND SALDO > 0 
--AND DATA_VENCIMENTO_REAL < GETDATE()
--AND STATUS_INADIMPLENCIA IS NULL
--AND TIPO_ORIGEM = 'NF'
--AND PRODUTO IN ('VAGAS FIT ANUID','VAGAS FIT EI','VAGAS FIT LIC','VAGAS FIT REV')
