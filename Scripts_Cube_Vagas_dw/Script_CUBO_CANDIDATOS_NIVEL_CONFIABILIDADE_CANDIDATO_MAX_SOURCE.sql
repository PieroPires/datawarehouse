=IF(CANDIDATOS_NIVEL_CONFIABILIDADE[CPF] <> BLANK() &&
	MAXX(FILTER(CANDIDATOS_NIVEL_CONFIABILIDADE
			;CANDIDATOS_NIVEL_CONFIABILIDADE[CPF]=EARLIER(CANDIDATOS_NIVEL_CONFIABILIDADE[CPF])
			&& CANDIDATOS_NIVEL_CONFIABILIDADE[NRO_NIVEL_CONFIABILIDADE_SOURCE]>EARLIER(CANDIDATOS_NIVEL_CONFIABILIDADE[NRO_NIVEL_CONFIABILIDADE_SOURCE])
			&& CANDIDATOS_NIVEL_CONFIABILIDADE[CPF]<>BLANK()
			)
			;CANDIDATOS_NIVEL_CONFIABILIDADE[NRO_NIVEL_CONFIABILIDADE_SOURCE]
		) = BLANK();
			[NRO_NIVEL_CONFIABILIDADE_SOURCE];
			MAXX(FILTER(CANDIDATOS
			;CANDIDATOS_NIVEL_CONFIABILIDADE[CPF]=EARLIER(CANDIDATOS_NIVEL_CONFIABILIDADE[CPF])
			&& CANDIDATOS_NIVEL_CONFIABILIDADE[NRO_NIVEL_CONFIABILIDADE_SOURCE]>EARLIER(CANDIDATOS_NIVEL_CONFIABILIDADE[NRO_NIVEL_CONFIABILIDADE_SOURCE])
			&& CANDIDATOS_NIVEL_CONFIABILIDADE[CPF]<>BLANK()
			)
			;CANDIDATOS_NIVEL_CONFIABILIDADE[NRO_NIVEL_CONFIABILIDADE_SOURCE]))