USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Equipes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Equipes
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 05/07/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Equipes

AS
SET NOCOUNT ON


---------------- Carregar tabela TMP com dados provindos da planilha no Google Drive
CREATE TABLE #TMP_ARQUIVO (ID_ARQUIVO SMALLINT IDENTITY PRIMARY KEY,
						   NOME_ARQUIVO VARCHAR(200) )

DECLARE @CMD VARCHAR(8000)

-- Transformar Planilha do Google Drive em arquivo .csv
SET @CMD = 'set PYTHONIOENCODING=cp437 & C:\Python27\python M:\Projetos\Scripts_Python\Exportacao_Arquivos_Google_Drive\LerPlanilhaGoogleDrive.py "1" "M:\\TMP\\Google_SpreadSheets_CSV\\"'
EXEC MASTER.DBO.XP_CMDSHELL @CMD

-- Buscar arquivos relacionados � planilha 
SET @CMD = 'dir m:\TMP\Google_SpreadSheets_CSV\"1_gspread_sheet_Equipes_csv_gspread_"*.* /B'

INSERT INTO #TMP_ARQUIVO
EXEC MASTER.DBO.XP_CMDSHELL @CMD

DECLARE @NOME_ARQUIVO VARCHAR(200)

SELECT TOP 1 @NOME_ARQUIVO = NOME_ARQUIVO
FROM #TMP_ARQUIVO
ORDER BY CONVERT(SMALLDATETIME,
	   LEFT(REPLACE(RIGHT(NOME_ARQUIVO,18),'.csv',''),8) + ' ' + 
	   LEFT(RIGHT(REPLACE(RIGHT(NOME_ARQUIVO,18),'.csv',''),6),2) + ':' +
	   SUBSTRING(RIGHT(REPLACE(RIGHT(NOME_ARQUIVO,18),'.csv',''),6),3,2) + ':' +
	   RIGHT(RIGHT(REPLACE(RIGHT(NOME_ARQUIVO,18),'.csv',''),6),2)
	   ) DESC

DELETE #TMP_ARQUIVO
FROM #TMP_ARQUIVO
WHERE (NOME_ARQUIVO <> @NOME_ARQUIVO)
OR (NOME_ARQUIVO IS NULL)

