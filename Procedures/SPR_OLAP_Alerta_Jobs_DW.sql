USE [VAGAS_DW] ;
GO

-- =============================================
-- Author: Fiama
-- Create date: 17/05/2017
-- Description: Script para alerta de falhas nos JOBs do DW
-- =============================================

IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_ALERTA_JOBS_DW' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[SPR_OLAP_ALERTA_JOBS_DW]
GO

CREATE PROCEDURE [VAGAS_DW].[SPR_OLAP_ALERTA_JOBS_DW]
AS


DECLARE	@PROFILE_NAME VARCHAR(256) ,
		@RECIPIENTS VARCHAR(MAX) ,
		@COPY_RECIPIENTS VARCHAR(MAX) ,
		@SUBJECT NVARCHAR(255) ,
		@BODY NVARCHAR(MAX) = '' ;


SET	@PROFILE_NAME = N'SQL SERVER AGENT' ;
SET	@RECIPIENTS = 'fiama.cristi@vagas.com.br' ;
SET @COPY_RECIPIENTS = NULL ;

-- Envia um alerta para notificar erro no JOB 'PKG - Executar Carga DW - (D-1)':
IF EXISTS (SELECT TOP 1 1
		   FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A
		   WHERE A.RUN_STATUS = 0
				 AND A.STEP_NAME != '(Job outcome)'
				 AND A.JOB_ID =  (SELECT A1.JOB_ID
								  FROM	[MSDB].[DBO].[SYSJOBS] AS A1
								  WHERE	A1.NAME = 'PKG - Executar Carga DW - (D-1)')
				 AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 112))
				 AND LEN(A.RUN_TIME) = 6
				 AND LEFT(A.RUN_TIME, 2) >= 18) AND DATEPART(HOUR, GETDATE()) < 13 

BEGIN
	SET	@SUBJECT = (SELECT	TOP 1 '[Failed] SQL Server Job System: ' + B.NAME
					FROM	[MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					WHERE	A.RUN_STATUS = 0
							AND A.STEP_NAME != '(Job outcome)'
							AND A.JOB_ID = (SELECT	A1.JOB_ID
											FROM	[MSDB].[DBO].[SYSJOBS] AS A1
											WHERE	A1.NAME = 'PKG - Executar Carga DW - (D-1)')
							AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 112))
							AND LEN(A.RUN_TIME) = 6
							AND LEFT(A.RUN_TIME, 2) >= 18) ;
		


	SET @BODY = (SELECT STUFF(
					(SELECT ' The step failed:' + ' ' + A.STEP_NAME + CHAR(10) , + 
							'Message Error:' + ' ' + A.[MESSAGE]  + CHAR(10) + CHAR(10) AS [text()] 
					 FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					 WHERE	 A.RUN_STATUS = 0
							 AND A.STEP_NAME != '(Job outcome)'
							 AND LEN(A.RUN_TIME) = 6
							 AND LEFT(A.RUN_TIME, 2) >= 18
							 AND A.JOB_ID IN (SELECT JOB_ID
											  FROM	[MSDB].[DBO].[SYSJOBS]
											  WHERE	NAME = 'PKG - Executar Carga DW - (D-1)')
							 AND RUN_DATE = (SELECT CONVERT(CHAR(8), DATEADD(DAY, -1, CAST(GETDATE() AS DATE)), 112)) FOR XML PATH('')), 1, 1, ''))


	EXEC [MSDB].[DBO].SP_SEND_DBMAIL
		@PROFILE_NAME = @PROFILE_NAME ,
		@RECIPIENTS = @RECIPIENTS ,
		@COPY_RECIPIENTS = @COPY_RECIPIENTS ,
		@BODY = @BODY ,
		@SUBJECT = @SUBJECT
END


-- Envia um alerta para notificar erro no JOB 'PKG - Executar Carga DW - (HORA EM HORA)':
IF EXISTS (SELECT 1
		   FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A
		   WHERE A.RUN_STATUS = 0
				 AND A.STEP_NAME != '(Job outcome)'
				 AND A.JOB_ID =  (SELECT A1.JOB_ID
								  FROM	[MSDB].[DBO].[SYSJOBS] AS A1
								  WHERE	A1.NAME = 'PKG - Executar Carga DW - (HORA EM HORA)')
				 AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)))

