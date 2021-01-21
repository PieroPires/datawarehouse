USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_Demandas_Equipe_Solucoes_Personalizadas_Enriquecimentos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Demandas_Equipe_Solucoes_Personalizadas_Enriquecimentos
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 29/09/2015
-- Description: Procedure para alimentação do DW
-- =============================================
CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_Demandas_Equipe_Solucoes_Personalizadas_Enriquecimentos

AS
SET NOCOUNT ON


-- Gera a tabela que extrai os motivos vs o número da demanda:
select	id_SOLUDSM_completo_URL as Numero_demanda
		, motivo_do_fechamento_c as Motivo_fechamento
		, Fase
		, OportunidadeCategoria
		, Conta
		, Oportunidade
		, convert(date, DataFechamento) as DataFechamento
into	#Tab_Motivos_SOLUDSM
from	openquery(mysqlprovider, 'SELECT
										id_c AS id_OportunidadeCRM,
										link_projeto_c AS link_projeto_SOLUDSM, 
										#REVERSE(SUBSTRING(REVERSE(TRIM(link_projeto_c)), 1, LOCATE(''/'', REVERSE(TRIM(link_projeto_c))))) ,
										#LENGTH(REVERSE(SUBSTRING(REVERSE(TRIM(link_projeto_c)), 1, LOCATE(''/'', REVERSE(TRIM(link_projeto_c)))))) - LENGTH(''/SOLUDSM-''),
										RIGHT(REVERSE(SUBSTRING(REVERSE(TRIM(link_projeto_c)), 1, LOCATE(''/'', REVERSE(TRIM(link_projeto_c))))), LENGTH(REVERSE(SUBSTRING(REVERSE(TRIM(link_projeto_c)), 1, LOCATE(''/'', REVERSE(TRIM(link_projeto_c)))))) - LENGTH(''/SOLUDSM-'')) AS id_SOLUDSM_completo_URL,
										IF(RIGHT(REVERSE(SUBSTRING(REVERSE(TRIM(link_projeto_c)), 1, LOCATE(''/'', REVERSE(TRIM(link_projeto_c))))), LENGTH(REVERSE(SUBSTRING(REVERSE(TRIM(link_projeto_c)), 1, LOCATE(''/'', REVERSE(TRIM(link_projeto_c)))))) - LENGTH(''/SOLUDSM-'')) 
										NOT REGEXP ''^-?[0-9]+$'',1,0) AS id_SOLUDSM,
										motivo_do_fechamento_c,
										motivo_do_fechamento_detalhe_c,
										motivo_do_fechamento_compl_c
								  FROM	sugarcrm.opportunities_cstm
								  WHERE	link_projeto_c LIKE ''%SOLUDSM%''') as Opp_SOLUDSM	inner join [VAGAS_DW].[OPORTUNIDADES] as Opp
																							on Opp_SOLUDSM.id_OportunidadeCRM = Opp.OportunidadeID 
																							collate SQL_Latin1_General_CP1_CI_AI
where	Opp.INSERT_MANUAL is null
		and isnumeric(id_SOLUDSM_completo_URL) = 1 ;



-- Limpar tabela:
truncate table [VAGAS_DW].[Demandas_SOLUDSM_Motivos];

insert into [VAGAS_DW].[Demandas_SOLUDSM_Motivos]
select	distinct Motivos.Numero_demanda
		, isnull(Motivo_fechamento_MaisRec.Motivo_fechamento, '') as Motivo_fechamento
		, Motivo_fechamento_MaisRec.Fase
		, Motivo_fechamento_MaisRec.OportunidadeCategoria
		, Motivo_fechamento_MaisRec.Conta
		, Motivo_fechamento_MaisRec.Oportunidade
		, Motivo_fechamento_MaisRec.DataFechamento
from	#Tab_Motivos_SOLUDSM as Motivos		outer apply (select top 1 *
														 from	#Tab_Motivos_SOLUDSM as Motivos_a1
														 where	Motivos.Numero_demanda = Motivos_a1.Numero_demanda
																and Motivos_a1.Motivo_fechamento <> 'higienizacao_sugar'
														 order by
																Motivos_a1.DataFechamento desc) as Motivo_fechamento_MaisRec ;