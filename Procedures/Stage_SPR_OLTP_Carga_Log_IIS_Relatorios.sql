-- EXEC VAGAS_DW.SPR_OLTP_Carga_Log_IIS_Relatorios '20160515','20160516'
USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Log_IIS_Relatorios' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Log_IIS_Relatorios
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 15/05/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW [processo de auditoria de execu��o dos relat�rios
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Log_IIS_Relatorios 
@DT_INICIO SMALLDATETIME = NULL, -- DATA DE CRIA��O DOS ARQUIVOS DE LOG
@DT_FIM SMALLDATETIME = NULL, -- DATA DE CRIA��O DOS ARQUIVOS DE LOG
--@DIRETORIO_LOGS VARCHAR(400) = '\\sharepoint\c$\inetpub\logs\LogFiles\W3SVC1835615947\', -- DIRET�RIO PADR�O DO SITE SHAREPOINT + OFFICE WEB APPS
@DIRETORIO_LOGS VARCHAR(400) = '\\sharepoint\c$\inetpub\logs\AdvancedLogs\"VAGAS - 80"\', -- DIRET�RIO PADR�O DO SITE SHAREPOINT + OFFICE WEB APPS
@DIRETORIO_CSV VARCHAR(200) = 'M:\TMP\LOG_IIS_RELATORIOS\' -- DIRET�RIO DE SA�DA DO ARQUIVO FORMATADO .CSV

AS
SET NOCOUNT ON

IF @DT_INICIO IS NULL
SET @DT_INICIO = '20160517' -- DATA EM QUE INICIAMOS A COLETA DOS LOGS NO FORMATO CORRENTE

IF @DT_FIM IS NULL
SET @DT_FIM = DATEADD(DAY,1,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)))

TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS 
TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_LOG_IIS

CREATE TABLE #TMP_ARQUIVOS_LOG (ID_ARQUIVO_LOG SMALLINT IDENTITY PRIMARY KEY,NOME_ARQUIVO VARCHAR(255),DATA_ARQUIVO SMALLDATETIME)

DECLARE @CMD VARCHAR(8000)
	
SET @CMD = 'DIR ' + @DIRETORIO_LOGS + '/B'

INSERT INTO #TMP_ARQUIVOS_LOG (NOME_ARQUIVO)
EXEC MASTER.DBO.XP_CMDSHELL @CMD

DELETE FROM #TMP_ARQUIVOS_LOG WHERE NOME_ARQUIVO IS NULL

--UPDATE #TMP_ARQUIVOS_LOG SET DATA_ARQUIVO = CONVERT(SMALLDATETIME,'20' + LEFT(REPLACE(REPLACE(NOME_ARQUIVO,'u_ex','') ,'.log',''),2) + -- ANO
--	SUBSTRING(REPLACE(REPLACE(NOME_ARQUIVO,'u_ex','') ,'.log',''),3,2) + -- M�S
--	RIGHT(REPLACE(REPLACE(NOME_ARQUIVO,'u_ex','') ,'.log',''),2)) -- DIA
--FROM #TMP_ARQUIVOS_LOG

UPDATE #TMP_ARQUIVOS_LOG SET DATA_ARQUIVO = CONVERT(SMALLDATETIME,SUBSTRING(NOME_ARQUIVO,23,8))
FROM #TMP_ARQUIVOS_LOG 

DELETE FROM #TMP_ARQUIVOS_LOG WHERE DATA_ARQUIVO < @DT_INICIO OR DATA_ARQUIVO > @DT_FIM

	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN ID_GRUPO 
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN ID
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN ACCESS_TOKEN 
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN SEGMENTACAO
	

DECLARE @ID_ARQUIVO_LOG SMALLINT,@NOME_ARQUIVO VARCHAR(255),@DATA_ARQUIVO SMALLDATETIME

SELECT TOP 1 @ID_ARQUIVO_LOG = ID_ARQUIVO_LOG,@NOME_ARQUIVO = NOME_ARQUIVO,@DATA_ARQUIVO = DATA_ARQUIVO
FROM #TMP_ARQUIVOS_LOG 
ORDER BY 1 ASC

