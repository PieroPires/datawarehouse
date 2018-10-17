USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Clientes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Clientes
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Clientes 

AS
SET NOCOUNT ON

TRUNCATE TABLE VAGAS_DW.VAGAS_DW.TMP_CLIENTES

;WITH  MaxPerfilUso AS -- Pegar ÚLTIMO REGISTRO do Perfil do cliente  
      (  
      SELECT CodCli_cliPerfUso,MAX(Cod_cliPerfUso) Maxcod_CliPerfUso  
      FROM  [hrh-data].dbo.[Clientes-PerfilUso] with (nolock)  
      GROUP BY CodCli_cliPerfUso  
      )  


SELECT A.Ident_Cli AS Cliente_VAGAS,
	   A.Cod_Cli AS Cod_Cli,
	   QtdeMinVagas_cliPerfUso, -- Minimo PerfilContratado RE (Recrutamento externo) 
       QtdeMaxVagas_cliPerfUso, -- Máximo PerfilContratado RE (Recrutamento externo)
	   QtdeMinVagasRI_cliPerfUso, -- Minimo PerfilContratado RI (Recrutamento interno)
	   QtdeMaxVagasRI_cliPerfUso,  -- Máximo PerfilContratado RI (Recrutamento interno)
	   CASE WHEN A.Cod_Cli IN (40647,65836) THEN NULL ELSE -- A TAM EXECUTIVA ESTÁ COM DATA INCONSISTENTE (30130503) e a PIRELLI Comercial 
		   CASE WHEN restrito_cli = 0 AND sobdemanda_cli = 0 THEN CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DataContrato_cliPerfUso,112)) -- FIT
				WHEN sobdemanda_cli = 1 THEN CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DtContratoServ_cli,112)) -- FLEX A | Créditos VAGAS
				WHEN restrito_cli = 1 THEN CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DtContratoServ_cli,112)) -- FLEX C
				ELSE CONVERT(SMALLDATETIME,CONVERT(VARCHAR,ISNULL(DataContrato_cliPerfUso,A.DtContratoServ_cli),112)) /* OUTROS */ END 	   
	   END AS DataContrato_cliPerfUso,	   
	   CapacidadeBCAAtual_cli AS Capacidade_BCE,
	   CASE WHEN restrito_cli = 0 AND sobdemanda_cli = 0 THEN 'FIT'
		    WHEN CreditosVAGAS_cli = 1 THEN 'Créditos VAGAS'
			WHEN sobdemanda_cli = 1  THEN 'FLEXA' -- FLEX
			WHEN restrito_cli = 1 THEN 'FLEXC' 
			ELSE 'Indefinido' END AS Tipo_Cliente,
	   A.IdContaCRM_cli AS Conta_CRM,
	   ISNULL(CASE WHEN A.CreditosVAGAS_cli = 1 THEN D.Creditos_Total ELSE A.RestritoQtdeVagas_cli END,0) AS Creditos_Total,
	   ISNULL(CASE WHEN A.CreditosVAGAS_cli = 1 THEN D.Creditos_Disponivel ELSE 0 END,0) AS Creditos_Disponivel, -- Apenas já temos calculado o valor no "Creditos VAGAS" (Os FLEX serão calculados na rotina do OLAP)
	   ISNULL(CASE WHEN A.CreditosVAGAS_cli = 1 THEN D.Creditos_Valor ELSE NULL END,0) AS Creditos_Valor, -- Apenas já temos calculado o valor no "Creditos VAGAS" (Os FLEX serão calculados na rotina do OLAP)
	   A.IdContaCRM_cli AS CONTA_ID ,
	   (SELECT UPPER(LTRIM(RTRIM(A.Uf_cli)))
	    FROM [hrh-data].[dbo].[Cad_estadosBR] AS A1
		WHERE A.Uf_cli = A1.Descr_estadoBR) AS UF,
		A.Cidade_cli AS CIDADE ,
	   CASE WHEN E.LOGO_DO_CLIENTE IS NOT NULL THEN 1 ELSE 0 END AS POSSUI_LOGO,
	   CASE WHEN E.EMPRESA_10_MAIS IS NOT NULL THEN 1 ELSE 0 END AS JA_FOI_VAGAS_10_MAIS,
	   CASE WHEN E.EMPRESA_10_MAIS IS NOT NULL 
		    THEN CONVERT(SMALLDATETIME,REPLACE(REVERSE(LEFT(REVERSE(E.EMPRESA_10_MAIS),9)),';','') )
			ELSE NULL END AS ULT_DATA_VAGAS_10_MAIS,
	   F.QTD_UNIDADES_CADASTRADAS,
	   G.QTD_UNIDADES_ATIVADAS ,
	   (SELECT	COUNT(*) AS QTD_LOGIN_ULT_30_DIAS
	    FROM	[hrh-data].[dbo].[Clientes-Login] AS A1
		WHERE	A.Cod_cli = A1.CodCli_log
				AND A1.Op_log = 1
				AND A1.CodUsuManut_log = 0
				AND A1.Data_log >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))) AS QTD_LOGIN_ULT_30_DIAS ,

		(	SELECT	COUNT(*) AS QTD_FUNC_LOGIN_ULT_30_DIAS
			FROM	[hrh-data].[dbo].[Funcionarios] AS A1
			WHERE	A.COD_CLI = A1.CodCli_func
					AND A1.Removido_func = 0
					AND EXISTS (SELECT	1
								FROM	[hrh-data].[dbo].[Clientes-Login] AS AA1
								WHERE	A1.Cod_func = AA1.CodFunc_Log
										AND AA1.Op_Log = 1
										AND ISNULL(AA1.CodUsuManut_log, -1) < 1
										AND AA1.Data_Log >= DATEADD(DAY, -30, CAST(GETDATE() AS DATE))) ) AS QTD_FUNC_LOGIN_ULT_30_DIAS ,

		(	SELECT	COUNT(*) AS QTD_FUNC_INATIVO
			FROM	[hrh-data].[dbo].[Funcionarios] AS A1
			WHERE	A.COD_CLI = A1.CodCli_func
					AND A1.Removido_func = 0
					AND EXISTS (SELECT	1
								FROM	[hrh-data].[dbo].[Clientes-Login] AS AA1
								WHERE	A1.Cod_func = AA1.CodFunc_Log
										AND AA1.Op_log = 1
										AND ISNULL(AA1.CodUsuManut_log, -1) < 1
										AND ( AA1.Data_log >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE))
											  AND AA1.Data_log < DATEADD(DAY, -30, CAST(GETDATE() AS DATE)))) )  AS QTD_FUNC_INATIVO ,

		(	SELECT	COUNT(*) AS QTD_FUNC_ADMIN
			FROM	[hrh-data].[dbo].[Funcionarios] AS A1
			WHERE	A.COD_CLI = A1.CodCli_func
					AND A1.Removido_func = 0
					AND A1.Admin_func = 1
					AND EXISTS (SELECT	1
								FROM	[hrh-data].[dbo].[Clientes-Login] AS AA1
								WHERE	A1.Cod_func = AA1.CodFunc_Log
										AND AA1.Op_Log = 1
										AND ISNULL(AA1.CodUsuManut_Log, -1) < 1
										AND AA1.Data_Log >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE))) ) AS QTD_FUNC_ADMIN ,

		(SELECT COUNT(*) AS QTD_PESQUISAS_BCC
		 FROM	[hrh-data].[dbo].[Funcionarios] AS A1		INNER JOIN [hrh-data].[dbo].[DebugTriagem] AS A2 ON A1.Cod_func = A2.CodUsu_debTri
		 WHERE	A.Cod_cli = A1.CodCli_func
				AND A2.BCC_debTri = 1 -- triagem no BCC
				AND A2.SenhaMestre_debTri = 0  -- não foi realizado por acesso Manut
				AND A2.data_debTri >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE)) ) AS QTD_PESQUISAS_BCC ,

		(SELECT	COUNT(*) AS QTD_PESQUISAS_BCE
		 FROM	[hrh-data].[dbo].[Funcionarios] AS A1		INNER JOIN [hrh-data].[dbo].[DebugTriagem] AS A2 ON A1.Cod_func = A2.CodUsu_debTri
		 WHERE	A.Cod_cli = A1.CodCli_func
				AND A2.BCA_debTri  = 1 -- triagem no BCE
				AND A2.SenhaMestre_debTri = 0 -- não foi realizado por acesso Manut
				AND A2.data_debTri >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE)) ) AS QTD_PESQUISAS_BCE ,

		(SELECT	COUNT(*) AS QTD_PESSOAS_CONTRATADAS
		 FROM	[hrh-data].[dbo].[Candidatos_Contratados] AS A1		INNER JOIN [hrh-data].[dbo].[Vagas] AS A2 ON A1.codvaga_candcon = A2.Cod_vaga
		 WHERE	A.Cod_cli = A2.CodCliente_vaga) AS QTD_PESSOAS_CONTRATADAS ,

		(SELECT	COUNT(*) AS QTD_USUARIOS_CADASTRADOS
		 FROM	[hrh-data].[dbo].[Funcionarios] AS A1
		 WHERE	A.COD_CLI = A1.CodCli_func
				AND A1.Removido_func = 0
				AND EXISTS (SELECT	1
							FROM	[hrh-data].[dbo].[Clientes-Login] AS AA1
							WHERE	A1.Cod_func = AA1.CodFunc_Log
									AND AA1.Op_log = 1
									AND ISNULL(AA1.CodUsuManut_log, -1) < 1
									AND AA1.Data_log >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE))) )AS QTD_USUARIOS_CADASTRADOS ,

		(SELECT COUNT(*) AS QTD_FUNC_ADMIN_BLOQUEADO
		 FROM	[hrh-data].[dbo].[Funcionarios] AS A1
		 WHERE	A.COD_CLI = A1.CodCli_func
				AND A1.Removido_func = 0
				AND A1.Admin_func = 1
				AND A1.StatusAcesso_func = 0
				AND EXISTS (SELECT	1
							FROM	[hrh-data].[dbo].[Clientes-Login] AS AA1
							WHERE	A1.Cod_func = AA1.CodFunc_Log
									AND AA1.Op_log = 1
									AND ISNULL(AA1.CodUsuManut_log, -1) < 1
									AND AA1.Data_log >= DATEADD(YEAR, -1, CAST(GETDATE() AS DATE)))) AS QTD_FUNC_ADMIN_BLOQUEADO ,

		(SELECT	COUNT(*) AS QTD_FUNC_ULT_2_MESES
		 FROM	[hrh-data].[dbo].[Funcionarios] AS A1		INNER JOIN [hrh-data].[dbo].[Clientes-Login] AS A2 ON A1.Cod_func = A2.CodFunc_Log
		 WHERE	A.COD_CLI = A1.CodCli_func
				AND A1.Removido_func = 0
				AND A2.Op_Log = 1
				AND ISNULL(A2.CodUsuManut_Log, -1) < 1
				AND A2.Data_Log = (SELECT	MIN(AA1.Data_Log) AS PRM_DATA_LOGIN
								   FROM		[hrh-data].[dbo].[Clientes-Login] AS AA1
								   WHERE	A1.Cod_func = AA1.CodFunc_Log
											AND AA1.Op_log = 1
											AND ISNULL(AA1.CodUsuManut_Log, -1) < 1)
				AND A2.Data_Log >= DATEADD(MONTH, -2, CAST(GETDATE() AS DATE)) ) AS QTD_FUNC_ULT_2_MESES ,

		ISNULL( ( SELECT TOP 1 'NÃO' AS SLA_NAO_CONFIGURADO
				  FROM	 [hrh-data].[dbo].[Clientes] AS A1	INNER JOIN [hrh-data].[dbo].[Divisoes] AS A2 ON A1.Cod_cli = A2.CodCli_div
															INNER JOIN [hrh-data].[dbo].[SLA_Divisoes] AS A3 ON A2.Cod_div = A3.CodDiv_slaDiv
				  WHERE	  A.COD_CLI = A1.Cod_cli ), 'SIM') AS SLA_NAO_CONFIGURADO ,
		ISNULL( ( SELECT TOP 1 'SIM'
				  FROM	[hrh-data].[dbo].[Fichas-DescrGeral] AS A1
				  WHERE A.COD_CLI = A1.CodCli_fic
						AND A1.Teste_fic != -1
						AND A1.Ident_fic NOT LIKE '%VAGAS%' ), 'NÃO') AS TESTE_CUSTOMIZADO ,
		ISNULL( ( SELECT	TOP 1 'NÃO' AS CONFIGUROU_POL_SENHA
				  FROM	[hrh-data].[dbo].[Clientes_Politica_Senhas] AS A1
				  WHERE	A.COD_CLI = CodCli_polSen
						AND A1.QtdeMinCar_polSen = 8
						AND A1.QtdeMaxCar_polSen = 20
						AND A1.ObrigSenhaComplexa_polSen = 0
						AND A1.DiasDuracaoMaxSenha_polSen = 90
						AND A1.DiasTrocaSenhaExpirada_polSen = 90
						AND A1.DiasDuracaoMinSenha_polSen = 1
						AND A1.QtdeSenhasMemorizadas_polSen = 5
						AND A1.QtdeTentativasBloqueio_polSen = 5
						AND A1.MinutosResetQtdeTentativas_polSen = 15
						AND A1.MinutosBloqueio_polSen = 15 ), 'SIM') AS CONFIGUROU_POL_SENHA ,
		( SELECT	COUNT(*) AS QTD_FUNC_REMOVIDO
		  FROM		[hrh-data].[dbo].[Funcionarios] AS A1
		  WHERE		A.Cod-cli = A1.CodCli_func
					AND A1.Removido_func = 1 ) AS QTD_FUNCIONARIOS_REMOVIDOS
