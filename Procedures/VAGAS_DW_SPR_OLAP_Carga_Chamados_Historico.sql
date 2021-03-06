-- EXEC VAGAS_DW.SPR_OLAP_Carga_Chamados_Historico
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Chamados_Historico' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Chamados_Historico
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimenta??o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Chamados_Historico

AS
SET NOCOUNT ON

-- RECUPERAR DADOS ANTERIORES PARA O C?LCULO CORRETO DO TMA
INSERT INTO STAGE.VAGAS_DW.TMP_CHAMADOS_HISTORICO 
SELECT *
FROM VAGAS_DW.CHAMADOS_HISTORICO A
WHERE EXISTS ( SELECT 1 FROM STAGE.VAGAS_DW.TMP_CHAMADOS_HISTORICO 
				WHERE ID_TICKET = A.ID_TICKET
				AND ID <> A.ID ) 

--------------------- C?LCULO DATA ENVIO NORMALIZADA
-- TRATAR CASOS DE CHAMADOS ABERTOS DE S?BADO E DOMINGO
SELECT ID,ID_TICKET,DESCR_HISTORICO,TIPO_HISTORICO,ESTADO,BODY,FILA,TIPO_MSG,ORIGEM,DATA_ENVIO,USUARIO,MSG_PADRAO,PAGINA_ORIGEM,REMETENTE,DESTINATARIO,
	   DATA_ALTERACAO,
	   CASE WHEN DATEPART(WEEKDAY,DATA_ENVIO_NORMALIZADA) = 7 -- S?BADO
			THEN DATEADD(HOUR,8,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(DAY,2,DATA_ENVIO_NORMALIZADA),112)))
			WHEN DATEPART(WEEKDAY,DATA_ENVIO_NORMALIZADA) = 1 -- DOMINGO
			THEN DATEADD(HOUR,8,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(DAY,1,DATA_ENVIO_NORMALIZADA),112)))
			ELSE DATA_ENVIO_NORMALIZADA END AS DATA_ENVIO_NORMALIZADA
INTO #TMP_DATA_NORMALIZADA 
FROM 
	(
	-- TRATAR CHAMADOS ABERTOS FORA DO HOR?RIO DE EXPEDIENTE (08:00 ?S 18:00)
	SELECT ID,ID_TICKET,DESCR_HISTORICO,TIPO_HISTORICO,ESTADO,BODY,FILA,TIPO_MSG,ORIGEM,DATA_ENVIO,USUARIO,MSG_PADRAO,PAGINA_ORIGEM,REMETENTE,DESTINATARIO,
			DATA_ALTERACAO,
			CASE WHEN DATEPART(HOUR,DATA_ENVIO) >= 18 -- ESTOU DANDO UMA FOLGA DE 30 minutos ANTES DO EXPEDIENTE PARA QUE CHAMADOS ENTRE A
													  -- AS 17:30 E 18:00 N?O DISTOR?AM MUITO NEGATIVAMENTE O TMA
							THEN DATEADD(HOUR,8,DATEADD(DAY,1,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_ENVIO,112))))
							WHEN DATEPART(HOUR,DATA_ENVIO) < 7 
							THEN DATEADD(HOUR,8,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_ENVIO,112)))
							ELSE DATA_ENVIO END AS DATA_ENVIO_NORMALIZADA
	FROM STAGE.VAGAS_DW.TMP_CHAMADOS_HISTORICO
	--WHERE ID_TICKET = 246205
	--ORDER BY ID
	) TAB
ORDER BY 1

---------------------------- FIM C?LCULO DATA ENVIO NORMALIZADA

-- TRATAR FERIADOS NACIONAIS + SP 
UPDATE #TMP_DATA_NORMALIZADA SET DATA_ENVIO_NORMALIZADA = CASE
				-- se o pr?x. dia for s?bado adiantar 3 dias (seg.) 
				WHEN DATEPART(WEEKDAY,DATEADD(DAY,1,DATA_ENVIO_NORMALIZADA)) = 7 THEN DATEADD(HOUR, 8, CONVERT(SMALLDATETIME, CONVERT(VARCHAR, DATEADD(DAY,3,DATA_ENVIO_NORMALIZADA), 112))) 

				-- se o pr?x. dia for domingo adiantar 2 dias 
			 WHEN DATEPART(WEEKDAY,DATEADD(DAY,1,DATA_ENVIO_NORMALIZADA)) = 1 THEN DATEADD(HOUR, 8, CONVERT(SMALLDATETIME, CONVERT(VARCHAR, DATEADD(DAY,2,DATA_ENVIO_NORMALIZADA), 112))) 
        ELSE DATEADD(HOUR, 8, CONVERT(SMALLDATETIME, CONVERT(VARCHAR, DATEADD(DAY,1,DATA_ENVIO_NORMALIZADA), 112))) END 

