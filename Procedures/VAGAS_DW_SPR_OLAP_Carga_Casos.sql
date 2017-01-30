USE VAGAS_DW
GO

IF EXISTS ( SELECT * FROM SYS.OBJECTS WHERE NAME = 'SPR_OLAP_Carga_CASOS' AND SCHEMA_NAME(SCHEMA_ID) = 'VAGAS_DW')
DROP PROCEDURE VAGAS_DW.SPR_OLAP_Carga_CASOS
GO

-- =============================================
-- Author: Luiz Fernando Braz
-- Create date: 19/05/2016
-- Description: Procedure para carga das tabelas tempor�rias (BD Stage) para alimenta��o do DW
-- =============================================

CREATE PROCEDURE VAGAS_DW.SPR_OLAP_Carga_CASOS 
AS
SET NOCOUNT ON

DELETE VAGAS_DW.CASOS
FROM VAGAS_DW.CASOS A
WHERE EXISTS ( SELECT 1 FROM VAGAS_DW.TMP_CASOS
				WHERE ID_CASO = A.ID_CASO )

SELECT ID_CASO,NUMERO_CASO,CONTA,FILA_ATENDIMENTO,STATUS,PRIORIDADE,CRITICIDADE,ORIGEM,TIPO,SUB_TIPO,DATA_INICIO_ATENDIMENTO,
		    DATA_FECHAMENTO,DATA_INCLUSAO,DATA_MODIFICACAO,USUARIO_RESPONSAVEL,ORIGEM_SUPORTE,DATA_PRM_ACAO,
	   CASE WHEN DATEPART(WEEKDAY,DATA_INCLUSAO_NORMALIZADA) = 7 -- S�BADO
			THEN DATEADD(HOUR,8,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(DAY,2,DATA_INCLUSAO_NORMALIZADA),112)))
			WHEN DATEPART(WEEKDAY,DATA_INCLUSAO_NORMALIZADA) = 1 -- DOMINGO
			THEN DATEADD(HOUR,8,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATEADD(DAY,1,DATA_INCLUSAO_NORMALIZADA),112)))
			ELSE DATA_INCLUSAO_NORMALIZADA END AS DATA_INCLUSAO_NORMALIZADA
INTO #TMP_DATA_NORMALIZADA 
FROM 
	(

	-- TRATAR CHAMADOS ABERTOS FORA DO HOR�RIO DE EXPEDIENTE (08:00 �S 19:00)
	SELECT ID_CASO,NUMERO_CASO,CONTA,FILA_ATENDIMENTO,STATUS,PRIORIDADE,CRITICIDADE,ORIGEM,TIPO,SUB_TIPO,DATA_INICIO_ATENDIMENTO,
		    DATA_FECHAMENTO,DATA_INCLUSAO,DATA_MODIFICACAO,USUARIO_RESPONSAVEL,ORIGEM_SUPORTE,DATA_PRM_ACAO,
			CASE WHEN DATEPART(HOUR,DATA_INCLUSAO) >= 19 
							THEN DATEADD(HOUR,8,DATEADD(DAY,1,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_INCLUSAO,112))))
							WHEN DATEPART(HOUR,DATA_INCLUSAO) < 8 
							THEN DATEADD(HOUR,8,CONVERT(SMALLDATETIME,CONVERT(VARCHAR,DATA_INCLUSAO,112)))
							ELSE DATA_INCLUSAO END AS DATA_INCLUSAO_NORMALIZADA
	FROM VAGAS_DW.TMP_CASOS
	WHERE FLAG_DELETADO = 0
	
	) TAB
ORDER BY 1

