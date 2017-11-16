-- =============================================
-- Author: Fiama
-- Create date: 09/11/2017
-- Description: Histórico do status de transição dos links no CRM.
-- =============================================

USE sugarcrm ;

# -------------------------------------------------- #
# Histórico do status de transição dos links no CRM:
# -------------------------------------------------- #
SET	@ID_LINK  = '' ;
SET	@ROW_NUMBER = 0	 ;

SELECT	CONVERT(SUBQUERY_2.ID_LINK USING Latin1) AS ID_LINK ,
		CONVERT(SUBQUERY_2.NOME_LINK USING Latin1) AS NOME_LINK ,
        SUBQUERY_2.DATA_CRIACAO_ALTERACAO ,
        CONVERT(SUBQUERY_2.VALOR_ANTERIOR USING Latin1) AS VALOR_ANTERIOR ,
        CONVERT(SUBQUERY_2.VALOR_POSTERIOR USING Latin1) AS VALOR_POSTERIOR ,
        SUBQUERY_2.ROW_NUMBER
FROM	(
	SELECT	SUBQUERY.ID_LINK ,
			SUBQUERY.NOME_LINK ,
			SUBQUERY.DATA_CRIACAO_ALTERACAO ,
			SUBQUERY.VALOR_ANTERIOR ,
			SUBQUERY.VALOR_POSTERIOR ,
			@ROW_NUMBER:= IF(@ID_LINK = SUBQUERY.ID_LINK, @ROW_NUMBER + 1, 1) AS ROW_NUMBER ,
			@ID_LINK := SUBQUERY.ID_LINK AS ID_LINK_CONTROLE
	FROM	(
		SELECT	B.id AS ID_LINK  ,
				B.name AS NOME_LINK ,
				CONVERT_TZ(A.date_created, @@session.time_zone, '-03:00') AS DATA_CRIACAO_ALTERACAO ,
				C.user_name AS USUARIO_ALTERACAO ,
				A.before_value_string AS VALOR_ANTERIOR ,
				A.after_value_string AS VALOR_POSTERIOR
		FROM	sugarcrm.lnk_links_audit AS A	LEFT OUTER JOIN sugarcrm.lnk_links AS B ON A.parent_id = B.id
												LEFT OUTER JOIN sugarcrm.users AS C ON A.created_by = C.id
		WHERE	A.field_name = 'status' ) AS SUBQUERY
ORDER BY
	SUBQUERY.ID_LINK ASC ,
	SUBQUERY.DATA_CRIACAO_ALTERACAO ASC) AS SUBQUERY_2 ;