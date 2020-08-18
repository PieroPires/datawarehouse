USE STAGE
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLTP_Carga_Vagas_Validacao' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Vagas_Validacao
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLTP_Carga_Vagas_Validacao 
@COD_VALIDACAO INT = NULL

AS
SET NOCOUNT ON

TRUNCATE TABLE VAGAS_DW.TMP_VAGAS_VALIDACAO

IF @COD_VALIDACAO IS NULL
SET @COD_VALIDACAO = 0

INSERT INTO VAGAS_DW.TMP_VAGAS_VALIDACAO 
SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Sem Ajuste' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.SemAjuste_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Ajuste Simples' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteSimples_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Nivel Area' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteNiveisAreas_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Escolaridade' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteEscolaridade_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Local' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteLocal_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Nivel' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteNiveis_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Area' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteAreas_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Correção Estética' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteCorrecaoEst_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Ortografia' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteOrtografia_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'CV para outra Fonte' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteCVOutraFonte_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Info. para Proc. Seletivo' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteInfoProcSel_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Experiência' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteExperiencia_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Idade' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteIdade_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Sexo' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteSexo_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Características Físicas' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteCaractFisicas_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Instituição de Ensino' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteInstituicaoEns_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'PJ/Autônomo' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjustePJAutonomo_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Sem Conteúdo' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteSemConteudo_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Ambiente de RI' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteAmbienteRI_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Vários Perfis' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteVariosPerfis_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Divergência de conteúdo/filtros' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteDtDivergentes_vagaVal = 1


UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Vários perfis/Aumento de banco' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteVariosPerfisAumentoBanco_vagaVal = 1

UNION ALL

SELECT A.Cod_vagaVal AS COD_VALIDACAO,
	   A.CodVaga_vagaVal AS COD_VAGA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataEntrada_vagaVal),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataEntrada_vagaVal,112))) AS DATA_ENTRADA,
	   DATEADD(HOUR,DATEPART(HOUR,A.DataValidacao_vagaVal ),CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DataValidacao_vagaVal ,112))) AS DATA_VALIDACAO,	
	   B.Ident_usuman AS USUARIO,
	   A2.Ident_Cli AS CLIENTE,
	   'Aumento de banco' AS TIPO_AJUSTE
FROM [hrh-data].dbo.[Vagas-Validacao] A
INNER JOIN [hrh-data].dbo.Vagas A1 ON A1.Cod_Vaga = A.CodVaga_vagaVal
INNER JOIN [hrh-data].dbo.Clientes A2 ON A2.Cod_Cli = A1.CodCliente_vaga
LEFT OUTER JOIN [hrh-data].dbo.ManutUsuarios B ON B.Cod_usuman = A.CodUsuMan_vagaVal
WHERE A.AjusteAumentoBanco_vagaVal = 1

GO