BEGIN
	SET	@SUBJECT = (SELECT	TOP 1 '[Failed] SQL Server Job System: ' + B.NAME
					FROM	[MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					WHERE	A.RUN_STATUS = 0
							AND A.STEP_NAME != '(Job outcome)'
							AND A.JOB_ID = (SELECT	A1.JOB_ID
											FROM	[MSDB].[DBO].[SYSJOBS] AS A1
											WHERE	A1.NAME = 'PKG - Executar Carga DW - (HORA EM HORA)')
							AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112))) ;
		


	SET @BODY = (SELECT STUFF(
					(SELECT ' The step failed:' + ' ' + A.STEP_NAME + CHAR(10) , + 
							'Message Error:' + ' ' + A.[MESSAGE]  + CHAR(10) + CHAR(10) AS [text()] 
					 FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					 WHERE	 A.RUN_STATUS = 0
							 AND A.STEP_NAME != '(Job outcome)'
							 AND A.JOB_ID IN (SELECT JOB_ID
											  FROM	[MSDB].[DBO].[SYSJOBS]
											  WHERE	NAME = 'PKG - Executar Carga DW - (HORA EM HORA)')
							 AND RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)) FOR XML PATH('')), 1, 1, ''))


	EXEC [MSDB].[DBO].SP_SEND_DBMAIL
		@PROFILE_NAME = @PROFILE_NAME ,
		@RECIPIENTS = @RECIPIENTS ,
		@COPY_RECIPIENTS = @COPY_RECIPIENTS ,
		@BODY = @BODY ,
		@SUBJECT = @SUBJECT
END


-- Envia um alerta para notificar erro no JOB 'PKG - Executar Carga DW (12:00)':
IF EXISTS (SELECT 1
		   FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A
		   WHERE A.RUN_STATUS = 0
				 AND A.STEP_NAME != '(Job outcome)'
				 AND A.JOB_ID =  (SELECT A1.JOB_ID
								  FROM	[MSDB].[DBO].[SYSJOBS] AS A1
								  WHERE	A1.NAME = 'PKG - Executar Carga DW (12:00)')
				 AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)))

BEGIN
	SET	@SUBJECT = (SELECT	TOP 1 '[Failed] SQL Server Job System: ' + B.NAME
					FROM	[MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					WHERE	A.RUN_STATUS = 0
							AND A.STEP_NAME != '(Job outcome)'
							AND A.JOB_ID = (SELECT	A1.JOB_ID
											FROM	[MSDB].[DBO].[SYSJOBS] AS A1
											WHERE	A1.NAME = 'PKG - Executar Carga DW (12:00)')
							AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112))) ;
		


	SET @BODY = (SELECT STUFF(
					(SELECT ' The step failed:' + ' ' + A.STEP_NAME + CHAR(10) , + 
							'Message Error:' + ' ' + A.[MESSAGE]  + CHAR(10) + CHAR(10) AS [text()] 
					 FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					 WHERE	 A.RUN_STATUS = 0
							 AND A.STEP_NAME != '(Job outcome)'
							 AND A.JOB_ID IN (SELECT JOB_ID
											  FROM	[MSDB].[DBO].[SYSJOBS]
											  WHERE	NAME = 'PKG - Executar Carga DW (12:00)')
							 AND RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)) FOR XML PATH('')), 1, 1, ''))


	EXEC [MSDB].[DBO].SP_SEND_DBMAIL
		@PROFILE_NAME = @PROFILE_NAME ,
		@RECIPIENTS = @RECIPIENTS ,
		@COPY_RECIPIENTS = @COPY_RECIPIENTS ,
		@BODY = @BODY ,
		@SUBJECT = @SUBJECT
END


-- Envia um alerta para notificar erro no JOB 'PKG - Executar Carga DW (QUINZENAL)':
IF EXISTS (SELECT 1
		   FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A
		   WHERE A.RUN_STATUS = 0
				 AND A.STEP_NAME != '(Job outcome)'
				 AND A.JOB_ID =  (SELECT A1.JOB_ID
								  FROM	[MSDB].[DBO].[SYSJOBS] AS A1
								  WHERE	A1.NAME = 'PKG - Executar Carga DW (QUINZENAL)')
				 AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)))