INTO #TMP_PERFIL_USO
FROM [hrh-data].dbo.Clientes A
LEFT OUTER JOIN MaxPerfilUso B ON B.CodCli_cliPerfUso = A.Cod_Cli
LEFT OUTER JOIN [hrh-data].dbo.[Clientes-PerfilUso] C ON C.Cod_cliPerfUso = B.Maxcod_CliPerfUso
OUTER APPLY ( SELECT SUM(Credito_Credv) AS Creditos_Total,
					 SUM(Usados_Credv) AS Creditos_Disponivel,
					 SUM(Custo_CredV) AS Creditos_Valor
			  FROM [hrh-data].dbo.Creditos_VAGAS
			  WHERE CodCli_CredV = A.Cod_Cli
			  AND DataVal_CredV >= GETDATE() ) D
OUTER APPLY ( SELECT TOP 1 * 
			  FROM [vagas-data].dbo.empresas_indexadas
			  WHERE cliente_id = A.cod_cli
			  ORDER BY id DESC ) E
OUTER APPLY ( SELECT COUNT(*) AS QTD_UNIDADES_CADASTRADAS
			  FROM [hrh-data].dbo.FranqueadorxFranqueado
			  WHERE CodCliFranqueador_fcf = A.Cod_Cli ) F
OUTER APPLY ( SELECT COUNT(*) AS QTD_UNIDADES_ATIVADAS
			  FROM [hrh-data].dbo.FranqueadorxFranqueado
			  WHERE CodCliFranqueador_fcf = A.Cod_Cli 
			  AND CodCliFranqueado_fcf IS NOT NULL ) G
