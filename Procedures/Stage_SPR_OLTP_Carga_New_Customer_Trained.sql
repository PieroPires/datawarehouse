-- =============================================
-- Author: Fiama
-- Create date: 13/02/2019
-- Description: Procedure para carga na tabela STAGE
-- =============================================
-- 27/02/2019: Removido o crit?rio de recorte dos Novos clientes a partir de 01/01/2018.

USE [STAGE] ;

IF EXISTS ( SELECT	* FROM SYS.OBJECTS WHERE SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW' AND NAME = 'Stage_SPR_OLTP_Carga_New_Customer_Trained')
DROP PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_New_Customer_Trained] ;
GO

CREATE PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_New_Customer_Trained]
AS
SET NOCOUNT ON

-- Limpeza da tabela tempor?ria:
TRUNCATE TABLE [VAGAS_DW].[TMP_NEW_CUSTOMER_TRAINED] ;


-- Carga na tabela tempor?ria:
INSERT INTO [VAGAS_DW].[TMP_NEW_CUSTOMER_TRAINED] (CONTA_ID, CONTA_CRM, DATA_ENTRADA, DATA_TREINAMENTO, MERCADO, HOUVE_TREINAMENTO, TEMPO_MESES_FECHADO_TREINADO,  TREINAMENTO_MESES_SLA, TEMPO_MESES_NAO_TREINADO, NOVOS_TREINADOS, NOVOSNAO_TREINADOS, INDICADOR_TREINAMENTO, FAIXA_CONTROLE_INDICADOR)
SELECT	DISTINCT A.CONTAID AS Id_ContaCRM ,
		A.CONTA AS CONTA_CRM ,
		CONVERT(DATE, A.DATAFECHAMENTO) AS Data_Fechamento ,
		ISNULL(CONVERT(DATE, C.DATA_REALIZACAO_INICIO), '19000101') AS Data_Treinamento ,
		ISNULL(B.MERCADO, 'N?O CLASSIFICADO') AS MERCADO ,
		IIF(C.DATA_REALIZACAO_INICIO IS NULL, 'N?O', 'SIM') Houve_Treinamento ,
		ROUND(CONVERT(FLOAT, DATEDIFF(DAY, A.DATAFECHAMENTO, C.DATA_REALIZACAO_INICIO)) / 30, 2) AS Meses_Fechamento_Treinamento ,
		IIF(ROUND(CONVERT(FLOAT, DATEDIFF(DAY, A.DATAFECHAMENTO, C.DATA_REALIZACAO_INICIO)) / 30, 2) <= 3, 'SIM', 'N?O') AS TreinamentoMeses_SLA ,
		IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0) AS TempoMesesSemTreinamento ,
		IIF(C.DATA_REALIZACAO_INICIO IS NULL, 0, 1) AS NOVOS_TREINADOS ,
		IIF(C.DATA_REALIZACAO_INICIO IS NULL, 1, 0) AS NOVOSNAO_TREINADOS ,
		CASE
			WHEN C.DATA_REALIZACAO_INICIO IS NULL AND IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0) = 0
				THEN '1 M?s'
			WHEN C.DATA_REALIZACAO_INICIO IS NULL AND IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0) = 1
				THEN '2 M?s'
			WHEN C.DATA_REALIZACAO_INICIO IS NULL AND IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0) = 2
				THEN '3 M?s'
			WHEN C.DATA_REALIZACAO_INICIO IS NULL AND IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0) > 2
				THEN 'Acima de 3 Meses'
			ELSE 'Treinado'
		END AS INDICADOR_TREINAMENTO ,
		IIF(C.DATA_REALIZACAO_INICIO IS NULL,
			IIF(IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0)=0, 1,
			IIF(IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0)=1, 2,
			IIF(IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0)=2, 3,
			IIF(IIF(C.DATA_REALIZACAO_INICIO IS NULL, DATEDIFF(MONTH, CONVERT(DATE, A.DATAFECHAMENTO), CONVERT(DATE, GETDATE())), 0)>2, 4, 0)))), 0) AS FAIXA
FROM	[VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A		LEFT OUTER JOIN [VAGAS_DW].[VAGAS_DW].[CLIENTES] AS B ON A.CONTAID = B.CONTA_ID
											OUTER APPLY(SELECT	TOP 1 *
														FROM	[VAGAS_DW].[VAGAS_DW].[TREINAMENTOS_CRM] AS A1
														WHERE	A.CONTAID = A1.CONTA_ID
																AND A1.[STATUS] = 'REALIZADO'
																AND A1.DATA_REALIZACAO_INICIO >= DATEADD(DAY, 1, DATEADD(DAY, DATEPART(DAY, A.DATAFECHAMENTO) * -1,																				A.DATAFECHAMENTO))
														ORDER BY
																	A1.DATA_REALIZACAO_INICIO ASC ) AS C

											OUTER APPLY(SELECT	TOP 1 *
														FROM	[VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
														WHERE	A.CONTAID = A1.CONTAID
																AND A1.Fase = 'fechado_e_ganho'
														ORDER BY
																A1.DataFechamento DESC ) AS D
WHERE	A.Fase = 'fechado_e_ganho'
		AND A.OportunidadeCategoria IN ('cliente_potencial', 'cliente_cotacao')
		AND A.PRODUTO_GRUPO IN ('FIT', 'RECRUTADOR', 'REDES')
		AND A.RECORRENTE = 1
		--AND A.DataFechamento >= '20180101'
		AND D.OportunidadeCategoria <> 'rescis?o' -- Exclui contas onde a ?ltima oportunidade ? de rescis?o.
		AND NOT EXISTS (SELECT	1
						FROM	[VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
						WHERE	A.CONTAID = A1.CONTAID
							AND A1.Fase = 'fechado_e_ganho'
							AND A1.PRODUTO_GRUPO IN ('FIT', 'RECRUTADOR', 'REDES')
							AND A1.RECORRENTE = 1
							--AND A1.DataFechamento >= '20180101'
							AND A1.OportunidadeCategoria = 'rescis?o'
							AND A1.DataFechamento > A.DataFechamento )
		AND A.DataFechamento = (SELECT	MIN(A1.DataFechamento)
								FROM	[VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS A1
								WHERE	A.CONTAID = A1.CONTAID
										AND A1.Fase = 'fechado_e_ganho'
										AND A1.OportunidadeCategoria IN ('cliente_potencial', 'cliente_cotacao')
										AND A1.PRODUTO_GRUPO IN ('FIT', 'RECRUTADOR', 'REDES')
										AND A1.RECORRENTE = 1
										--AND A1.DataFechamento >= '20180101'
										AND D.OportunidadeCategoria <> 'rescis?o' -- Exclui contas onde a ?ltima oportunidade ? de rescis?o.
										AND NOT EXISTS (SELECT	1
														FROM	[VAGAS_DW].[VAGAS_DW].[OPORTUNIDADES] AS AA1
														WHERE	A1.CONTAID = AA1.CONTAID
																AND AA1.Fase = 'fechado_e_ganho'
																AND AA1.PRODUTO_GRUPO IN ('FIT', 'RECRUTADOR', 'REDES')
																AND AA1.RECORRENTE = 1
																--AND AA1.DataFechamento >= '20180101'
																AND AA1.OportunidadeCategoria = 'rescis?o'																
																AND	AA1.DataFechamento > A1.DataFechamento )  ) ;