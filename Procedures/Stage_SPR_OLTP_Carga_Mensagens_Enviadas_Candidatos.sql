USE [VAGAS_DW] ;
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Mensagens_Enviadas_Candidatos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Mensagens_Enviadas_Candidatos
GO

-- =============================================
-- Author: Fiama
-- Create date: 30/06/2017
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW.
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Mensagens_Enviadas_Candidatos @DATA_ENVIO_MSG SMALLDATETIME = NULL

AS
SET NOCOUNT ON

TRUNCATE TABLE [VAGAS_DW].[TMP_MENSAGENS_ENVIADAS_CANDIDATOS] ;

-- DROP TABLE #TMP_MSG_UNICA
SELECT	DISTINCT A.CodVaga_hist AS COD_VAGA ,
		CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.Dt_hist,112)) AS DATA_ENVIO_MSG ,
		A.CodCand_hist AS COD_CAND ,
		B.Cod_func AS COD_FUNC
INTO	#TMP_MSG_UNICA
FROM	[hrh-data].[dbo].[Historico] AS A	INNER JOIN [hrh-data].[dbo].[Funcionarios] AS B ON A.Autor_hist = B.Cod_func
WHERE	A.Tipo_hist = -107 -- Envio de mensagens
		AND A.CodVaga_hist IS NOT NULL
		AND ISNUMERIC(A.Autor_hist) = 1 -- Autor_hist contenha apenas express�es do tipo num�rico
		AND A.Dt_hist >= @DATA_ENVIO_MSG


-- MANTER APENAS 1� ENVIO
DELETE	FROM #TMP_MSG_UNICA 
FROM	#TMP_MSG_UNICA AS A
WHERE	A.DATA_ENVIO != (SELECT	MIN(A1.DATA_ENVIO) 
						 FROM   #TMP_MSG_UNICA AS A1
						 WHERE	A.COD_CAND = A1.COD_CAND
								AND A.CODVAGA_HIST = A1.CODVAGA_HIST) ;


SELECT	A.DATA_ENVIO_MSG ,
		A.COD_VAGA ,
		A.COD_FUNC ,
		COUNT(DISTINCT A.COD_CAND) AS QTD_ENVIO_MSG
INTO	#TMP_MSG
FROM	#TMP_MSG_UNICA AS A		INNER JOIN [VAGAS_DW].[VAGAS_DW].[VAGAS] AS B ON A.COD_VAGA = B.VAGAS_Cod_Vaga
WHERE	B.VAGA_ATIVA = 'N�O' 
		AND B.TIPO_PROCESSO IN (PET, PRC, RE, REDES)
		AND B.VAGA_TESTE = 'N�O'
GROUP BY 
		A.DATA_ENVIO_MSG ,
		A.COD_VAGA ,
		A.COD_FUNC
ORDER BY 1 ;


INSERT INTO [VAGAS_DW].[TMP_MENSAGENS_ENVIADAS_CANDIDATOS] (DATA_ENVIO_MSG, QTD_ENVIO_MSG, COD_VAGA, COD_FUNC)
SELECT	A.DATA_ENVIO_MSG ,
		A.QTD_ENVIO_MSG ,
		A.COD_VAGA ,
		A.COD_FUNC
FROM	#TMP_MSG AS A ;