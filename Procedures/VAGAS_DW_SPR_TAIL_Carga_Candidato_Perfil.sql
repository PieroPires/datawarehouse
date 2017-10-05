USE VAGAS_DW
GO

-- EXEC VAGAS_DW.SPR_TAIL_Carga_Candidato_Perfil
IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_TAIL_Carga_Candidato_Perfil' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_TAIL_Carga_Candidato_Perfil
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 09/08/2017
-- Description: Procedure para alimenta��o do perfil do candidato (� professor ? � engenheiro ?etc) para possibilitar "onboarding" dos dados
-- na DMP Tail (Publicidade)
-- INSERT INTO VAGAS_DW.TAIL_TIPO_PERFIL VALUES('LOOKALIKE_REVENDEDOR_PERFUMARIA_RUIM')
-- SELECT * FROM VAGAS_DW.TAIL_TIPO_PERFIL 
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_TAIL_Carga_Candidato_Perfil 

AS
SET NOCOUNT ON

-- "� PROFESSOR?"
-- tenha alguma experi�ncia como professor e correlatos
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,1 AS TIPO_PERFIL -- PROFESSOR
FROM VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE ( A.DESCRICAO_EXPERIENCIA LIKE '%PROFESSOR%'
	  OR A.ULTIMO_CARGO LIKE '%PROFESSOR%'
	  OR A.ULTIMO_CARGO LIKE '%INSTRUTOR%' )
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 1 )
UNION

SELECT DISTINCT A.COD_CAND,1 AS TIPO_PERFIL
FROM VAGAS_DW.VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.AREA_INTERESSE IN ('Ensino Superior e Pesquisa','Ensino - Outros')
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 1 )
				 
-- TECNOLOGIA
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,2 AS TIPO_PERFIL
FROM VAGAS_DW.VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.AREA_INTERESSE = 'Inform�tica/T.I.'
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 2 )

-- ENGENHARIA
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,3 AS TIPO_PERFIL -- ENGENHARIA
FROM VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.ULTIMO_CARGO LIKE '%ENGENHEIR%'
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 3 )
UNION

SELECT DISTINCT A.COD_CAND,3 AS TIPO_PERFIL
FROM VAGAS_DW.VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.AREA_INTERESSE LIKE 'Engenharia%'
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 3 )


-- DIREITO
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,4 AS TIPO_PERFIL -- DIREITO
FROM VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.ULTIMO_CARGO LIKE '%ADVOGAD%'
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 4 )
UNION

SELECT DISTINCT A.COD_CAND,4 AS TIPO_PERFIL
FROM VAGAS_DW.VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.AREA_INTERESSE = 'Advocacia/Jur�dica'
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 4 )

-- MARKETING/COMUNICA��O
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,5 AS TIPO_PERFIL -- MARKETING_COMUNICACAO
FROM VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.ULTIMO_CARGO LIKE '%MARKETING%'
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 5 )
UNION

SELECT DISTINCT A.COD_CAND,5 AS TIPO_PERFIL
-- SELECT COUNT(DISTINCT A.COD_CAND)
FROM VAGAS_DW.VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.AREA_INTERESSE IN ('Comunica��o','Marketing')
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 5 )

-- RH
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,6 AS TIPO_PERFIL -- RH
-- SELECT COUNT(DISTINCT A.COD_CAND)
FROM VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE ( A.ULTIMO_CARGO LIKE '%RH%' OR A.ULTIMO_CARGO LIKE '%RECURSOS HUMANOS%' )
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 6 )
UNION

SELECT DISTINCT A.COD_CAND,6 AS TIPO_PERFIL
-- SELECT COUNT(DISTINCT A.COD_CAND)
FROM VAGAS_DW.VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.AREA_INTERESSE IN ('Recursos Humanos')
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 6 )

-- ADMINISTRA��O
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,7 AS TIPO_PERFIL
-- SELECT COUNT(DISTINCT A.COD_CAND)
FROM VAGAS_DW.VAGAS_DW.CANDIDATOS_AREA_INTERESSE A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE A.AREA_INTERESSE IN ('Administra��o Comercial/Vendas','Administra��o de Empresas','Administra��o P�blica','Servi�os Administrativos')
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 7 )

-- LIDERAN�A
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT DISTINCT A.COD_CAND,8 AS TIPO_PERFIL -- LIDERAN�A
FROM VAGAS_DW.EXPERIENCIAS_PROFISSIONAIS A
INNER JOIN VAGAS_DW.CANDIDATOS B ON B.COD_CAND = A.COD_CAND
WHERE ( ( A.ULTIMO_CARGO LIKE '%LIDER%'
		  OR A.ULTIMO_CARGO LIKE '%CHEFE%'
		  OR A.ULTIMO_CARGO LIKE '%HEAD%'
		  OR A.ULTIMO_CARGO LIKE '%DIRETOR%'
		  OR A.ULTIMO_CARGO LIKE '%DIRECTOR%'
		  OR A.ULTIMO_CARGO LIKE '%GERENTE%'
		  OR A.ULTIMO_CARGO LIKE '%MANAGER%'
		  OR A.ULTIMO_CARGO LIKE '%COORDENADOR%'
		  OR A.ULTIMO_CARGO LIKE '%COORDINATOR%'
		  OR A.ULTIMO_CARGO LIKE '%SUPERVISOR%' )
		OR ( B.NIVEL IN ('Supervis�o/Coordena��o','Ger�ncia','Diretoria') ) )
AND B.FEZ_ACESSO_IRRESTRITO = 1
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = B.COD_CAND 
				 AND TIPO_PERFIL = 8 )


-- LOOKALIKE_REVENDEDOR_PERFUMARIA
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT TOP 150000 COD_CAND,9 AS TIPO_PERFIL -- LOOKALIKE_REVENDEDOR_PERFUMARIA
FROM VAGAS_DW.LOOKALIKE_BOTICARIO_COD_CAND_PREDICTION A
WHERE PROB_CONVERTIDO >= 0.7 -- AUMENTAR CASO QUISERMOS ATINGIR UM PONTO DE CORTE MAIOR
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = A.COD_CAND 
				 AND TIPO_PERFIL = 9 )
ORDER BY NEWID()

-- LOOKALIKE_REVENDEDOR_PERFUMARIA RUIM (TEMPORARIO, APENAS COMO GRUPO DE CONTROLE)
INSERT INTO VAGAS_DW.TAIL_CANDIDATO_PERFIL (COD_CAND,TIPO_PERFIL)
SELECT COD_CAND,10 AS TIPO_PERFIL -- LOOKALIKE_REVENDEDOR_PERFUMARIA_RUIM
FROM VAGAS_DW.LOOKALIKE_BOTICARIO_COD_CAND_PREDICTION A
WHERE PROB_CONVERTIDO <= 0.3 
AND NOT EXISTS ( SELECT * 
				 FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL
				 WHERE COD_CAND = A.COD_CAND 
				 AND TIPO_PERFIL = 10 )

DELETE FROM VAGAS_DW.TAIL_CANDIDATO_PERFIL WHERE TIPO_PERFIL = 9