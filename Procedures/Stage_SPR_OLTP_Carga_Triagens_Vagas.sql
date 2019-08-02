-- =============================================
-- Author: Fiama
-- Create date: 13/07/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;
GO

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'Stage_SPR_OLTP_Carga_Triagens_Vagas' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Triagens_Vagas] 
GO

CREATE PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Triagens_Vagas]
AS
SET NOCOUNT ON


-- Limpeza da tabela:
TRUNCATE TABLE [VAGAS_DW].[TMP_TRIAGENS_VAGAS] ;

---------------------------------------
-- Levantamento das triagens nas vagas:
---------------------------------------
SELECT	CONVERT(DATE, A.Data_debTri) AS DATA_TRIAGEM ,
		A.CodVaga_debTri AS COD_VAGA ,
		CASE
			WHEN A.BCC_DebTri = 1
				THEN 'BCC'
			WHEN A.BCA_DebTri = 1
				THEN 'BCE'
			WHEN A.CodVaga_debTri > 0 AND B.ColetaCur_vaga = 0
				THEN 'VAGA'
			WHEN A.CodVaga_debTri > 0 AND B.ColetaCur_vaga = 1
				THEN 'CAPTAÇÃO ABERTA'
			ELSE NULL
		END AS CONTEXTO ,
		D.Cod_cli ,
		D.Ident_cli AS CLIENTE_VAGAS ,
		CASE
			WHEN A.VersaoTriagem_debTri IS NULL
				THEN 'TRIAGEM 1.0'
			WHEN A.VersaoTriagem_debTri = 2
				THEN 'TRIAGEM 2.0'
		END AS VERSAO_TRIAGEM ,
		C.Cod_func AS COD_FUNC ,
		COUNT(*) AS QTD_TRIAGENS ,
		SUM(QTDECV_DEBTRI) AS QTD_CURRICULOS
INTO	#TMP_TRIAGENS_VAGAS
FROM	[hrh-data].[dbo].[DebugTriagem] AS A	LEFT OUTER JOIN [hrh-data].[dbo].[Vagas] AS B ON A.CodVaga_debTri = B.Cod_vaga
												AND B.VagaModelo_vaga = 0 -- Vaga não é modelo   
												AND LEFT(B.Cargo_vaga,5) not in ('demo ', 'demo-') -- a vaga nao foi criada durante uma demonstracao  
												AND ISNULL(B.VagaComExt_vaga, 0) = 0 -- FILTRAR VAGAS DE COMUNID. EXTERNA [SUGESTÃO BETH]
												LEFT OUTER JOIN [hrh-data].[dbo].[Funcionarios] AS C ON A.CodUsu_DebTri = C.Cod_func
												LEFT OUTER JOIN [hrh-data].[dbo].[Clientes] AS D ON C.CodCli_func = D.Cod_cli
WHERE	A.Data_debTri >= '19000101'
		AND A.SenhaMestre_debTri = 0 -- Não foi realizado por acesso Manut
		AND ( A.VersaoTriagem_debTri IS NULL -- Triagem 1.0
			  OR A.VersaoTriagem_debTri = 2 ) -- Triagem 2.0
		AND CODVAGA_DEBTRI > 0
GROUP BY
		CONVERT(DATE, A.Data_debTri) ,
		A.CodVaga_debTri ,
		CASE
			WHEN A.BCC_DebTri = 1
				THEN 'BCC'
			WHEN A.BCA_DebTri = 1
				THEN 'BCE'
			WHEN A.CodVaga_debTri > 0 AND B.ColetaCur_vaga = 0
				THEN 'VAGA'
			WHEN A.CodVaga_debTri > 0 AND B.ColetaCur_vaga = 1
				THEN 'CAPTAÇÃO ABERTA'
			ELSE NULL
		END ,
		D.Cod_cli ,
		D.Ident_cli ,
		CASE
			WHEN A.VersaoTriagem_debTri IS NULL
				THEN 'TRIAGEM 1.0'
			WHEN A.VersaoTriagem_debTri = 2
				THEN 'TRIAGEM 2.0'
		END ,
		C.Cod_func ;

-- Carregar registros na tabela temporária:
INSERT INTO [VAGAS_DW].[TMP_TRIAGENS_VAGAS](DATA_TRIAGEM,COD_VAGA,CONTEXTO,COD_CLI,CLIENTE_VAGAS,VERSAO_TRIAGEM,COD_FUNC,QTD_TRIAGENS, QTD_CURRICULOS)
SELECT	A.DATA_TRIAGEM ,
		A.COD_VAGA ,
		A.CONTEXTO ,
		A.COD_CLI ,
		A.CLIENTE_VAGAS ,
		A.VERSAO_TRIAGEM ,
		A.COD_FUNC ,
		A.QTD_TRIAGENS ,
		A.QTD_CURRICULOS
FROM #TMP_TRIAGENS_VAGAS AS A ;