FROM #TMP_DATA_NORMALIZADA A
WHERE EXISTS ( SELECT 1
				FROM VAGAS_DW.FERIADOS_NACIONAIS -- CONT?M OS FERIADOS BRA + SP ATE 2019
				WHERE DATA = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DATA_ENVIO_NORMALIZADA,112)) )


----------------------- CALCULAR TEMPO M?DIO DE ATENDIMENTO (TMA)
-----------------------------------------------------------------------------------------

DECLARE @DATA_REFERENCIA_INICIAL SMALLDATETIME,
		@DATA_REFERENCIA_FINAL SMALLDATETIME,
		@QTD_HORAS_UTEIS TINYINT = 10,
		@EXTREMIDADE_INFERIOR TINYINT = 7, -- HOR?RIO INICIO DE EXPEDIENTE
		@EXTREMIDADE_SUPERIOR TINYINT = 18 -- HOR?RIO FINAL DE EXPEDIENTE

	SELECT @DATA_REFERENCIA_INICIAL = MIN(CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_ENVIO,112))),
		@DATA_REFERENCIA_FINAL = MAX(CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_ENVIO,112))) 
	FROM #TMP_DATA_NORMALIZADA 

	;WITH CTE_DATAS 
	AS (
		SELECT @DATA_REFERENCIA_INICIAL AS DATA_REFERENCIA
		UNION ALL
		SELECT DATEADD(DAY,1,DATA_REFERENCIA) AS DATA_REFERENCIA
		FROM CTE_DATAS
		WHERE DATA_REFERENCIA < @DATA_REFERENCIA_FINAL		
		
		)
	

	-- EXISTEM CHAMADOS RE-ABERTOS COM UM PERIODO MUITO GRANDE QUE DISTORCE O TMA.
	SELECT   A.ID_TICKET,
			 A.DATA_ENVIO,
			 A.DATA_ENVIO_NORMALIZADA,
			 PROX.DATA_ENVIO_NORMALIZADA AS DATA_PROX,
			 
			 DATEDIFF(DAY,A.DATA_ENVIO_NORMALIZADA,DATEADD(DAY,1,PROX.DATA_ENVIO_NORMALIZADA)) AS QTD_DIAS,
			 
			 ( SELECT COUNT(*) FROM CTE_DATAS
			   WHERE DATA_REFERENCIA >= A.DATA_ENVIO_NORMALIZADA
			   AND DATA_REFERENCIA < PROX.DATA_ENVIO_NORMALIZADA
			   AND ( DATEPART(WEEKDAY,DATA_REFERENCIA) IN (1,7) -- CONTAR A QUANTIDADE DE S?B / DOM NO PER?ODO
					 OR  EXISTS ( SELECT 1
								  FROM VAGAS_DW.FERIADOS_NACIONAIS 
								  WHERE DATA = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DATA_ENVIO_NORMALIZADA,112)) ) ) -- SE EXISTIR FERIADO NO PER?ODO TAMB?M ABATEMOS

			    ) AS QTD_FDS, -- ABATER AS 24 HORAS DOS FINAIS DE SEMANA
			 
			 -- F?RMULA TMA
			 ( DATEDIFF(DAY,A.DATA_ENVIO_NORMALIZADA,DATEADD(DAY,1,PROX.DATA_ENVIO_NORMALIZADA)) * 10 ) -- CALCULAR HORAS CORRIDAS DE TRABALHO
			 -
			 
			 ( ( SELECT COUNT(*) FROM CTE_DATAS
			   WHERE DATA_REFERENCIA >= A.DATA_ENVIO_NORMALIZADA
			   AND DATA_REFERENCIA < PROX.DATA_ENVIO_NORMALIZADA
			   AND ( DATEPART(WEEKDAY,DATA_REFERENCIA) IN (1,7) -- CONTAR A QUANTIDADE DE S?B / DOM NO PER?ODO
					 OR  EXISTS ( SELECT 1
								  FROM VAGAS_DW.FERIADOS_NACIONAIS 
								  WHERE DATA = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DATA_ENVIO_NORMALIZADA,112)) ) ) -- SE EXISTIR FERIADO NO PER?ODO TAMB?M ABATEMOS

			    ) * @QTD_HORAS_UTEIS ) -- CALCULAR HORAS DESCONTO FINAL DE SEMANA / FERIADO
			
			-
			
			(  @QTD_HORAS_UTEIS - (@EXTREMIDADE_SUPERIOR - DATEPART(HOUR,A.DATA_ENVIO_NORMALIZADA)) ) -- CALCULAR HORAS DE DESCONTO DO INICIO EXPEDIENTE
			-
			(  @QTD_HORAS_UTEIS - ((DATEPART(HOUR,PROX.DATA_ENVIO_NORMALIZADA)) - @EXTREMIDADE_INFERIOR) ) -- CALCULAR HORAS DE DESCONTO DO INICIO EXPEDIENTE
			AS TMA,

			( SELECT COUNT(*) FROM #TMP_DATA_NORMALIZADA
			  WHERE ORIGEM = 'customer' AND ESTADO = 'open' 
			  AND ID_TICKET = A.ID_TICKET ) AS QTD_REABERTURA,

			-- BRAZ (20160801): Cria??o do novo campo TME (sem o desconto de finais de semana, feriados ou hor?rio de atendimento)
		    DATEDIFF(HOUR,A.DATA_ENVIO,PROX.DATA_ENVIO) AS TME
			
	INTO #TMA_TICKET
	FROM #TMP_DATA_NORMALIZADA A
	OUTER APPLY ( SELECT TOP 1 * 
				  FROM #TMP_DATA_NORMALIZADA B
				  WHERE B.ID_TICKET = A.ID_TICKET
				  -- COMENTADO EM 07/06/2016 POIS ALGUNS CHAMADOS N?O ESTAVAM CONTABILIZANDO O TMA
				  --AND B.ORIGEM = 'agent' 
				  AND B.ESTADO IN ('closed successful','Em andamento')
				  --AND B.TIPO_HISTORICO = 'SendAnswer'
				  AND A.ORIGEM = 'customer'
				  AND B.ID > A.ID
				  ORDER BY B.ID ASC ) PROX
	WHERE PROX.DATA_ENVIO_NORMALIZADA IS NOT NULL
	--AND A.ID_TICKET = 218460 
	ORDER BY A.ID ASC
	OPTION (MAXRECURSION 8000);

	SELECT ID_TICKET,
		   AVG(TMA) AS TMA,
		   MAX(DATA_PROX) AS DATA_ENCERRAMENTO,
		   MAX(QTD_REABERTURA) AS QTD_REABERTURA,
		   MIN(DATA_ENVIO) AS DATA_ABERTURA,
		   AVG(TME) AS TME
	INTO #TICKET_MEDIA_TMA
	FROM #TMA_TICKET
	GROUP BY ID_TICKET
	ORDER BY 1

