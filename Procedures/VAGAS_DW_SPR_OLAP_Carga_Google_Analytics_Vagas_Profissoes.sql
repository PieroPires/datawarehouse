-- select * from vagas_dw.TMP_VAGAS
-- EXEC VAGAS_DW.SPR_OLAP_Carga_Google_Analytics_Vagas_Profissoes
USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Google_Analytics_Vagas_Profissoes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Google_Analytics_Vagas_Profissoes
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 22/01/2015
-- Description: Procedure para alimenta??o do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Google_Analytics_Vagas_Profissoes 
@DT_CARGA_INICIO SMALLDATETIME,
@DT_CARGA_FIM SMALLDATETIME = NULL

AS
SET NOCOUNT ON

DECLARE @CMD VARCHAR(8000),
		@DT_PROCESSAMENTO_GOOGLE_INICIO CHAR(10),
		@DT_PROCESSAMENTO_GOOGLE_FIM CHAR(10)

SET @DT_PROCESSAMENTO_GOOGLE_INICIO = SUBSTRING(CONVERT(VARCHAR,@DT_CARGA_INICIO,20),1,10)

IF @DT_CARGA_FIM IS NULL OR @DT_CARGA_FIM <= '19010131'
	SET @DT_PROCESSAMENTO_GOOGLE_FIM = SUBSTRING(CONVERT(VARCHAR,DATEADD(DAY,-1,GETDATE()),20),1,10)
ELSE
	SET @DT_PROCESSAMENTO_GOOGLE_FIM = SUBSTRING(CONVERT(VARCHAR,@DT_CARGA_FIM,20),1,10)

--SET @CMD = 'C:\"Program Files"\R\R-3.2.3\bin\x64\Rscript.exe "M:\Projetos\Scripts_R\Dados_VAGAS_PROFISSOES.R" 2014-08-12 2016-01-28'
SET @CMD = 'C:\"Program Files"\R\R-3.2.3\bin\x64\Rscript.exe " Z:\Scripts\Scripts_R\Dados_VAGAS_PROFISSOES.R" ' 
															+ @DT_PROCESSAMENTO_GOOGLE_INICIO + ' ' + @DT_PROCESSAMENTO_GOOGLE_FIM
																				 
EXEC MASTER.DBO.XP_CMDSHELL @CMD

-- Para algumas datas o campo "Date" n?o veio preenchido corretamente. Nestes casos usamos os campos Ano,mes e dia
UPDATE TMP_GOOGLE_VAGAS_PROFISSOES SET Data = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,Ano) + RIGHT('00' + CONVERT(VARCHAR,Mes),2) + RIGHT('00' + CONVERT(VARCHAR,Dia),2))
FROM TMP_GOOGLE_VAGAS_PROFISSOES 
WHERE Data IS NULL

-- Limpar tabela fato relativo ?s datas que ser?o processadas
DELETE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES A
WHERE EXISTS ( SELECT 1 FROM TMP_GOOGLE_VAGAS_PROFISSOES
				WHERE CONVERT(SMALLDATETIME,Data) = A.DATA ) 

INSERT INTO VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES (DATA,QTD_USUARIOS,QTD_PAGE_VIEWS,QTD_SESSOES,MEDIA_SESSAO)
SELECT CONVERT(SMALLDATETIME,Data) AS Data,
		Usuarios,
		PageViews,
		Sessoes,
		Media_Sessao
FROM TMP_GOOGLE_VAGAS_PROFISSOES
ORDER BY 1

-- Calculo da m?dia m?vel (30 e 60) das sess?es, usu?rios e page views
UPDATE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES SET MEDIA_MOV_30_SESSAO = MED_30.MEDIA_MOV_30,
											   MEDIA_MOV_60_SESSAO = MED_60.MEDIA_MOV_60
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES A
OUTER APPLY ( SELECT AVG(QTD_SESSOES) AS MEDIA_MOV_30
			  FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES
			  WHERE DATA >= DATEADD(DAY,-30,A.DATA)
			  AND DATA < A.DATA ) MED_30
OUTER APPLY ( SELECT AVG(QTD_SESSOES) AS MEDIA_MOV_60
			  FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES
			  WHERE DATA >= DATEADD(DAY,-60,A.DATA)
			  AND DATA < A.DATA ) MED_60
WHERE MEDIA_MOV_30_SESSAO IS NULL OR MEDIA_MOV_60_SESSAO IS NULL