-- LOOP PARA IMPORTA��O DE CADA UM DOS ARQUIVOS
WHILE @@ROWCOUNT > 0
BEGIN
	TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_LOG_IIS
	PRINT 'Processando arquivo : ' + @NOME_ARQUIVO
	
	--SELECT * FROM VAGAS_DW.VAGAS_DW.TMP_LOG_IIS

	--SET @CMD = 'powershell "Get-Content ' + @DIRETORIO_LOGS + 
	--			'\' + @NOME_ARQUIVO + ' |%{$_ -replace ''#Fields: '', ''''} |?{$_ -notmatch ''^#''} | ConvertFrom-Csv -Delimiter '' '' | Export-Csv ' + @DIRETORIO_CSV + 'LOG_FILE_IIS_OUT.csv"'
	
	SET @CMD = 'powershell "Get-Content ' + REPLACE(@DIRETORIO_LOGS,'"','''') + 
			    + @NOME_ARQUIVO + ' |%{$_ -replace ''#Fields:  '', ''''} |?{$_ -notmatch ''^#''} | ConvertFrom-Csv -Delimiter '' '' | Export-Csv ' + @DIRETORIO_CSV + 'LOG_FILE_IIS_OUT.csv"'
	
	-- Get-Content \\sharepoint\c$\inetpub\logs\AdvancedLogs\"VAGAS - 80"\Auditoria_Relatorios_D20160516-175450372.log |%{$_ -replace '#Fields:  ', ''} |?{$_ -notmatch '^#'} | ConvertFrom-Csv -Delimiter ' ' | Export-Csv M:\TMP\LOG_IIS_RELATORIOS\LOG_FILE_IIS_OUT_TESTE.csv

	-- BUSCAR .LOG DO SERVIDOR DO SHAREPOINT / OFFICE WEB APPS
	print @CMD
	EXEC MASTER.DBO.XP_CMDSHELL @CMD

	SET @CMD = 'BULK INSERT [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] 
				FROM ''' + @DIRETORIO_CSV + 'LOG_FILE_IIS_OUT.csv''
				WITH (      FIELDTERMINATOR = '','',
							FIRSTROW =1,
							ROWTERMINATOR = '''+CHAR(10)+''')'
	-- IMPORTAR DADOS .CSV
	PRINT @CMD
	EXEC(@CMD)

	-- ADICIONAR COLUNAS NECESS�RIAS PARA O CORRETO C�LCULO POR "ACCESS_TOKEN"	
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD ID INT IDENTITY 
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD ID_GRUPO INT
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD ACCESS_TOKEN VARCHAR(50)
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD SEGMENTACAO VARCHAR(50)


	-- GERAR IDENTIFICA��O UNICA POR ACCESS_TOKEN (EM ALGUMAS SITUA��ES O MESMO TOKEN � GERADO PARA UMA NOVA CONSULTA) NESTE CASO VAMOS TRATAR PELA DIFEREN�A M�XIMA ENTRE ELAS
	SELECT ID,
		REPLACE(REPLACE(SUBSTRING([cs-uri-query],CHARINDEX('access_token_ttl',[cs-uri-query]),LEN([cs-uri-query])),'"',''),'access_token_ttl=','') AS ACCESS_TOKEN,
		ROW_NUMBER() OVER (PARTITION BY REPLACE(REPLACE(SUBSTRING([cs-uri-query],CHARINDEX('access_token_ttl',[cs-uri-query]),LEN([cs-uri-query])),'"',''),'access_token_ttl=','')
										ORDER BY CONVERT(TIME,REPLACE([time],'"','')) ASC ) AS ID_GRUPO
	INTO #TMP_ID_GRUPO
	FROM [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] 
	WHERE [cs-uri-stem] LIKE '%wopi.ashx%'

	-- PEGAR ACCESS TOKEN E ATUALIZAR O IDENTIFICADOR UNICO POR ACCESS_TOKEN
	UPDATE  [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] SET ID_GRUPO = B.ID_GRUPO,
													ACCESS_TOKEN = B.ACCESS_TOKEN			
	FROM [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] A
	INNER JOIN #TMP_ID_GRUPO B ON B.ID = A.ID

	-- CALCULAR DIFERENCA DE TEMPO ENTRE UM MESMO ACCESS_TOKEN
	SELECT A.ACCESS_TOKEN
		,A.ID
		,CONVERT(DATETIME,REPLACE(A.[DATE],'"','') + ' ' + REPLACE(A.[TIME],'"','')) AS DATA
		,A.ID_GRUPO AS ID_GRUPO
		,DATEDIFF(MINUTE,CONVERT(TIME,REPLACE(A.[time],'"','')),CONVERT(TIME,REPLACE(B.[time],'"',''))) AS DIF_MINUTOS
		,CONVERT(VARCHAR(250),'') AS SEGMENTACAO
	INTO #TMP_GRUPO_ACCESS_TOKEN
	FROM [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] A
	OUTER APPLY ( SELECT TOP 1 * FROM [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] 
				  WHERE ACCESS_TOKEN = A.ACCESS_TOKEN 
				  AND ID_GRUPO > A.ID_GRUPO
				  ORDER BY ID_GRUPO ASC ) B
	WHERE A.[cs-uri-stem] LIKE '%wopi.ashx%' 

	-- CASO EXISTA UMA DIFEREN�A ENTRE UMA CHAMADA AJAX E OUTRA MAIOR DO QUE 10 MIN. PARA UM MESMO ACCESS_TOKEN 
	-- MARCAMOS ELAS EM GRUPOS DIFERENTES PARA O CORRETO CALCULO DA DURA��O DA SESS�O
	UPDATE #TMP_GRUPO_ACCESS_TOKEN SET SEGMENTACAO = B.ID_GRUPO
	FROM #TMP_GRUPO_ACCESS_TOKEN A
	OUTER APPLY ( SELECT TOP 1 * FROM #TMP_GRUPO_ACCESS_TOKEN
					WHERE ACCESS_TOKEN = A.ACCESS_TOKEN
					AND ID_GRUPO >= A.ID_GRUPO
					AND DIF_MINUTOS > 10
				  ORDER BY ID_GRUPO ASC ) B

	-- SEMPRE O ULTIMO GRUPO FICAR� COM A SEGMENTACAO NULL
	UPDATE #TMP_GRUPO_ACCESS_TOKEN SET SEGMENTACAO  = B.ID_GRUPO
	FROM #TMP_GRUPO_ACCESS_TOKEN A
	OUTER APPLY ( SELECT MAX(ID_GRUPO) AS ID_GRUPO 
				  FROM #TMP_GRUPO_ACCESS_TOKEN 
				  WHERE ACCESS_TOKEN = A.ACCESS_TOKEN
				  AND SEGMENTACAO IS NULL ) B
	WHERE A.SEGMENTACAO IS NULL

	-- ATUALIZAR INFORMACAO DE "SEGMENTACAO" GERADA POR ACCESS_TOKEN
	UPDATE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] SET SEGMENTACAO = B.SEGMENTACAO 
	FROM [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] A
	INNER JOIN #TMP_GRUPO_ACCESS_TOKEN B ON B.ID = A.ID

	-- CALCULAR A DURACAO DE CADA REFRESH DA SESS�O (ACCESS_TOKEN)
	SELECT ACCESS_TOKEN,
		   SEGMENTACAO,
		   MIN(DATA) AS DATA_INICIAL,
		   MAX(DATA) AS DATA_FINAL,
		   DATEDIFF(SECOND,MIN(DATA), MAX(DATA)) AS DIF_SEGUNDOS
	INTO #TMP_GRUPO_ACCESS_TOKEN_DURACAO
	FROM #TMP_GRUPO_ACCESS_TOKEN A
	--WHERE ACCESS_TOKEN = '1463543313373'
	GROUP BY ACCESS_TOKEN,
		   SEGMENTACAO

	-- GRAVAR DADOS J� FORMATADOS
	INSERT INTO VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS 	
	SELECT  DISTINCT 
		    --MIN(CONVERT(DATETIME,REPLACE(A.[DATE],'"','') + ' ' + REPLACE(A.[TIME],'"',''))) AS DATA_AUDITORIA,
			B.DATA_INICIAL AS DATA_AUDITORIA,
			REPLACE(A.[s-ip],'"','') AS SERVER_IP,
			REPLACE(A.[cs-method],'"','') AS METODO,
			REPLACE(A.[cs-uri-stem],'"','') AS URI_STEM,
			REPLACE(A.[cs-uri-query],'"','') AS URI_QUERY,
			REPLACE(A.[s-port],'"','') AS PORTA,
			REPLACE(A.[cs-username],'"','') AS USER_NAME,
			REPLACE(A.[c-ip],'"','') AS CLIENT_IP,
			REPLACE(A.[cs(User-Agent)],'"','') AS USER_AGENT,
			REPLACE(A.[cs(Cookie)],'"','') AS COOKIE,
			REPLACE(A.[cs-host],'"','') AS HOST,
			REPLACE(A.[sc-status],'"','') AS STATUS,
			REPLACE(A.[sc-substatus],'"','') AS SUB_STATUS,
			REPLACE(A.[sc-win32-status],'"','') AS WIN32_STATUS,
			--CONVERT(INT,REPLACE(REPLACE(REPLACE(A.[time-taken],'"',''),CHAR(10),''),CHAR(13),'')) AS TIME_TAKEN,
			NULL AS TIME_TAKEN, -- POR ENQUANTO UTILIZAREMOS A DIFEREN�A ENTRE A PRIMEIRA E ULTIMA CHAMADA AJAX 
			@NOME_ARQUIVO,
		    @DATA_ARQUIVO,
			NULL AS NOME_RELATORIO,
			NULL AS AREA,
			SUBSTRING(
			REPLACE(REPLACE(REVERSE(SUBSTRING(REVERSE([cs-uri-stem]),1,CHARINDEX('/',REVERSE([cs-uri-stem])))),'/',''),'"','') 
			,1,8) + '-' +
			SUBSTRING(
			REPLACE(REPLACE(REVERSE(SUBSTRING(REVERSE([cs-uri-stem]),1,CHARINDEX('/',REVERSE([cs-uri-stem])))),'/',''),'"','') 
			,9,4) + '-' +
			SUBSTRING(
			REPLACE(REPLACE(REVERSE(SUBSTRING(REVERSE([cs-uri-stem]),1,CHARINDEX('/',REVERSE([cs-uri-stem])))),'/',''),'"','') 
			,13,4) + '-' +
			SUBSTRING(
			REPLACE(REPLACE(REVERSE(SUBSTRING(REVERSE([cs-uri-stem]),1,CHARINDEX('/',REVERSE([cs-uri-stem])))),'/',''),'"','') 
			,17,4) + '-' +
			SUBSTRING(
			REPLACE(REPLACE(REVERSE(SUBSTRING(REVERSE([cs-uri-stem]),1,CHARINDEX('/',REVERSE([cs-uri-stem])))),'/',''),'"','') 
			,21,12) AS FILE_ID,
		   REPLACE(REPLACE(SUBSTRING([cs-uri-query],CHARINDEX('access_token_ttl',[cs-uri-query]),LEN([cs-uri-query])),'"',''),'access_token_ttl=','') AS ACCESS_TOKEN_TTL,
		   --DATEDIFF(SECOND,MIN(CONVERT(DATETIME,REPLACE([DATE],'"','') + ' ' + REPLACE([TIME],'"',''))),MAX(CONVERT(DATETIME,REPLACE([DATE],'"','') + ' ' + REPLACE([TIME],'"','')))) AS DURACAO_SEGUNDOS,		   
		   B.DIF_SEGUNDOS AS DURACAO_SEGUNDOS,
		   NULL AS DIRETORIO_RELATORIO		   
	FROM VAGAS_DW.VAGAS_DW.TMP_LOG_IIS A
	INNER JOIN #TMP_GRUPO_ACCESS_TOKEN_DURACAO B ON B.ACCESS_TOKEN COLLATE SQL_Latin1_General_CP1_CI_AI = A.ACCESS_TOKEN 
												AND B.SEGMENTACAO COLLATE SQL_Latin1_General_CP1_CI_AI = A.SEGMENTACAO
	WHERE [cs-uri-stem] LIKE '%wopi.ashx%'  
	ORDER BY ACCESS_TOKEN_TTL
	
	DELETE FROM VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS WHERE FILE_ID = 'contents----'

	UPDATE VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS SET NOME_RELATORIO = LeafName,
											 DIRETORIO_RELATORIO = DirName,
											 AREA = SUBSTRING(REPLACE(DirName ,'Documents/',''),1,CASE WHEN CHARINDEX('/',REPLACE(DirName ,'Documents/','')) = 0 THEN LEN(REPLACE(DirName ,'Documents/',''))+1
																									   ELSE CHARINDEX('/',REPLACE(DirName ,'Documents/','')) END - 1 ) 
	FROM VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS A
	LEFT OUTER JOIN SHAREPOINT.VAGAS_CONTENT.DBO.ALLDOCS B ON B.ID = CONVERT(UNIQUEIDENTIFIER,A.FILE_ID)
	WHERE A.NOME_ARQUIVO = @NOME_ARQUIVO

	DROP TABLE #TMP_GRUPO_ACCESS_TOKEN
	DROP TABLE #TMP_GRUPO_ACCESS_TOKEN_DURACAO
	DROP TABLE #TMP_ID_GRUPO

	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN ID_GRUPO 
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN ID
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN ACCESS_TOKEN 
	ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] DROP COLUMN SEGMENTACAO
	
	SELECT TOP 1 @ID_ARQUIVO_LOG = ID_ARQUIVO_LOG,@NOME_ARQUIVO = NOME_ARQUIVO,@DATA_ARQUIVO = DATA_ARQUIVO
	FROM #TMP_ARQUIVOS_LOG 
	WHERE ID_ARQUIVO_LOG  > @ID_ARQUIVO_LOG 
	ORDER BY 1 ASC
END


-- EXISTEM ALGUMAS CHAMADAS QUE N�O CONDIZEM COM O TEMPO REAL DO RELAT�RIO 
-- (EXCLUIMOS ELAS COM BASE NA M�DIA, SE O % FICAR ABAIXO DE 2% DA M�DIA ENT�O EXCLUIMOS O REGISTRO)
DELETE VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS
FROM VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS A
OUTER APPLY ( SELECT AVG(DURACAO_SEGUNDOS) AS MEDIA_DURACAO
			  FROM VAGAS_DW.VAGAS_DW.TMP_AUDITORIA_RELATORIOS 
			  WHERE NOME_RELATORIO = A.NOME_RELATORIO
			  AND NOME_ARQUIVO = A.NOME_ARQUIVO 
			  AND DURACAO_SEGUNDOS > 0 ) B
WHERE CONVERT(FLOAT,A.DURACAO_SEGUNDOS) / CONVERT(FLOAT,B.MEDIA_DURACAO) < 0.02 
AND B.MEDIA_DURACAO > 30 -- APENAS PARA RELAT�RIOS QUE A M�DIA SEJA MAIOR QUE 30 SEG. (POIS EXISTE UMA VARIA��O PLAUS�VEL COM TEMPO MENOR QUE 30 SEG.)

-- TEMOS SEMPRE QUE FICAR ATENTOS A ESTRUTURA DA TABELA [TMP_LOG_IIS] POIS O BULK INSERT D� PROBLEMA COM TODAS AS COLUNAS 
-- POR ISSO PRECISAMOS FICAR INCLUINDO E EXCLUINDO AS COLUNAS DE APOIO

-- m�todo alternativo devido ao erro "The table "TMP_LOG_IIS" has been created, but its maximum row
-- size exceeds the allowed maximum of 8060 bytes. INSERT or UPDATE to this table will fail if the resulting row exceeds the size
-- limit."

DROP TABLE [VAGAS_DW].[TMP_LOG_IIS]

CREATE TABLE [VAGAS_DW].[TMP_LOG_IIS](
	[date] [varchar](200) NULL,
	[time] [varchar](100) NULL,
	[s-ip] [varchar](100) NULL,
	[cs-method] [varchar](50) NULL,
	[cs-uri-stem] [varchar](500) NULL,
	[cs-uri-query] [varchar](max) NULL,
	[s-port] [varchar](max) NULL,
	[cs-username] [varchar](100) NULL,
	[c-ip] [varchar](100) NULL,
	[cs(User-Agent)] [varchar](max) NULL,
	[cs(Cookie)] [varchar](max) NULL,
	[cs(Referer)] [varchar](max) NULL,
	[cs-host] [varchar](max) NULL,
	[sc-status] [varchar](max) NULL,
	[sc-substatus] [varchar](max) NULL,
	[sc-win32-status] [varchar](max) NULL,
	[time-taken] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD ID INT IDENTITY 
ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD ID_GRUPO INT
ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD ACCESS_TOKEN VARCHAR(50)
ALTER TABLE [VAGAS_DW].[VAGAS_DW].[TMP_LOG_IIS] ADD SEGMENTACAO VARCHAR(50)
	
DROP TABLE #TMP_ARQUIVOS_LOG 