BEGIN
	SET	@SUBJECT = (SELECT	TOP 1 '[Failed] SQL Server Job System: ' + B.NAME
					FROM	[MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					WHERE	A.RUN_STATUS = 0
							AND A.STEP_NAME != '(Job outcome)'
							AND A.JOB_ID = (SELECT	A1.JOB_ID
											FROM	[MSDB].[DBO].[SYSJOBS] AS A1
											WHERE	A1.NAME = 'PKG - Executar Carga DW (QUINZENAL)')
							AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112))) ;
		


	SET @BODY = (SELECT STUFF(
					(SELECT ' The step failed:' + ' ' + A.STEP_NAME + CHAR(10) , + 
							'Message Error:' + ' ' + A.[MESSAGE]  + CHAR(10) + CHAR(10) AS [text()] 
					 FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					 WHERE	 A.RUN_STATUS = 0
							 AND A.STEP_NAME != '(Job outcome)'
							 AND A.JOB_ID IN (SELECT JOB_ID
											  FROM	[MSDB].[DBO].[SYSJOBS]
											  WHERE	NAME = 'PKG - Executar Carga DW (QUINZENAL)')
							 AND RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)) FOR XML PATH('')), 1, 1, ''))


	EXEC [MSDB].[DBO].SP_SEND_DBMAIL
		@PROFILE_NAME = @PROFILE_NAME ,
		@RECIPIENTS = @RECIPIENTS ,
		@COPY_RECIPIENTS = @COPY_RECIPIENTS ,
		@BODY = @BODY ,
		@SUBJECT = @SUBJECT
END


-- Envia um alerta para notificar erro no JOB 'PKG - Executar Carga DW (SEMANAL)':
IF EXISTS (SELECT 1
		   FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A
		   WHERE A.RUN_STATUS = 0
				 AND A.STEP_NAME != '(Job outcome)'
				 AND A.JOB_ID =  (SELECT A1.JOB_ID
								  FROM	[MSDB].[DBO].[SYSJOBS] AS A1
								  WHERE	A1.NAME = 'PKG - Executar Carga DW (SEMANAL)')
				 AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)))

BEGIN
	SET	@SUBJECT = (SELECT	TOP 1 '[Failed] SQL Server Job System: ' + B.NAME
					FROM	[MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					WHERE	A.RUN_STATUS = 0
							AND A.STEP_NAME != '(Job outcome)'
							AND A.JOB_ID = (SELECT	A1.JOB_ID
											FROM	[MSDB].[DBO].[SYSJOBS] AS A1
											WHERE	A1.NAME = 'PKG - Executar Carga DW (SEMANAL)')
							AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112))) ;
		


	SET @BODY = (SELECT STUFF(
					(SELECT ' The step failed:' + ' ' + A.STEP_NAME + CHAR(10) , + 
							'Message Error:' + ' ' + A.[MESSAGE]  + CHAR(10) + CHAR(10) AS [text()] 
					 FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					 WHERE	 A.RUN_STATUS = 0
							 AND A.STEP_NAME != '(Job outcome)'
							 AND A.JOB_ID IN (SELECT JOB_ID
											  FROM	[MSDB].[DBO].[SYSJOBS]
											  WHERE	NAME = 'PKG - Executar Carga DW (SEMANAL)')
							 AND RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)) FOR XML PATH('')), 1, 1, ''))


	EXEC [MSDB].[DBO].SP_SEND_DBMAIL
		@PROFILE_NAME = @PROFILE_NAME ,
		@RECIPIENTS = @RECIPIENTS ,
		@COPY_RECIPIENTS = @COPY_RECIPIENTS ,
		@BODY = @BODY ,
		@SUBJECT = @SUBJECT
END




-- Envia um alerta para notificar erro no JOB 'PKG - Executar Carga DW (MENSAL)':
IF EXISTS (SELECT 1
		   FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A
		   WHERE A.RUN_STATUS = 0
				 AND A.STEP_NAME != '(Job outcome)'
				 AND A.JOB_ID =  (SELECT A1.JOB_ID
								  FROM	[MSDB].[DBO].[SYSJOBS] AS A1
								  WHERE	A1.NAME = 'PKG - Executar Carga DW (MENSAL)')
				 AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)))

