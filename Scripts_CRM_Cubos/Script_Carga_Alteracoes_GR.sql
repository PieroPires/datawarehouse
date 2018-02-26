-- =============================================
-- Author: Fiama
-- Create date: 22/02/2018
-- Description: Carga do histórico de alterações do GR na CONTA.
-- =============================================

USE sugarcrm ;

SELECT	CONVERT(B.name USING Latin1) AS CONTA ,
		CONVERT_TZ(A.date_created , @@session.time_zone, '-03:00') AS DATA_ALTERACAO ,
		CONVERT(C.user_name USING Latin1) AS VALOR_ANTERIOR ,
        CONVERT(D.user_name USING Latin1) AS VALOR_ATUALIZADO ,
		CONVERT(B.id USING Latin1) AS CONTA_ID
FROM	sugarcrm.accounts_audit AS A	INNER JOIN sugarcrm.accounts AS B ON A.parent_id = B.id
										LEFT OUTER JOIN sugarcrm.users AS C ON A.before_value_string = C.id
										LEFT OUTER JOIN sugarcrm.users AS D ON A.after_value_string = D.id
WHERE	A.field_name = 'assigned_user_id'
ORDER BY 1 ;