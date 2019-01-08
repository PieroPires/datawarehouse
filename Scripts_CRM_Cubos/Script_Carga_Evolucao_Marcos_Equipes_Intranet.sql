-- =============================================
-- Author: Fiama
-- Create date: 06/12/2018
-- Description: Script para carga da Evolução dos Marcos das Equipes.
-- =============================================

SELECT n.nid AS MARCO_NID,
	   groups.title AS EQUIPE,
	   contador.field_contador_value AS MARCO_INDICADOR,
	   titulo.field_marcos_titulo_value AS MARCO_TITULO,
	   atingimento.field_marcos_atingimento_value AS PERC_ATINGIMENTO,
	   marco_ciclo.field_marcos_ciclo_target_id AS CICLO_NID,
	   ciclo.field_ciclo_titulo_value AS CICLO,
	   criterio_marco.entity_id AS CRITERIO_NID,
	   criterio.field_criterio_sucesso_value AS CRITERIO_SUCESSO,
       contexto.field_contexto_do_impacto_value AS CONTEXTO_IMPACTO_NEGOCIO,
       field_impacto_tipo.field_impacto_tipo_tid AS IMPACTO_NEGOCIO,    
       
       field_contador.field_contador_value AS DIRECIONADOR,
       field_dir.field_direcionador_value AS TITULO_DIRECIONADOR,
       field_impacto_tipo_2.field_impacto_tipo_tid AS IMPACTO_PE,
       ciclo_periodo.field_ciclo_periodo_value AS CICLO_INICIO,
       ciclo_periodo.field_ciclo_periodo_value2 AS CICLO_FIM,
       status.field_marcos_status_value AS STATUS
FROM drp_node n
LEFT JOIN drp_field_data_field_equipes equipe ON n.nid = equipe.entity_id
LEFT JOIN drp_groups groups ON equipe.field_equipes_target_id = groups.gid
LEFT JOIN drp_field_data_field_marcos_ciclo marco_ciclo ON n.nid = marco_ciclo.entity_id
LEFT JOIN drp_field_data_field_ciclo_titulo ciclo ON marco_ciclo.field_marcos_ciclo_target_id = ciclo.entity_id
LEFT JOIN drp_field_data_field_contador contador ON n.nid = contador.entity_id
LEFT JOIN drp_field_data_field_marcos_titulo titulo ON n.nid = titulo.entity_id
LEFT JOIN drp_field_data_field_marcos_status status ON n.nid = status.entity_id
LEFT JOIN drp_field_data_field_marcos_atingimento atingimento ON n.nid = atingimento.entity_id  
LEFT JOIN drp_field_data_field_pe_marco criterio_marco ON n.nid = criterio_marco.field_pe_marco_target_id 
LEFT JOIN drp_field_data_field_criterio_sucesso criterio ON criterio_marco.entity_id = criterio.entity_id 
LEFT JOIN drp_field_data_field_ciclo_periodo ciclo_periodo ON marco_ciclo.field_marcos_ciclo_target_id = ciclo_periodo.entity_id

# Impacto de Negócio
LEFT JOIN drp_field_data_field_impacto_marco impacto_marco ON n.nid = impacto_marco.field_impacto_marco_target_id 
LEFT JOIN drp_field_data_field_contexto_do_impacto contexto ON impacto_marco.entity_id = contexto.entity_id 
LEFT JOIN drp_field_data_field_impacto_tipo field_impacto_tipo ON impacto_marco.entity_id  = field_impacto_tipo.entity_id

# Impacto do PE
LEFT JOIN drp_field_data_field_pe_marco impacto_pe_marco ON n.nid = impacto_pe_marco.field_pe_marco_target_id
LEFT JOIN drp_field_data_field_pe_direcionador dir ON impacto_pe_marco.entity_id = dir.entity_id
LEFT JOIN drp_field_data_field_direcionador field_dir ON dir.field_pe_direcionador_target_id = field_dir.entity_id
LEFT JOIN drp_field_data_field_contador field_contador ON dir.field_pe_direcionador_target_id = field_contador.entity_id 
LEFT JOIN drp_field_data_field_obj_estrategico obj ON impacto_pe_marco.entity_id = obj.entity_id 
LEFT JOIN drp_field_data_field_objetivo field_obj ON obj.field_obj_estrategico_target_id = field_obj.entity_id
LEFT JOIN drp_field_data_field_contador field_contador_obj ON obj.field_obj_estrategico_target_id = field_contador_obj.entity_id
LEFT JOIN drp_field_data_field_impacto_tipo field_impacto_tipo_2 ON impacto_pe_marco.entity_id = field_impacto_tipo_2.entity_id

WHERE n.type ='marcos'
ORDER BY ciclo.field_ciclo_titulo_value