BEGIN
	SET	@SUBJECT = (SELECT	TOP 1 '[Failed] SQL Server Job System: ' + B.NAME
					FROM	[MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					WHERE	A.RUN_STATUS = 0
							AND A.STEP_NAME != '(Job outcome)'
							AND A.JOB_ID = (SELECT	A1.JOB_ID
											FROM	[MSDB].[DBO].[SYSJOBS] AS A1
											WHERE	A1.NAME = 'PKG - Executar Carga DW (MENSAL)')
							AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112))) ;
		


	SET @BODY = (SELECT STUFF(
					(SELECT ' The step failed:' + ' ' + A.STEP_NAME + CHAR(10) , + 
							'Message Error:' + ' ' + A.[MESSAGE]  + CHAR(10) + CHAR(10) AS [text()] 
					 FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					 WHERE	 A.RUN_STATUS = 0
							 AND A.STEP_NAME != '(Job outcome)'
							 AND A.JOB_ID IN (SELECT JOB_ID
											  FROM	[MSDB].[DBO].[SYSJOBS]
											  WHERE	NAME = 'PKG - Executar Carga DW (MENSAL)')
							 AND RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)) FOR XML PATH('')), 1, 1, ''))


	EXEC [MSDB].[DBO].SP_SEND_DBMAIL
		@PROFILE_NAME = @PROFILE_NAME ,
		@RECIPIENTS = @RECIPIENTS ,
		@COPY_RECIPIENTS = @COPY_RECIPIENTS ,
		@BODY = @BODY ,
		@SUBJECT = @SUBJECT
END

-- Envia um alerta para notificar erro no JOB 'PKG - Executar Carga DW - (Integra��o SenseData)':
IF EXISTS (SELECT 1
		   FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A
		   WHERE A.RUN_STATUS = 0
				 AND A.STEP_NAME != '(Job outcome)'
				 AND A.JOB_ID =  (SELECT A1.JOB_ID
								  FROM	[MSDB].[DBO].[SYSJOBS] AS A1
								  WHERE	A1.NAME = 'Integra��o SenseData')
				 AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)))

BEGIN
	SET	@SUBJECT = (SELECT	TOP 1 '[Failed] SQL Server Job System: ' + B.NAME
					FROM	[MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					WHERE	A.RUN_STATUS = 0
							AND A.STEP_NAME != '(Job outcome)'
							AND A.JOB_ID = (SELECT	A1.JOB_ID
											FROM	[MSDB].[DBO].[SYSJOBS] AS A1
											WHERE	A1.NAME = 'Integra��o SenseData')
							AND A.RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112))) ;
		


	SET @BODY = (SELECT STUFF(
					(SELECT ' The step failed:' + ' ' + A.STEP_NAME + CHAR(10) , + 
							'Message Error:' + ' ' + A.[MESSAGE]  + CHAR(10) + CHAR(10) AS [text()] 
					 FROM	 [MSDB].[DBO].[SYSJOBHISTORY] AS A	INNER JOIN [MSDB].[DBO].[SYSJOBS] AS B ON A.JOB_ID = B.JOB_ID
																INNER JOIN [MSDB].[DBO].[SYSJOBSTEPS] AS C ON B.JOB_ID = C.JOB_ID AND A.STEP_ID = C.STEP_ID
					 WHERE	 A.RUN_STATUS = 0
							 AND A.STEP_NAME != '(Job outcome)'
							 AND A.JOB_ID IN (SELECT JOB_ID
											  FROM	[MSDB].[DBO].[SYSJOBS]
											  WHERE	NAME = 'Integra��o SenseData')
							 AND RUN_DATE = (SELECT CONVERT(CHAR(8), CAST(GETDATE() AS DATE), 112)) FOR XML PATH('')), 1, 1, ''))


	EXEC [MSDB].[DBO].SP_SEND_DBMAIL
		@PROFILE_NAME = @PROFILE_NAME ,
		@RECIPIENTS = @RECIPIENTS ,
		@COPY_RECIPIENTS = @COPY_RECIPIENTS ,
		@BODY = @BODY ,
		@SUBJECT = @SUBJECT
END