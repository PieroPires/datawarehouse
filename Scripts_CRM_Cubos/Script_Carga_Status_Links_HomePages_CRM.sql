-- =============================================
-- Author: Fiama
-- Create date: 09/11/2017
-- Description: Histórico do status de transição dos links no CRM.
-- =============================================

USE sugarcrm ;

# -------------------------------------------------- #
# Histórico do status de transição dos links no CRM:
# -------------------------------------------------- #
SET	@NOME_LINK  = '' ;
SET	@ROW_NUMBER = 0	 ;

SELECT	SUBQUERY_2.ID_ALTERACAO_LINK ,
		SUBQUERY_2.NOME_LINK ,
        SUBQUERY_2.DATA_CRIACAO_ALTERACAO ,
        SUBQUERY_2.VALOR_ANTERIOR ,
        SUBQUERY_2.VALOR_POSTERIOR ,
        SUBQUERY_2.FASES ,
        SUBQUERY_2.ROW_NUMBER
FROM	(
	SELECT	SUBQUERY.ID_ALTERACAO_LINK ,
			SUBQUERY.NOME_LINK ,
			SUBQUERY.DATA_CRIACAO_ALTERACAO ,
			SUBQUERY.VALOR_ANTERIOR ,
			SUBQUERY.VALOR_POSTERIOR ,
			FASES ,
			@ROW_NUMBER:= IF(@NOME_LINK = SUBQUERY.NOME_LINK, @ROW_NUMBER + 1, 1) AS ROW_NUMBER ,
			@NOME_LINK := SUBQUERY.NOME_LINK AS NOME_LINK_CONTROLE
	FROM	(
		SELECT	A.id AS ID_ALTERACAO_LINK  ,
				B.name AS NOME_LINK ,
				CONVERT_TZ(A.date_created, @@session.time_zone, '-03:00') AS DATA_CRIACAO_ALTERACAO ,
				C.user_name AS USUARIO_ALTERACAO ,
				A.before_value_string AS VALOR_ANTERIOR ,
				A.after_value_string AS VALOR_POSTERIOR ,
				CASE
					WHEN (A.before_value_string = 'elaboracao' AND A.after_value_string = 'elaborando') THEN 'ELABORACAO -> ELABORANDO'
					WHEN (A.before_value_string = 'elaborando' AND A.after_value_string = 'aprovacao') THEN 'ELABORANDO -> APROVACAO'
					WHEN (A.before_value_string = 'aprovacao'  AND A.after_value_string = 'alteracao') THEN 'APROVACAO -> ALTERACAO'
					WHEN (A.before_value_string = 'alteracao'  AND A.after_value_string = 'alterando') THEN 'ALTERACAO -> ALTERANDO'
					WHEN (A.before_value_string = 'alterando'  AND A.after_value_string = 'aprovacao') THEN 'ALTERANDO -> APROVACAO'
					WHEN (A.before_value_string = 'aprovacao'  AND A.after_value_string = 'correcao') THEN 'APROVACAO -> CORRECAO'
					WHEN (A.before_value_string = 'correcao'   AND A.after_value_string = 'corrigindo') THEN 'CORRECAO -> CORRIGINDO'
					WHEN (A.before_value_string = 'corrigindo' AND A.after_value_string = 'aprovacao') THEN 'CORRIGINDO -> APROVACAO'
					WHEN (A.before_value_string = 'aprovacao'  AND A.after_value_string = 'implantacao') THEN 'APROVACAO -> IMPLANTACAO'
					WHEN (A.before_value_string = 'implantacao' AND A.after_value_string = 'implantando') THEN 'IMPLANTACAO -> IMPLANTANDO'
					WHEN (A.before_value_string = 'implantando' AND A.after_value_string = 'publicado') THEN 'IMPLANTADO -> PUBLICADO'
					WHEN (A.before_value_string = 'elaboracao'  AND A.after_value_string = 'publicado') THEN 'ELABORACAO -> IMPLANTADO'
				ELSE UPPER(CONCAT(A.before_value_string, SPACE(1), '->', SPACE(1), A.after_value_string, SPACE(1), '[CONTRAFLUXO]'))
				END AS FASES
		FROM	sugarcrm.lnk_links_audit AS A	LEFT OUTER JOIN sugarcrm.lnk_links AS B ON A.parent_id = B.id
												LEFT OUTER JOIN sugarcrm.users AS C ON A.created_by = C.id
		WHERE	A.field_name = 'status' ) AS SUBQUERY
ORDER BY
	SUBQUERY.NOME_LINK ,
	SUBQUERY.DATA_CRIACAO_ALTERACAO ) AS SUBQUERY_2 ; 