UPDATE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES SET MEDIA_MOV_30_USUARIO = MED_30.MEDIA_MOV_30,
											   MEDIA_MOV_60_USUARIO = MED_60.MEDIA_MOV_60
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES A
OUTER APPLY ( SELECT AVG(QTD_USUARIOS) AS MEDIA_MOV_30
			  FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES
			  WHERE DATA >= DATEADD(DAY,-30,A.DATA)
			  AND DATA < A.DATA ) MED_30
OUTER APPLY ( SELECT AVG(QTD_USUARIOS) AS MEDIA_MOV_60
			  FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES
			  WHERE DATA >= DATEADD(DAY,-60,A.DATA)
			  AND DATA < A.DATA ) MED_60
WHERE MEDIA_MOV_30_USUARIO IS NULL OR MEDIA_MOV_60_USUARIO IS NULL

UPDATE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES SET MEDIA_MOV_30_PAGE_VIEW = MED_30.MEDIA_MOV_30,
											   MEDIA_MOV_60_PAGE_VIEW = MED_60.MEDIA_MOV_60
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES A
OUTER APPLY ( SELECT AVG(QTD_PAGE_VIEWS) AS MEDIA_MOV_30
			  FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES
			  WHERE DATA >= DATEADD(DAY,-30,A.DATA)
			  AND DATA < A.DATA ) MED_30
OUTER APPLY ( SELECT AVG(QTD_PAGE_VIEWS) AS MEDIA_MOV_60
			  FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES
			  WHERE DATA >= DATEADD(DAY,-60,A.DATA)
			  AND DATA < A.DATA ) MED_60
WHERE MEDIA_MOV_30_PAGE_VIEW IS NULL OR MEDIA_MOV_60_PAGE_VIEW IS NULL

-- INICIO ROTINA DE C?LCULO DO "NEW RETURNING VISITOR" (Usu?rios 30 dias ativos)
DELETE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS 
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS A
WHERE EXISTS ( SELECT 1 FROM TMP_GOOGLE_VAGAS_PROFISSOES_USUARIOS_ATIVOS
				WHERE CONVERT(SMALLDATETIME,Data) = A.DATA ) 

INSERT INTO VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS (DATA,QTD_USUARIOS_ATIVOS)
SELECT CONVERT(SMALLDATETIME,A.Data) AS Data,
		Usuarios
FROM TMP_GOOGLE_VAGAS_PROFISSOES_USUARIOS_ATIVOS A

-- ATUALIZAR % NEW VISITORS
UPDATE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS SET PERC_NEW_VISITOR = B.PERC_NEW_VISITOR
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS A
INNER JOIN TMP_GOOGLE_VAGAS_PROFISSOES_NOVOS_USUARIOS B ON B.Ano = YEAR(A.DATA) AND B.Mes = MONTH(A.DATA)

UPDATE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS SET PERC_RETURNING_VISITOR = 100 - A.PERC_NEW_VISITOR
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS A
INNER JOIN TMP_GOOGLE_VAGAS_PROFISSOES_NOVOS_USUARIOS B ON B.Ano = YEAR(A.DATA) AND B.Mes = MONTH(A.DATA)

-- MANTER APENAS ?LTIMO REGISTRO DO M?S
DELETE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS 
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS 
				WHERE MONTH(DATA) = MONTH(A.DATA) AND YEAR(DATA) = YEAR(A.DATA)
				AND DATA > A.DATA ) 

-- Atualizar totalizador de sess?o e aplicar convers?o (baseado no acumulado de sessoes mensais)
UPDATE VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS 
SET QTD_SESSOES = B.QTD_SESSOES,
	PERC_USUARIOS_ATIVOS = CASE WHEN B.QTD_SESSOES IS NOT NULL AND B.QTD_SESSOES <> 0 
								THEN CONVERT(FLOAT,A.QTD_USUARIOS_ATIVOS) / CONVERT(FLOAT,B.QTD_SESSOES)
								ELSE 0 END										
FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES_NEW_RETURNING_VISITORS A
OUTER APPLY ( SELECT SUM(QTD_SESSOES) AS QTD_SESSOES FROM VAGAS_DW.ANALYTICS_VAGAS_PROFISSOES 
			  WHERE MONTH(DATA) = MONTH(A.DATA) AND YEAR(DATA) = YEAR(A.DATA) ) B

