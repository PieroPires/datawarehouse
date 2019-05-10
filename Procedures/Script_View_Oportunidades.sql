CREATE OR REPLACE VIEW `vwOportunidadesComProdutos`
AS
select    `acc`.`name` AS `cntConta`
          ,`acc`.`account_type` AS `cntCategoria`
          ,`acc`.`industry` AS `cntNegócio`
          ,`accs`.`perfil_c` AS `cntPerfil`
          ,`accpai`.`name` AS `cntPai`
          ,`accs`.`id_hsys_c` AS `cntIdHsys`
          ,`opp`.`name` AS `oppOportunidade`
          ,`opp`.`id` AS `oppID`
          ,`opp`.`sales_stage` AS `oppFase`
          ,`opp`.`opportunity_type` AS `oppCategoria`
          ,round(`opp`.`amount`,2) AS `oppValor`
          ,`opp`.`date_entered` AS `oppDataCriada`
          ,`opp`.`date_closed` AS `oppDataFechamento`
          ,`usropp`.`user_name` AS `oppProprietário`
          ,concat(`lead`.`first_name`,' ',`lead`.`last_name`) AS `leadNome`
          ,`lead`.`lead_source` AS `leadFonte`,`usrleadprop`
          .`user_name` AS `leadProprietário`,`usrleadcriador`
          .`user_name` AS `leadCriador`,`cmp`
          .`name` AS `leadCampanha`,`off`
          .`name` AS `prpProposta`,`off`.`id` AS `prpID`
          ,`off`.`grand_total` AS `prpValor`
          ,`offs`.`principal_c` AS `prpPrincipal`
          ,`prod`.`svnumber` AS `prodCodProduto`
          ,`serv`.`zeitbezug` AS `prodRecorrencia`
          ,`serv`.`price` AS `prodValor`
          ,`serv`.`discount_value` AS `prodDesconto`
          ,`serv`.`quantity` AS `prodQuantidade`
		  ,accs.id_vagas_c AS Id_Vagas
          #,round(((`serv`.`price` * (1 - (`serv`.`discount_value` / 100))) * `serv`.`quantity`),2) AS `prodValorFinal`
		  ,round((case serv.discount_select when 'rel' then round(`serv`.`price` * (1 - `serv`.`discount_value` / 100) * `serv`.`quantity` ,2) else (`serv`.`price` - `serv`.`discount_value`) * `serv`.`quantity` end),2) AS `prodValorFinal`
          ,acc.id AS contaid
		  ,accs.valor_principal_c AS cntValorPrincipal
          ,offprop.name AS cntPropostaAprov
          ,offprop.grand_total AS cntValPropAprov
		  ,usraccount.user_name AS cntProprietario
          ,accs.conta_erp_c AS Fatura_ERP
		  ,accs.cnpj_c AS CNPJ
		  ,accs.tipo_c AS TipoConta
		
		  ,usrcropp.user_name AS oppCriador
          ,usrmodaccount.user_name AS cntUsuarioAlteracao
          ,acc.date_modified AS DataAlteracaoConta
          #,opp_cstm.motivo_da_perda_c AS MotivoPerda
          #,opp_cstm.motivo_da_perda_complemento_c AS MotivoPerdaComplemento
          ,camp.name AS campanha
          ,case when exists ( select * 
							   from accounts 
                               where parent_id = acc.id
                               and deleted = 0) then 1 else 0 end as possui_conta_membro
		  ,CONVERT(accs.cnae_secao_id_c USING Latin1) AS cnae_secao_id
		  ,CONVERT(accs.cnae_secao_descr_c USING Latin1) AS cnae_secao
		  ,CONVERT(accs.cnae_divisao_id_c USING Latin1) AS cnae_divisao_id
		  ,CONVERT(accs.cnae_divisao_descr_c USING Latin1) AS cnae_divisao
		  ,CONVERT(accs.cnae_classe_id_c USING Latin1) AS cnae_classe_id
		  ,CONVERT(accs.cnae_classe_descr_c USING Latin1) AS cnae_classe
		  ,CONVERT(accs.cnae_faixa_funcionarios_c USING Latin1) AS cnae_faixa_funcionarios
		  ,CONVERT(accs.segmento_c USING Latin1) AS segmento
		  ,accs.cnae_subclasse_id_c
		  ,accs.cnae_subclasse_descr_c
		  ,offprop_cstm.num_posicoes_mes_c AS POSICOES_MES 
          ,offprop_cstm.num_unidades_c AS TOTAL_UNIDADES
          ,offprop_cstm.num_posicoes_unidade_mes_c AS POSICOES_POR_UNIDADE
          ,off.clientcontact_id AS ID_CONTATO
          ,CONVERT(opp_cstm.motivo_do_fechamento_c USING Latin1) AS MOTIVO_FECHAMENTO
	      ,CONVERT(opp_cstm.motivo_do_fechamento_detalhe_c USING Latin1) AS MOTIVO_FECHAMENTO_DETALHE
          ,CONVERT(opp_cstm.concorrente_c USING Latin1) AS MOTIVO_CONCORRENTE
          ,CONVERT(CAST(opp_cstm.perfis_especificos_c AS CHAR(200)) USING Latin1) AS MOTIVO_PERFIL_ESPECIFICO
		  ,opp_cstm.data_proposta_c AS Data_proposta
		  ,opp_cstm.data_avaliacao_c AS Data_avaliacao_proposta
		  ,opp_cstm.data_contrato_c AS Data_contrato
