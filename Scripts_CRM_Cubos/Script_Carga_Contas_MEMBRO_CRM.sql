-- =============================================
-- Author: Fiama
-- Create date: 29/05/2017
-- Description: Script para carga das contas MEMBRO do CRM em uma estrutura atrelada ao DW.
-- =============================================

USE sugarcrm ;

# Contas Membro:
SELECT	CONVERT(A.id USING Latin1) AS CONTA_ID ,
		CONVERT(A.name USING Latin1) AS CONTA_CRM ,
		CONVERT(A.parent_id USING Latin1) AS CONTA_ID_PAI ,
		CONVERT(B.cnpj_c USING Latin1) AS CNPJ ,
		CONVERT(B.tipo_c USING Latin1) AS TIPO ,
        CONVERT(A.account_type USING Latin1) AS CATEGORIA ,
        A.date_entered AS DATA_ENTRADA ,
        B.porcentual_rateio_c AS PORCENTUAL_RATEIO ,
        CONVERT(B.mercado_c USING Latin1) AS MERCADO ,
        (SELECT	CONVERT(A1.user_name USING Latin1) AS PROPRIETARIO_CONTA
		 FROM	sugarcrm.users AS A1
         WHERE	A.assigned_user_id = A1.id) AS PROPRIETARIO_CONTA
FROM	sugarcrm.accounts AS A		LEFT OUTER JOIN sugarcrm.accounts_cstm AS B ON A.id = B.id_c
WHERE	IFNULL(A.parent_id, '') != '' # Conta Membro
		AND A.deleted = 0 ;