-- TRATAR FERIADOS NACIONAIS + SP 
UPDATE #TMP_DATA_NORMALIZADA SET DATA_INCLUSAO_NORMALIZADA = CASE
				-- se o pr�x. dia for s�bado adiantar 3 dias (seg.) 
				 WHEN DATEPART(WEEKDAY,DATEADD(DAY,1,DATA_INCLUSAO_NORMALIZADA)) = 7 THEN DATEADD(HOUR, 8, CONVERT(SMALLDATETIME, CONVERT(VARCHAR, DATEADD(DAY,3,DATA_INCLUSAO_NORMALIZADA), 112))) 
				-- se o pr�x. dia for domingo adiantar 2 dias 
				 WHEN DATEPART(WEEKDAY,DATEADD(DAY,1,DATA_INCLUSAO_NORMALIZADA)) = 1 THEN DATEADD(HOUR, 8, CONVERT(SMALLDATETIME, CONVERT(VARCHAR, DATEADD(DAY,2,DATA_INCLUSAO_NORMALIZADA), 112))) 
        ELSE DATEADD(HOUR, 8, CONVERT(SMALLDATETIME, CONVERT(VARCHAR, DATEADD(DAY,1,DATA_INCLUSAO_NORMALIZADA), 112))) END 
FROM #TMP_DATA_NORMALIZADA A
WHERE EXISTS ( SELECT 1
				FROM VAGAS_DW.FERIADOS_NACIONAIS -- CONT�M OS FERIADOS BRA + SP ATE 2019
				WHERE DATA = CONVERT(SMALLDATETIME,CONVERT(VARCHAR,A.DATA_INCLUSAO_NORMALIZADA,112)) )



	-- EXTRA��O DAS QUANTIDADES
	SELECT ID_CASO ,
		NUMERO_CASO ,
		CONTA ,
		FILA_ATENDIMENTO ,
		[STATUS] ,
		PRIORIDADE ,
		CRITICIDADE ,
		ORIGEM ,
		TIPO ,
		SUB_TIPO ,
		DATA_INICIO_ATENDIMENTO ,
		DATA_FECHAMENTO ,
		DATA_INCLUSAO ,
		DATA_MODIFICACAO ,
		USUARIO_RESPONSAVEL ,
		ORIGEM_SUPORTE ,
		DATA_PRM_ACAO ,
		DATA_INCLUSAO_NORMALIZADA , 
		CASE WHEN (CASE WHEN ORIGEM_SUPORTE = 'E-mail' THEN DATEDIFF(HOUR, DATA_INCLUSAO_NORMALIZADA, DATA_PRM_ACAO) ELSE NULL END) < 0 THEN 0 ELSE (CASE WHEN ORIGEM_SUPORTE = 'E-mail' THEN DATEDIFF(HOUR, DATA_INCLUSAO_NORMALIZADA, DATA_PRM_ACAO) ELSE NULL END) END AS TME ,
		CASE WHEN (CASE WHEN A.STATUS IN ('fechado', 'fechado_sem_resposta') AND A.FILA_ATENDIMENTO = 'suporte_empresas' THEN DATEDIFF(HOUR, A.DATA_INCLUSAO_NORMALIZADA, ISNULL(A.DATA_FECHAMENTO, A.DATA_MODIFICACAO)) ELSE NULL END) < 0 THEN 0 ELSE (CASE WHEN A.STATUS IN ('fechado', 'fechado_sem_resposta') AND A.FILA_ATENDIMENTO = 'suporte_empresas' THEN DATEDIFF(HOUR, A.DATA_INCLUSAO_NORMALIZADA, ISNULL(A.DATA_FECHAMENTO, A.DATA_MODIFICACAO)) ELSE NULL END) END AS TMS
	INTO	#TMR_CASOS
	FROM	#TMP_DATA_NORMALIZADA AS A
	--WHERE	A.FILA_ATENDIMENTO = 'suporte_empresas'
	--AND A.STATUS = 'fechado'
	ORDER BY A.NUMERO_CASO ASC 
	OPTION (MAXRECURSION 32767);
-- (354 row(s) affected)