SET @CMD = ' BULK INSERT VAGAS_DW.TMP_EQUIPES 
			 FROM ''M:\\TMP\\Google_SpreadSheets_CSV\\' + @NOME_ARQUIVO + '''' +
		   ' WITH
			(
				FIELDTERMINATOR = ''|'',
				ROWTERMINATOR = ''\n'',
				CODEPAGE = 1252
			) '

PRINT @CMD

-- Carregar tabela TMP
EXEC (@CMD)

DROP TABLE #TMP_ARQUIVO 

----------------------------------------------------

---- Inser��o de novas equipes
INSERT INTO VAGAS_DW.EQUIPES (NOME,TIPO,DATA_CRIACAO,DATA_ALTERACAO,EMAIL,ATIVO,ID_INTRANET,LINK_ACORDO,
							  LINK_CICLO_1,LINK_CICLO_2,LINK_CICLO_3,LINK_CICLO_4,LINK_CICLO_5,CHAVE_EQUIPE)
SELECT REPLACE(NOME,'"','') AS NOME, 
	   TIPO,
	   GETDATE() AS DATA_CRIACAO,
	   GETDATE() AS DATA_ALTERACAO,
	   EMAIL,
	   1 AS ATIVO,
	   '0' AS ID_INTRANET,
	   ACORDO,
	   CICLO_1,
	   CICLO_2,
	   CICLO_3,
	   CICLO_4,
	   CICLO_5,
	   CHAVE_EQUIPE
FROM VAGAS_DW.TMP_EQUIPES A
WHERE TIPO <> '0' 
AND TIPO <> 'Categoria'
AND NOT EXISTS ( SELECT 1 FROM VAGAS_DW.EQUIPES
				 WHERE REPLACE(NOME,'"','') = REPLACE(A.NOME,'"','') )

---- Atualizar atributos que foram alterados
UPDATE VAGAS_DW.EQUIPES SET EMAIL = B.EMAIL,DATA_ALTERACAO = GETDATE()							
FROM VAGAS_DW.EQUIPES A
INNER JOIN VAGAS_DW.TMP_EQUIPES B ON REPLACE(B.NOME,'"','') = REPLACE(A.NOME,'"','') 
								 AND REPLACE(B.TIPO,'"','') = REPLACE(A.TIPO,'"','')
WHERE A.EMAIL <> B.EMAIL 

UPDATE VAGAS_DW.EQUIPES SET LINK_ACORDO = B.ACORDO,
							LINK_CICLO_1 = B.CICLO_1,
							LINK_CICLO_2 = B.CICLO_2,
							LINK_CICLO_3 = B.CICLO_3,
							LINK_CICLO_4 = B.CICLO_4,
							LINK_CICLO_5 = B.CICLO_5,
							CHAVE_EQUIPE = B.CHAVE_EQUIPE,
							DATA_ALTERACAO = GETDATE(),
							CICLO_ATUAL = CASE WHEN LINK_CICLO_5 IS NOT NULL THEN 5 
											   WHEN LINK_CICLO_4 IS NOT NULL THEN 4
											   WHEN LINK_CICLO_3 IS NOT NULL THEN 3
											   WHEN LINK_CICLO_2 IS NOT NULL THEN 2
											   WHEN LINK_CICLO_1 IS NOT NULL THEN 1
										   END 
FROM VAGAS_DW.EQUIPES A
INNER JOIN VAGAS_DW.TMP_EQUIPES B ON REPLACE(B.NOME,'"','') = REPLACE(A.NOME,'"','') 
								 AND REPLACE(B.TIPO,'"','') = REPLACE(A.TIPO,'"','')
WHERE A.LINK_ACORDO <> B.ACORDO 
OR ISNULL(A.LINK_CICLO_1,'') <> ISNULL(B.CICLO_1,'')
OR ISNULL(A.LINK_CICLO_2,'') <> ISNULL(B.CICLO_2,'')
OR ISNULL(A.LINK_CICLO_3,'') <> ISNULL(B.CICLO_3,'')
OR ISNULL(A.LINK_CICLO_4,'') <> ISNULL(B.CICLO_4,'')
OR ISNULL(A.LINK_CICLO_5,'') <> ISNULL(B.CICLO_5,'')
OR ISNULL(A.CHAVE_EQUIPE,'') <> ISNULL(B.CHAVE_EQUIPE,'')

-- MARCAR COMO "INATIVO" EQUIPES QUE FORAM APAGADAS / RENOMEADAS
UPDATE VAGAS_DW.EQUIPES SET ATIVO = 0
FROM VAGAS_DW.EQUIPES A
WHERE ATIVO = 1 
AND NOT EXISTS ( SELECT * FROM VAGAS_DW.TMP_EQUIPES
					WHERE REPLACE(NOME,'"','') = REPLACE(A.NOME,'"','')
					AND REPLACE(TIPO,'"','') = REPLACE(A.TIPO,'"','') )

-- Buscar arquivos relacionados � planilha 
SET @CMD = 'del m:\TMP\Google_SpreadSheets_CSV\"1_gspread_sheet_Equipes_csv_gspread_*.*'
EXEC MASTER.DBO.XP_CMDSHELL @CMD

DECLARE @QTD_COLUNAS TINYINT -- CASO A ESTRUTURA DA PLANILHA SEJA ALTERADO ESTE VALOR DEVE SER ALTERADO PARA TODAS AS PLANILHAS 
SET @QTD_COLUNAS = 12

-- INSERIR NOVOS CONTROLES DE PLANILHAS DE EVOLU��O DE CICLO DAS EQUIPES
INSERT INTO VAGAS_DW.CONTROLE_SPREADSHEET (URL,SHEET_NAME,DATA_CADASTRO,DATA_ALTERACAO,NOME_CONTROLE,FLAG_ATIVO,ID_EQUIPE,QTD_COLUNAS)
SELECT LINK_CICLO_1 AS URL,
		'1� Ciclo' AS SHEET_NAME,
		GETDATE() AS DATA_CADASTRO,
		GETDATE() AS DATA_ALTERACAO,
		'EVOLUCAO_CICLO' AS NOME_CONTROLE,
		1,
		A.ID_EQUIPE,
		@QTD_COLUNAS
FROM VAGAS_DW.EQUIPES A
WHERE LINK_CICLO_1 IS NOT NULL
AND NOT EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
					WHERE URL = A.LINK_CICLO_1
					AND NOME_CONTROLE = 'EVOLUCAO_CICLO' )

UNION ALL

SELECT LINK_CICLO_2 AS URL,
		'2� Ciclo' AS SHEET_NAME,
		GETDATE() AS DATA_CADASTRO,
		GETDATE() AS DATA_ALTERACAO,
		'EVOLUCAO_CICLO' AS NOME_CONTROLE,
		1,
		A.ID_EQUIPE,
		@QTD_COLUNAS
FROM VAGAS_DW.EQUIPES A
WHERE LINK_CICLO_2 IS NOT NULL
AND NOT EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
					WHERE URL = A.LINK_CICLO_2
					AND NOME_CONTROLE = 'EVOLUCAO_CICLO' )
	
UNION ALL

SELECT LINK_CICLO_3 AS URL,
		'3� Ciclo' AS SHEET_NAME,
		GETDATE() AS DATA_CADASTRO,
		GETDATE() AS DATA_ALTERACAO,
		'EVOLUCAO_CICLO' AS NOME_CONTROLE,
		1,
		A.ID_EQUIPE,
		@QTD_COLUNAS
FROM VAGAS_DW.EQUIPES A
WHERE LINK_CICLO_3 IS NOT NULL
AND NOT EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
					WHERE URL = A.LINK_CICLO_3
					AND NOME_CONTROLE = 'EVOLUCAO_CICLO' )

UNION ALL

SELECT LINK_CICLO_4 AS URL,
		'4� Ciclo' AS SHEET_NAME,
		GETDATE() AS DATA_CADASTRO,
		GETDATE() AS DATA_ALTERACAO,
		'EVOLUCAO_CICLO' AS NOME_CONTROLE,
		1,
		A.ID_EQUIPE,
		@QTD_COLUNAS
FROM VAGAS_DW.EQUIPES A
WHERE LINK_CICLO_4 IS NOT NULL
AND NOT EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
					WHERE URL = A.LINK_CICLO_4
					AND NOME_CONTROLE = 'EVOLUCAO_CICLO' )

UNION ALL

SELECT LINK_CICLO_5 AS URL,
		'5� Ciclo' AS SHEET_NAME,
		GETDATE() AS DATA_CADASTRO,
		GETDATE() AS DATA_ALTERACAO,
		'EVOLUCAO_CICLO' AS NOME_CONTROLE,
		1,
		A.ID_EQUIPE,
		@QTD_COLUNAS
FROM VAGAS_DW.EQUIPES A
WHERE LINK_CICLO_5 IS NOT NULL
AND NOT EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
					WHERE URL = A.LINK_CICLO_5
					AND NOME_CONTROLE = 'EVOLUCAO_CICLO' )


-- DESATIVAR CICLOS QUE J� EVOLU�RAM
UPDATE VAGAS_DW.CONTROLE_SPREADSHEET SET FLAG_ATIVO = 0
FROM VAGAS_DW.CONTROLE_SPREADSHEET A
WHERE NOME_CONTROLE = 'EVOLUCAO_CICLO'
AND SHEET_NAME = '1� Ciclo'
AND EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
			 WHERE ID_EQUIPE = A.ID_EQUIPE
			 AND SHEET_NAME IN ('2� Ciclo','3� Ciclo','4� Ciclo','5� Ciclo') )

UPDATE VAGAS_DW.CONTROLE_SPREADSHEET SET FLAG_ATIVO = 0
FROM VAGAS_DW.CONTROLE_SPREADSHEET A
WHERE NOME_CONTROLE = 'EVOLUCAO_CICLO'
AND SHEET_NAME = '2� Ciclo'
AND EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
			 WHERE ID_EQUIPE = A.ID_EQUIPE
			 AND SHEET_NAME IN ('3� Ciclo','4� Ciclo','5� Ciclo') )
			 
UPDATE VAGAS_DW.CONTROLE_SPREADSHEET SET FLAG_ATIVO = 0
FROM VAGAS_DW.CONTROLE_SPREADSHEET A
WHERE NOME_CONTROLE = 'EVOLUCAO_CICLO'
AND SHEET_NAME = '3� Ciclo'
AND EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
			 WHERE ID_EQUIPE = A.ID_EQUIPE
			 AND SHEET_NAME IN ('4� Ciclo','5� Ciclo') )


UPDATE VAGAS_DW.CONTROLE_SPREADSHEET SET FLAG_ATIVO = 0
FROM VAGAS_DW.CONTROLE_SPREADSHEET A
WHERE NOME_CONTROLE = 'EVOLUCAO_CICLO'
AND SHEET_NAME = '4� Ciclo'
AND EXISTS ( SELECT * FROM VAGAS_DW.CONTROLE_SPREADSHEET 
			 WHERE ID_EQUIPE = A.ID_EQUIPE
			 AND SHEET_NAME IN ('5� Ciclo') )