WHERE A.ident_cli NOT IN ('zapt','ficticia', 'ficticia redes', 'teste01', 'Teste Treinamento', 'Teste02', 'teste2012', 'setorial')  


SELECT B.Cliente_VAGAS,
	   COUNT(*) AS QTD_BCE 
INTO #TMP_BCE
FROM [hrh-data].dbo.CandidatoxCliente A
INNER JOIN #TMP_PERFIL_USO B ON B.Cod_Cli = A.codCliente_candCli
WHERE Estado_CandCli > 0
GROUP BY B.Cliente_VAGAS

SELECT A.Cod_Cli,
	   A.Cliente_VAGAS,
	   A.QtdeMinVagas_cliPerfUso AS QtdMin_VAGAS , -- MinimoPerfilContratado  
       A.QtdeMaxVagas_cliPerfUso AS QtdMax_VAGAS, -- MaximoPerfilContratado  
	   QtdeMinVagasRI_cliPerfUso AS QtdMin_RI_VAGAS,
	   QtdeMaxVagasRI_cliPerfUso AS QtdMax_RI_VAGAS,
	   -- Ajuste por conta de um contrato da TAM EXECUTIVA que está com data de 3013
	   CASE WHEN A.DataContrato_cliPerfUso > DATEADD(MONTH,3,GETDATE()) THEN GETDATE() ELSE A.DataContrato_cliPerfUso  END AS Data_Contrato,
	   A.Capacidade_BCE,
	   A.Tipo_Cliente,
	   A.Conta_CRM,
	   B.QTD_BCE,
	   A.Creditos_Total,
	   A.Creditos_Disponivel,
	   A.Creditos_Valor,
	   A.CONTA_ID,
	   A.UF,
	   A.CIDADE ,
	   A.POSSUI_LOGO,
	   A.JA_FOI_VAGAS_10_MAIS,
	   A.ULT_DATA_VAGAS_10_MAIS,
	   A.QTD_UNIDADES_CADASTRADAS,
	   A.QTD_UNIDADES_ATIVADAS ,
	   A.QTD_LOGIN_ULT_30_DIAS ,
	   A.QTD_FUNC_LOGIN_ULT_30_DIAS ,
	   A.QTD_FUNC_INATIVO ,
	   A.QTD_FUNC_ADMIN ,
	   A.QTD_PESQUISAS_BCC ,
	   A.QTD_PESQUISAS_BCE ,
	   A.QTD_PESSOAS_CONTRATADAS ,
	   A.QTD_USUARIOS_CADASTRADOS ,
	   A.QTD_FUNC_ADMIN_BLOQUEADO ,
	   A.QTD_FUNC_ULT_2_MESES ,
	   A.SLA_NAO_CONFIGURADO ,
	   A.TESTE_CUSTOMIZADO ,
	   A.CONFIGUROU_POL_SENHA