from     ((((((((((((((((`opportunities` `opp`
          join `users` `usropp` on((`usropp`.`id` = `opp`.`assigned_user_id`)))
          join `accounts_opportunities` `accopp` on(((`accopp`.`opportunity_id` = `opp`.`id`) and (`accopp`.`deleted` = 0))))
          join `accounts` `acc` on(((`acc`.`id` = `accopp`.`account_id`) and (`acc`.`deleted` = 0))))
          join `accounts_cstm` `accs` on((`accs`.`id_c` = `acc`.`id`)))
          left join `accounts` `accpai` on((`accpai`.`id` = `acc`.`parent_id`)))
          left join `leads` `lead` on((`lead`.`opportunity_id` = `opp`.`id`)))
          left join `leads_cstm` `leads` on((`leads`.`id_c` = `lead`.`id`)))
          left join `users` `usrleadprop` on((`usrleadprop`.`id` = `lead`.`assigned_user_id`)))
          left join `users` `usrleadcriador` on((`usrleadcriador`.`id` = `lead`.`created_by`)))
          left join `campaigns` `cmp` on((`cmp`.`id` = `lead`.`campaign_id`)))
          left join `oqc_offering_opportunities` `offopp` on(((`offopp`.`opportunities_idb` = `opp`.`id`)
                                                          and (`offopp`.`deleted` = 0))))
          left join `oqc_offering` `off` on(((`off`.`id` = `offopp`.`oqc_offering_ida`) and (`off`.`deleted` = 0))))
          left join `oqc_offering_cstm` `offs` on((`offs`.`id_c` = `off`.`id`)))
          left join `oqc_offerin_oqc_service` `offserv` on(((`offserv`.`oqc_offering_ida` = `off`.`id`)
                                                          and (`offserv`.`deleted` = 0))))
          left join `oqc_service` `serv` on(((`serv`.`id` = `offserv`.`oqc_service_idb`) and (`serv`.`deleted` = 0))))
          left join `oqc_product` `prod` on(((`prod`.`id` = `serv`.`product_id`) and (`prod`.`deleted` = 0))))
          left join users usraccount on usraccount.id = acc.assigned_user_id
	  left join users usrcropp on usrcropp.id = opp.created_by
          left join oqc_offering offprop on offprop.id = accs.oqc_offering_id_c
	  left join oqc_offering_cstm offprop_cstm on offprop_cstm.id_c = offprop.id
          left join users usrmodaccount on usrmodaccount.id = acc.modified_user_id
          left join opportunities_cstm opp_cstm on opp_cstm.id_c = opp.id
          left join campaigns camp on camp.id = opp.campaign_id
where     (`opp`.`deleted` = 0)
          #and accs.tipo_c <> "ex_cliente"
          #and acc.account_type <> "ex_cliente"