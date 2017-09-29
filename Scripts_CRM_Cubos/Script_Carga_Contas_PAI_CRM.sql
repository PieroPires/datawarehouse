-- =============================================
-- Author: Fiama
-- Create date: 29/05/2017
-- Description: Script para carga das contas PAI do CRM em uma estrutura atrelada ao DW.
-- =============================================

USE sugarcrm ;

# Contas Pai:
SELECT	CONVERT(A.id USING Latin1) AS CONTA_ID ,
		CONVERT(A.name USING Latin1) AS CONTA_CRM ,
		CONVERT(B.cnpj_c USING Latin1) AS CNPJ ,
        CONVERT(CASE WHEN B.num_membros_c > 0 THEN 'SIM' ELSE 'NÃO' END USING Latin1) AS POSSUI_CONTA_MEMBRO ,
		CONVERT(CASE WHEN    (SELECT COUNT(*) AS QTD_OPORTUNIDADES
							  FROM   sugarcrm.accounts_opportunities AS A1
							  WHERE  A1.deleted = 0
									 AND A.id = A1.account_id) > 0 THEN 'SIM' ELSE 'NÃO' END USING Latin1) AS POSSUI_OPORTUNIDADE ,
		CONVERT(B.tipo_c USING Latin1) AS TIPO ,
        CONVERT(A.account_type USING Latin1) AS CATEGORIA ,
		A.date_entered AS DATA_ENTRADA ,
        B.porcentual_rateio_c AS PORCENTUAL_RATEIO ,
        B.valor_principal_c AS VALOR_PRINCIPAL ,
        CONVERT(B.mercado_c USING Latin1) AS MERCADO ,
        (SELECT	CONVERT(A1.user_name USING Latin1) AS PROPRIETARIO_CONTA
		 FROM	sugarcrm.users AS A1
         WHERE	A.assigned_user_id = A1.id) AS PROPRIETARIO_CONTA
FROM	sugarcrm.accounts AS A	LEFT OUTER JOIN sugarcrm.accounts_cstm AS B ON A.id = B.id_c
WHERE	A.deleted = 0 
		AND IFNULL(A.parent_id, '') = '' ;