INTO #TMP_GERAL
FROM #TMP_PERFIL_USO A
LEFT OUTER JOIN #TMP_BCE B ON B.Cliente_VAGAS = A.Cliente_VAGAS
ORDER BY Data_Contrato DESC  

DECLARE @ANO_REF SMALLDATETIME
-- Neste caso consideraremos vagas a partir da data ref. (ref = Início do ano anterior)
SELECT @ANO_REF = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,YEAR(GETDATE()) - 1) + '0101')

-- VAGAS ABERTAS POR MÊS
SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DtPrimInicioWeb_vaga,112)) AS Data_Publicacao,
	   B.Ident_Cli AS Cliente_VAGAS,
	   COUNT(*) AS QTD_VAGAS 
INTO #TMP_VAGAS
FROM [hrh-data].dbo.Vagas A
INNER JOIN [hrh-data].dbo.Clientes B ON B.Cod_Cli = A.CodCliente_vaga
WHERE ColetaCur_vaga = 0 -- Não contar vagas de CAPTAÇÃO  
AND VagaComExt_Vaga = 0 -- Não contabilizar Vagas veiculadas em comunidades Externas  
AND TipoProcesso_vaga = 0 -- Não Contabilizar VAGAS PET/PRC (verificar com Comercial se mantemos essa condição) -- 961131 (tipo 4 = VAGAS REDES)  
AND Teste_vaga = 0 -- -- nao eh uma vaga de teste (Não considerar no Cálculo)  
AND VagaModelo_vaga = 0 -- Vaga não é modelo              
AND LEFT(Cargo_vaga,5) <> 'demo ' -- a vaga nao foi criada durante uma demonstracao    
AND LEFT(Cargo_vaga,5) <> 'demo-' --     
AND DtPrimInicioWeb_vaga >= @ANO_REF 
AND A.Cod_Vaga <> 210366 -- Vaga com data pub. inconsistente  
GROUP BY CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DtPrimInicioWeb_vaga,112)),
		 B.Ident_Cli
