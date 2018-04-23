-- =============================================
-- Author: Fiama
-- Create date: 21/12/2017
-- Description: Script para extração do histórico de casos.
-- =============================================

SELECT	SUBQUERY_2.ID_CASO ,
		SUBQUERY_2.NUMERO_CASO ,
        SUBQUERY_2.VALOR_ANTERIOR ,
        SUBQUERY_2.NOVO_VALOR ,
        SUBQUERY_2.ALTERADOR ,
        SUBQUERY_2.DATA_ALTERACAO ,
        SUBQUERY_2.ROW_NUMBER
FROM	(
		SELECT	CONVERT(SUBQUERY.ID_CASO USING Latin1) AS ID_CASO ,
				CONVERT(SUBQUERY.NUMERO_CASO USING Latin1) AS NUMERO_CASO ,
				CONVERT(SUBQUERY.VALOR_ANTERIOR USING Latin1) AS VALOR_ANTERIOR ,
				CONVERT(SUBQUERY.NOVO_VALOR USING Latin1) AS NOVO_VALOR ,
				CONVERT(SUBQUERY.ALTERADOR USING Latin1) AS ALTERADOR ,
				SUBQUERY.DATA_ALTERACAO ,
				@ROW_NUMBER:= IF(@NUMERO_CASO = SUBQUERY.NUMERO_CASO, @ROW_NUMBER + 1, 1) AS ROW_NUMBER ,
				@NUMERO_CASO:= SUBQUERY.NUMERO_CASO
		FROM	(
					SELECT	A.id AS ID_CASO ,
							A.case_number AS NUMERO_CASO ,
							UPPER(B.before_value_string) AS VALOR_ANTERIOR ,
							UPPER(B.after_value_string) AS NOVO_VALOR ,
							C.user_name AS ALTERADOR ,
							CONVERT_TZ(B.date_created, @@session.time_zone, 'America/Sao_Paulo') AS DATA_ALTERACAO
					FROM	cases AS A	INNER JOIN cases_audit AS B ON A.id = B.parent_id
										LEFT OUTER JOIN users AS C ON B.created_by = C.id AND C.deleted = 0 
					WHERE	A.deleted = 0 
							AND B.field_name = 'status'
					ORDER BY
							NUMERO_CASO ASC ,
							DATA_ALTERACAO ASC
				) AS SUBQUERY
		) AS SUBQUERY_2 ;