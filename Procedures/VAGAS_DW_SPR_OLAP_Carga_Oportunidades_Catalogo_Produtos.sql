-- =============================================
-- Author: Fiama
-- Create date: 10/07/2019
-- Description: Cat?logo de Produtos do CRM x Cubo de Oportunidades.
-- =============================================

USE [VAGAS_DW] ;

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Catalogo_Produtos' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Catalogo_Produtos]
GO

CREATE PROCEDURE [VAGAS_DW].[VAGAS_DW_SPR_OLAP_Carga_Oportunidades_Catalogo_Produtos]
AS
SET NOCOUNT ON 

-- Novo Cat?logo de produtos:
UPDATE	[VAGAS_DW].[OPORTUNIDADES]
SET		COD_PRODUTO =	CASE
							WHEN A.PRODUTO IN ('FIT', 'VAGAS FIT ANUID', 'VAGAS FIT LIC', 'VAGAS FIT REV', 'VAGAS FIT EI')
								THEN 'FIT'
							WHEN A.PRODUTO IN ('CRED.VAGAS', 'VAGAS PONTUAL')
								THEN 'VAGAS PONTUAL'
							WHEN A.PRODUTO IN ('VETM', 'COMPL AVALIACAOM')
								THEN 'COMPL AVALIACAOM'
							WHEN A.PRODUTO IN ('VETP', 'COMPL AVALIACAOP')
								THEN 'COMPL AVALIACAOP'
							WHEN A.PRODUTO IN ('COMPL EBPORT', 'COMPL PORTAL')
								THEN 'COMPL PORTAL'
							WHEN A.PRODUTO IN ('SMS', 'COMPL SMSM', 'COMPL SMS')
								THEN 'COMPL SMS'
							WHEN A.PRODUTO IN ('PET', 'VAGAS PETM', 'VAGAS PETP')
								THEN 'VAGAS PETP'
							WHEN A.PRODUTO IN ('PUBL.ADNETWORK', 'PUBL ADNETWORK')
								THEN 'PUBL ADNETWORK'
							WHEN A.PRODUTO IN ('PUBL.BANNER', 'PUBL BANNER', 'PUBL.EDITORIAL')
								THEN 'PUBL BANNER'
							WHEN A.PRODUTO IN ('PUBL.MAILMKT', 'PUBL MAILMKT')
								THEN 'PUBL MAILMKT'
							WHEN A.PRODUTO IN ('PUBL.POST', 'PUBL POST')
								THEN 'PUBL POST'
							WHEN A.PRODUTO IN ('DSMCORT', 'SERV DSM CORTESIA')
								THEN 'SERV DSM CORTESIA'
							WHEN A.PRODUTO IN ('DSMFRANQ', 'SERV DSM FRANQUIA')
								THEN 'SERV DSM FRANQUIA'
							WHEN A.PRODUTO IN ('EI')
								THEN 'EI'
							WHEN A.PRODUTO IN ('REV')
								THEN 'REV'
							WHEN A.PRODUTO IN ('VREDES', 'VAGAS REDES')
								THEN 'VAGAS REDES'
							WHEN A.PRODUTO IN ('COMPL HOMEPAGE', 'COMPL HOMEPAGE')
								THEN 'COMPL HOMEPAGE'
							WHEN A.PRODUTO IN ('VAGAS RECRUTADOR', 'VAGAS RECRUTADOR ANUID')
								THEN 'VAGAS RECRUTADOR'
							ELSE A.PRODUTO
						END
FROM	[VAGAS_DW].[OPORTUNIDADES] AS A ;