------------------------------------------------------------ FIM C?LCULO TMA

DELETE VAGAS_DW.CHAMADOS_TMA 
FROM VAGAS_DW.CHAMADOS_TMA A
WHERE EXISTS ( SELECT 1 FROM #TICKET_MEDIA_TMA WHERE ID_TICKET = A.ID_TICKET )

-- GRAVAR REGISTRO DOS ?LTIMOS TMA's
INSERT INTO VAGAS_DW.CHAMADOS_TMA 
SELECT * FROM #TICKET_MEDIA_TMA

-- LIMPAR DA TABELA FATO ATUAL OS DADOS NOVOS/ALTERADOS QUE SER?O CARREGADOS
DELETE VAGAS_DW.CHAMADOS_HISTORICO
FROM VAGAS_DW.CHAMADOS_HISTORICO A
WHERE EXISTS ( SELECT 1 FROM #TMP_DATA_NORMALIZADA
				WHERE ID = A.ID)
				
-- CARREGAR CUBO
INSERT INTO VAGAS_DW.CHAMADOS_HISTORICO (ID,ID_TICKET,DESCR_HISTORICO,TIPO_HISTORICO,ESTADO,BODY,FILA,TIPO_MSG,ORIGEM,DATA_ENVIO,
USUARIO,MSG_PADRAO,PAGINA_ORIGEM,REMETENTE,DESTINATARIO,DATA_ALTERACAO,DATA_ENVIO_NORMALIZADA)
SELECT * FROM #TMP_DATA_NORMALIZADA