ORDER BY Cliente_VAGAS, Data_Publicacao

DECLARE @DATA_REFERENCIA_12_MESES SMALLDATETIME

-- Neste caso consideraremos a data ref. como sendo 12 meses atrás [desconsiderando os dias do mes atual]
SELECT @DATA_REFERENCIA_12_MESES = DATEADD(MONTH,-12,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)) - DAY(GETDATE()) + 1)

-- drop table #TMP_VAGAS_MENSAL
SELECT Cliente_VAGAS,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= @DATA_REFERENCIA_12_MESES
		AND Data_Publicacao < DATEADD(MONTH,1,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_1,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,1,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,2,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_2,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,2,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,3,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_3,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,3,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,4,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_4,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,4,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,5,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_5,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,5,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,6,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_6,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,6,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,7,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_7,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,7,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,8,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_8,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,8,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,9,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_9,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,9,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,10,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_10,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,10,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,11,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_11,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= DATEADD(MONTH,11,@DATA_REFERENCIA_12_MESES)
		AND Data_Publicacao < DATEADD(MONTH,12,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_MES_12,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(DAY,-30,GETDATE()) ,112))
		AND Data_Publicacao <= GETDATE() ),0) AS QTD_Vagas_30_Dias,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(MONTH,-3,GETDATE()) - DAY(DATEADD(MONTH,-3,GETDATE())) + 1,112))
		AND Data_Publicacao <= DATEADD(MONTH,12,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_ULT_3_Meses,
	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(MONTH,-6,GETDATE()) - DAY(DATEADD(MONTH,-6,GETDATE())) + 1,112))
		AND Data_Publicacao <= DATEADD(MONTH,12,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_ULT_6_Meses,
 	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(MONTH,-9,GETDATE()) - DAY(DATEADD(MONTH,-9,GETDATE())) + 1,112))
		AND Data_Publicacao <=DATEADD(MONTH,12,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_ULT_9_Meses,
 	  ISNULL(( SELECT SUM(QTD_VAGAS) 
		FROM #TMP_VAGAS
		WHERE Cliente_Vagas = A.Cliente_Vagas
		AND Data_Publicacao  >= CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(MONTH,-12,GETDATE()) - DAY(DATEADD(MONTH,-12,GETDATE())) + 1,112))
		AND Data_Publicacao <= DATEADD(MONTH,12,@DATA_REFERENCIA_12_MESES) ),0) AS QTD_Vagas_ULT_12_Meses
