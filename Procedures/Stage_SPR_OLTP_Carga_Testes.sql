-- =============================================
-- Author: Fiama
-- Create date: 18/06/2018
-- Description: Procedure para carga das tabelas temporárias (BD Stage) para alimentação do DW
-- =============================================

USE [STAGE] ;

IF EXISTS (SELECT * FROM SYS.OBJECTS WHERE NAME = 'Stage_SPR_OLTP_Carga_Testes' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Testes] ;
GO

CREATE PROCEDURE [VAGAS_DW].[Stage_SPR_OLTP_Carga_Testes]
AS
SET NOCOUNT ON

-- Limpeza da tabela:
TRUNCATE TABLE [VAGAS_DW].[TMP_TESTES] ;

	-- Extraindo os testes para carga na visão domínio:
SELECT	A.Cod_fic AS COD_TESTE ,
		A.Ident_fic AS NOME_TESTE ,
		A.CodCli_fic AS COD_CLI_TESTE ,
		IIF(A.TesteGlobal_fic = 1, 'SIM', 'NÃO') AS GLOBAL_TESTE ,
		CHOOSE(A.CodIdioma_fic, 'PORTUGUÊS', 'ESPANHOL', 'INGLÊS') AS IDIOMA_TESTE ,
		IIF(A.Ident_fic IN ('Teste de inglês - VAGAS', 'Teste de língua portuguesa - VAGAS', 'Teste de espanhol - VAGAS'), 'SIM', 'NÃO') AS TESTE_IDIOMAS ,
		IIF( A.TesteGlobal_fic = 0
				AND NOT A.Ident_fic IN ('Teste de espanhol - VAGAS', 'Teste de inglês - VAGAS') , 'SIM', 'NÃO') AS TESTE_CUSTOMIZADO ,
		IIF( A.TesteGlobal_fic = 0
				AND NOT A.Ident_fic IN ('Teste de espanhol - VAGAS', 'Teste de inglês - VAGAS') , 'Teste customizado', A.Ident_fic) AS CLASSIFICACAO_TESTE ,
		CodFunc_fic as COD_FUNC ,
		ConstrutorFicha_fic AS FLAG_CONSTRUTOR_TESTES ,
		CONVERT(DATE,DataCriacao_fic) AS DATA_CRIACAO,
		CONVERT(DATE,DataAlteracao_fic) AS DATA_ALTERACAO,
		NULL AS DATA_RASCUNHO,
		0 FLAG_RASCUNHO,
		(select iif(status is null, null, 'Teste') from stage.vagas_dw.testes_construtor where company_id = CodCli_fic and name = Ident_fic) RASCUNHO_CONV_TESTE
INTO	#TMP_TESTES
FROM	[hrh-data].[dbo].[Fichas-DescrGeral] AS A
WHERE	A.Teste_fic = 4
UNION ALL
SELECT	isnull(( select Teste_A1.Cod_fic from [hrh-data].[dbo].[Fichas-DescrGeral] AS Teste_A1
				 where	name = Teste_A1.Ident_fic
						and company_id = Teste_A1.CodCli_fic), id * -1),
		name,
		company_id,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		employee_id,
		1,
		CONVERT(DATE, created_at),
		CONVERT(DATE, updated_at),
		CONVERT(DATE, created_at),
		1,
		IIF(status = 0, 'Rascunho', 'Teste')
FROM	[STAGE].[VAGAS_DW].[TESTES_CONSTRUTOR] ;



	-- Inserindo os registros na visão domínio:
	INSERT INTO [VAGAS_DW].[TMP_TESTES] (COD_TESTE,
NOME_TESTE,COD_CLI_TESTE,GLOBAL_TESTE,IDIOMA_TESTE,TESTE_IDIOMAS,TESTE_CUSTOMIZADO,CLASSIFICACAO_TESTE,COD_FUNC,FLAG_CONSTRUTOR_TESTES,DATA_CRIACAO,DATA_ALTERACAO,DATA_RASCUNHO,FLAG_RASCUNHO, RASCUNHO_CONV_TESTE)
	SELECT	A.COD_TESTE ,
			A.NOME_TESTE ,
			A.COD_CLI_TESTE ,
			A.GLOBAL_TESTE ,
			A.IDIOMA_TESTE ,
			A.TESTE_IDIOMAS ,
			A.TESTE_CUSTOMIZADO ,
			A.CLASSIFICACAO_TESTE,
			A.COD_FUNC,
			FLAG_CONSTRUTOR_TESTES,
			DATA_CRIACAO,
			DATA_ALTERACAO,
			DATA_RASCUNHO,
			FLAG_RASCUNHO,
			RASCUNHO_CONV_TESTE
	FROM	#TMP_TESTES AS A ;


-- Ajuste de inconsistência: o status no postgres está como teste, mas não é um teste:
update	[vagas_dw].[tmp_testes]
set		rascunho_conv_teste = 'Rascunho'
from	[vagas_dw].[tmp_testes] as Test
where	cod_teste < 0
		and rascunho_conv_teste = 'Teste' ;

-- Apaga registro inválido:
delete from vagas_dw.tmp_testes
where cod_cli_teste = 0 ;


-- Insere a data do rascunho pra valores provindos do banco legado:
update	[vagas_dw].[tmp_testes]
set		data_rascunho =	(select	Tmp_teste_A1.data_rascunho 
						 from	[vagas_dw].[tmp_testes] as Tmp_teste_A1 
						 where	Tmp_teste.cod_teste = Tmp_teste_A1.cod_teste
								and Tmp_teste_A1.flag_rascunho = 1)
from	[vagas_dw].[tmp_testes] as Tmp_teste		inner join [vagas_dw].[VAGAS_DW].[CLIENTES] as DW_Cli
													on Tmp_teste.cod_cli_teste = DW_Cli.Cod_cli
where	flag_construtor_testes = 1
		and isnull(rascunho_conv_teste, '') <> ''
		and flag_rascunho = 0 ;