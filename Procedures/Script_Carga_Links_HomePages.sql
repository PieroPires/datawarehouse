-- =============================================
-- Author: Fiama
-- Create date: 23/01/2017
-- Description: Indicador Status de Modificação
-- =============================================

USE sugarcrm ;

SELECT	CONVERT(ID_CONTA USING latin1) AS ID_CONTA ,
		CONVERT(CONTA USING latin1) AS CONTA ,
		CONVERT(ID_LINK USING latin1) AS ID_LINK ,
		CONVERT(NOME_LINK USING latin1) AS NOME_LINK ,
        CONVERT(STATUS_LINK USING latin1) AS STATUS_LINK ,
        CONVERT(CATEGORIA_LINK USING latin1) AS CATEGORIA_LINK ,
        DATA_CRIACAO_LINK AS DATA_CRIACAO_LINK,
        DATA_MODIFICACAO_LINK AS DATA_MODIFICACAO_LINK ,
        QTD_TRANSICOES_LINK ,
        DATA_ULT_TRANSICAO_STATUS AS DATA_ULT_TRANSICAO_STATUS , 
        QTD_STATUS_ALTERACAO ,
        DATA_ULT_ALTERACAO_STATUS AS DATA_ULT_ALTERACAO_STATUS ,
        IFNULL(SUM(QTD_DIAS_APROVACAO), 0) AS QTD_DIAS_APROVACAO
FROM	(
		SELECT	DISTINCT D.id AS ID_CONTA ,
				D.name AS CONTA ,
				A.id AS ID_LINK ,
				A.name AS NOME_LINK ,
				A.status AS STATUS_LINK ,
				A.type AS CATEGORIA_LINK ,
				A.date_entered AS DATA_CRIACAO_LINK ,
				A.date_modified AS DATA_MODIFICACAO_LINK ,
				(SELECT	COUNT(*) AS QTD_TRANSICOES_LINK
				 FROM	lnk_links_audit AS A1
				 WHERE	A.id = A1.parent_id
						AND A1.field_name = 'status') AS QTD_TRANSICOES_LINK ,
				(SELECT	MAX(A1.date_created) AS DATA_ULT_TRANSICAO_STATUS
				 FROM	lnk_links_audit AS A1
				 WHERE	A.id = A1.parent_id
						AND A1.field_name = 'status'
				 ORDER BY A1.date_created DESC
				 LIMIT 1) AS DATA_ULT_TRANSICAO_STATUS ,
				 (SELECT SUM(CASE WHEN A1.before_value_string = 'alteracao' OR A1.after_value_string = 'alteracao' THEN 1 ELSE 0 END) AS QTD_STATUS_ALTERACAO
				  FROM lnk_links_audit AS A1
				  WHERE A.id = A1.parent_id
						AND A1.field_name = 'status') AS QTD_STATUS_ALTERACAO ,
				 (SELECT A1.date_created AS DATA_ULT_STATUS_ALTERACAO
				  FROM lnk_links_audit AS A1
				  WHERE A.id = A1.parent_id
						AND A1.field_name = 'status'
						AND (A1.before_value_string = 'alteracao' OR A1.after_value_string = 'alteracao')
				  ORDER BY A1.date_created DESC
				  LIMIT 1) AS DATA_ULT_ALTERACAO_STATUS ,
				  DATEDIFF((SELECT A1.date_created AS DATA_PROX_APROVACAO
						   FROM lnk_links_audit AS A1
						   WHERE A.id = A1.parent_id
								AND B.after_value_string = 'aprovacao'
								AND A1.date_created > B.date_created
						   ORDER BY A1.date_created
						   LIMIT 1), B.date_created) AS QTD_DIAS_APROVACAO
		FROM	sugarcrm.lnk_links AS A		LEFT OUTER JOIN sugarcrm.lnk_links_audit AS B ON A.id = B.parent_id AND B.after_value_string = 'aprovacao' AND B.field_name = 'status'
											LEFT OUTER JOIN sugarcrm.lnk_links_accounts_c AS C ON C.lnk_links_accountslnk_links_idb = A.id AND C.deleted = 0
											LEFT OUTER JOIN sugarcrm.accounts AS D ON D.id = C.lnk_links_accountsaccounts_ida AND D.deleted = 0
		WHERE	A.deleted = 0 # Link não removido
				AND A.assigned_user_id = (SELECT A1.id AS ATRIBUIDO_A_PROPRIETARIO
										  FROM	users AS A1
										  WHERE	A1.user_name = 'homepages')
	) AS SUB   
GROUP BY
		ID_LINK ,
		NOME_LINK ,
        STATUS_LINK ,
        CATEGORIA_LINK ,
        DATA_CRIACAO_LINK ,
        DATA_MODIFICACAO_LINK ,
        QTD_TRANSICOES_LINK ,
        DATA_ULT_TRANSICAO_STATUS , 
        QTD_STATUS_ALTERACAO ,
        DATA_ULT_ALTERACAO_STATUS ;