INTO #TMP_VAGAS_MENSAL
FROM #TMP_VAGAS A
--WHERE Cliente_VAGAS = 'Amaggi'
GROUP BY Cliente_VAGAS

INSERT INTO VAGAS_DW.VAGAS_DW.TMP_CLIENTES (DATA_REFERENCIA,DATA_REFERENCIA_12_MESES_INICIO,DATA_REFERENCIA_12_MESES_FIM,COD_CLI,CLIENTE_VAGAS,
											QTD_MIN_VAGAS,QTD_MAX_VAGAS,QTD_MIN_RI_VAGAS,QTD_MAX_RI_VAGAS,DATA_CONTRATO_MANUT,CAPACIDADE_BCE,
											QTD_BCE,TIPO_CLIENTE_MANUT,QTD_CREDITOS_TOTAL,QTD_CREDITOS_DISPONIVEL,VALOR_CREDITOS_VAGAS,
											QTD_VAGAS_MES_1,QTD_VAGAS_MES_2,QTD_VAGAS_MES_3,QTD_VAGAS_MES_4,
											QTD_VAGAS_MES_5,QTD_VAGAS_MES_6,QTD_VAGAS_MES_7,QTD_VAGAS_MES_8,QTD_VAGAS_MES_9,QTD_VAGAS_MES_10,
											QTD_VAGAS_MES_11,QTD_VAGAS_MES_12,QTD_VAGAS_30_DIAS,QTD_VAGAS_ULT_3_MESES,QTD_VAGAS_ULT_6_MESES,
											QTD_VAGAS_ULT_9_MESES,QTD_VAGAS_ULT_12_MESES,CONTA_ID,UF,CIDADE,POSSUI_LOGO,
											JA_FOI_VAGAS_10_MAIS,ULT_DATA_VAGAS_10_MAIS,UNIDADES_CADASTRADAS,UNIDADES_ATIVADAS, QTD_LOGIN_ULT_30_DIAS, FONTE, QTD_FUNC_LOGIN_ULT_30_DIAS, QTD_FUNC_INATIVO, QTD_FUNC_ADMIN, QTD_PESQUISAS_BCC, QTD_PESQUISAS_BCE, QTD_PESSOAS_CONTRATADAS, QTD_USUARIOS_CADASTRADOS, QTD_FUNC_ADMIN_BLOQUEADO, QTD_FUNC_ULT_2_MESES, SLA_NAO_CONFIGURADO,TESTE_CUSTOMIZADO, CONFIGUROU_POL_SENHA,QTD_FUNCIONARIOS_REMOVIDOS)