-- Inserir novos casos 
INSERT INTO VAGAS_DW.CASOS (ID_CASO,NUMERO_CASO,CONTA,FILA_ATENDIMENTO,[STATUS],PRIORIDADE,CRITICIDADE,ORIGEM,TIPO,SUB_TIPO,DATA_INICIO_ATENDIMENTO,DATA_FECHAMENTO,  DATA_INCLUSAO,DATA_MODIFICACAO,USUARIO_RESPONSAVEL,ORIGEM_SUPORTE,DATA_PRM_ACAO,DATA_INCLUSAO_NORMALIZADA,TME) 
SELECT  ID_CASO,NUMERO_CASO,CONTA,FILA_ATENDIMENTO,[STATUS],PRIORIDADE,CRITICIDADE,ORIGEM,TIPO,SUB_TIPO,DATA_INICIO_ATENDIMENTO,DATA_FECHAMENTO,  DATA_INCLUSAO,DATA_MODIFICACAO,USUARIO_RESPONSAVEL,ORIGEM_SUPORTE,DATA_PRM_ACAO,DATA_INCLUSAO_NORMALIZADA,TME 
FROM #TMR_CASOS

 
 
-- Tratamento de erro operacional, para 188 casos especificados pelo Ed Carlos (Suporte a Empresas) em 13/12/2016:  (EM CASO DE CARGA FULL)
UPDATE  VAGAS_DW.CASOS 
SET    TME = 0 
FROM  VAGAS_DW.CASOS 
WHERE  NUMERO_CASO IN (61435 ,39192 ,49922 
,44793 ,44797 ,44813 ,44521 ,44552 ,44591 ,44600 ,44616 ,44610 ,44684 ,44734 ,45118 ,45119 ,44831 ,44832 ,45120 ,45169 ,45175 ,44872 ,
45185 ,45186 ,44881 ,44884 ,44886 ,44887 ,44912 ,44960 ,44979 ,44987 ,44995 ,45002 ,45012 ,45094 ,45116 ,45114 ,131883 ,49350 ,49481 ,
49489 ,49488 ,49247 ,49561 ,49565 ,49610 ,49660 ,49558 ,49750 ,49804 ,49808 ,49814 ,49816 ,49876 ,49573 ,145151 ,49592 ,49594 ,49617 ,
49618 ,49619 ,49863 ,49865 ,49913 ,49915 ,49916 ,49918 ,131387 ,133287 ,133907 ,138370 ,27 ,138674 ,140495 ,143538 ,143965 ,140594 ,
151072 ,151092 ,151128 ,144554 ,139436 ,151496 ,144926 ,144928 ,148714 ,148715 ,151724 ,149769 ,149315 ,145441 ,145461 ,145462 ,26 ,
148914 ,145593 ,145597 ,145658 ,145691 ,149442 ,145774 ,149039 ,29 ,146041 ,150380 ,149761 ,152738 ,149803 ,149840 ,131269 ,131277 ,
149943 ,23  ,147411  ,139827  ,29  ,147451  ,150539  ,152521  ,143072  ,25  ,146993  ,139867  ,139519  ,139217  ,146290  ,139578  ,
146358  ,25  ,138781  ,28  ,146377  ,150642  ,146417  ,150940  ,150118  ,147514  ,146442  ,155321  ,141880  ,141883  ,141884  ,141885  ,
141886  ,157937  ,150990  ,141889  ,150178  ,141887  ,141888  ,141890  ,141891  ,141892  ,161319  ,159988  ,159989  ,153198  ,159257  ,
145736  ,141263  ,141265  ,149710  ,133892  ,138512  ,141270  ,162025  ,144418  ,140199  ,141271  ,161661  ,147876  ,145138  ,139644  ,
139971 );


-- Tratamento dos TMS com poss�veis erros operacionais: 22/12/2016 (EM CASO DE CARGA FULL)
UPDATE [VAGAS_DW].[VAGAS_DW].[CASOS]
SET TMS = NULL
FROM [VAGAS_DW].[VAGAS_DW].[CASOS] AS A
WHERE NUMERO_CASO IN (136290,142562,131530,131579,131529,131527,131520,131518,131515,131544,131538,131534,135492,136386,132102,
134007,139115,133311,136698) ;