SELECT CONVERT(SMALLDATETIME,CONVERT(VARCHAR,GETDATE(),112)) AS DATA_REFERENCIA,
	   @DATA_REFERENCIA_12_MESES, -- DATA REF. INICIO (12 MESES PRA TRÁS)
	   DATEADD(MONTH,12,@DATA_REFERENCIA_12_MESES), -- DATA REF. FIM (INICIO DO MES ATUAL DE REF.)
	   A.COD_CLI,
	   A.Cliente_VAGAS,
	   A.QtdMin_VAGAS,
	   A.QtdMax_VAGAS,
	   A.QtdMin_RI_VAGAS,
	   A.QtdMax_RI_VAGAS,
	   A.Data_Contrato,
	   A.Capacidade_BCE,
	   A.QTD_BCE,
	   A.Tipo_Cliente,
	   A.Creditos_Total,
	   A.Creditos_Disponivel,
	   A.Creditos_Valor,
	   ISNULL(B.QTD_Vagas_MES_1,0) AS QTD_Vagas_MES_1,
	   ISNULL(B.QTD_Vagas_MES_2,0) AS QTD_Vagas_MES_2,
	   ISNULL(B.QTD_Vagas_MES_3,0) AS QTD_Vagas_MES_3,
	   ISNULL(B.QTD_Vagas_MES_4,0) AS QTD_Vagas_MES_4,
	   ISNULL(B.QTD_Vagas_MES_5,0) AS QTD_Vagas_MES_5,
	   ISNULL(B.QTD_Vagas_MES_6,0) AS QTD_Vagas_MES_6,
	   ISNULL(B.QTD_Vagas_MES_7,0) AS QTD_Vagas_MES_7,
	   ISNULL(B.QTD_Vagas_MES_8,0) AS QTD_Vagas_MES_8,
	   ISNULL(B.QTD_Vagas_MES_9,0) AS QTD_Vagas_MES_9,
	   ISNULL(B.QTD_Vagas_MES_10,0) AS QTD_Vagas_MES_10,
	   ISNULL(B.QTD_Vagas_MES_11,0) AS QTD_Vagas_MES_11,
	   ISNULL(B.QTD_Vagas_MES_12,0) AS QTD_Vagas_MES_12,
	   ISNULL(B.QTD_Vagas_30_DIAS,0) AS QTD_Vagas_30_DIAS,
	   ISNULL(B.QTD_Vagas_ULT_3_Meses,0) AS QTD_Vagas_ULT_3_Meses,
	   ISNULL(B.QTD_Vagas_ULT_6_Meses,0) AS QTD_Vagas_ULT_6_Meses,
	   ISNULL(B.QTD_Vagas_ULT_9_Meses,0) AS QTD_Vagas_ULT_9_Meses, 
	   ISNULL(B.QTD_Vagas_ULT_12_Meses,0) AS QTD_Vagas_ULT_12_Meses,
	   CONTA_ID,
	   UF,
	   CIDADE,
	   POSSUI_LOGO,
	   JA_FOI_VAGAS_10_MAIS,
	   ULT_DATA_VAGAS_10_MAIS,
	   QTD_UNIDADES_CADASTRADAS,
	   QTD_UNIDADES_ATIVADAS ,
	   ISNULL(A.QTD_LOGIN_ULT_30_DIAS, 0) AS QTD_LOGIN_ULT_30_DIAS ,
	   'MANUT' AS FONTE ,
	   QTD_FUNC_LOGIN_ULT_30_DIAS ,
	   QTD_FUNC_INATIVO ,
	   QTD_FUNC_ADMIN ,
	   QTD_PESQUISAS_BCC ,
	   QTD_PESQUISAS_BCE ,
	   QTD_PESSOAS_CONTRATADAS ,
	   QTD_USUARIOS_CADASTRADOS ,
	   QTD_FUNC_ADMIN_BLOQUEADO ,
	   QTD_FUNC_ULT_2_MESES ,
	   SLA_NAO_CONFIGURADO ,
	   TESTE_CUSTOMIZADO ,
	   CONFIGUROU_POL_SENHA ,
	   QTD_FUNCIONARIOS_REMOVIDOS
FROM #TMP_GERAL A 
LEFT OUTER JOIN #TMP_VAGAS_MENSAL B ON B.Cliente_VAGAS = A.Cliente_VAGAS
ORDER BY 5

DROP TABLE #TMP_PERFIL_USO
DROP TABLE #TMP_GERAL
DROP TABLE #TMP_VAGAS_MENSAL
DROP TABLE #TMP_VAGAS
DROP TABLE #TMP_BCE

GO