USE export
GO

  
ALTER VIEW TailTarget.Exportacao      
as      
      
with /*objetivo5 as       
    query desativada em 20180423  
      substituida pelo nivel fluencia(      
   select   oc.CodCand_cargo      
            , isnull(S1.Descr_setor, '') obj1        
            , isnull(S2.Descr_setor, '') obj2        
            , isnull(S3.Descr_setor, '') obj3        
            , isnull(S4.Descr_setor, '') obj4        
            , isnull(S5.Descr_setor, '') obj5        
            , isnull(ch.Descr_Hierarquia, '') hrq        
   from     Export.ExactTarget.OjetivoCandAux oc  left outer join [hrh-data].dbo.[Cad_setores] S1 ON S1.Cod_setor = oc.obj1       
              left outer join [hrh-data].dbo.[Cad_setores] S2 ON S2.Cod_setor = oc.obj2      
              left outer join [hrh-data].dbo.[Cad_setores] S3 ON S3.Cod_setor = oc.obj3      
              left outer join [hrh-data].dbo.[Cad_setores] S4 ON S4.Cod_setor = oc.obj4      
              left outer join [hrh-data].dbo.[Cad_setores] S5 ON S5.Cod_setor = oc.obj5      
              left outer join [hrh-data].dbo.cad_hierarquias ch on ch.Cod_hierarquia = oc.hrq      
   )      
     
   , Idioma3 as      
   (      
   select   IC.CodCand_idiomaCand      
            , isnull(CI1.Descr_idioma, '')   idi1      
            , isnull(CI2.Descr_idioma, '')   idi2        
            , isnull(CI3.Descr_idioma, '')   idi3         
            , isnull(CF1.Nivel_Fluencia, '') flu1        
            , isnull(CF2.Nivel_Fluencia, '') flu2        
            , isnull(CF3.Nivel_Fluencia, '') flu3        
   from     Export.ExactTarget.IdiomaCand IC left outer join [hrh-data].dbo.Cad_idiomas CI1 ON CI1.Cod_idioma = IC.idioma1       
            left outer join [hrh-data].dbo.Cad_idiomas CI2 ON CI2.Cod_idioma = IC.idioma2      
            left outer join [hrh-data].dbo.Cad_idiomas CI3 ON CI3.Cod_idioma = IC.idioma3      
            left outer join [hrh-data].dbo.Cad_fluencias CF1 on CF1.Cod_fluencia = IC.conversacao1      
            left outer join [hrh-data].dbo.Cad_fluencias CF2 on CF2.Cod_fluencia = IC.conversacao2      
            left outer join [hrh-data].dbo.Cad_fluencias CF3 on CF3.Cod_fluencia = IC.conversacao3      
   )      
   ,*/ Graduado as      
   (      
   select   CodCand_form      
            , isnull(CG.descr_cursoGrad, '') ClassificaoCursoGraduacao      
            , isnull(instit_form, '') InstituicaoGraduacao      
            ,  case  codStatus_form      
                     when -1 then '' -- Não preenchido      
                     when 10 then 'Interrompido'      
                     when 20 then 'Cursando'      
                     when 30 then 'Curso Concluído'      
               end SituacaoAtual      
            ,  case        
                     when isnull(DataStatus_Form, '') <> '' then convert(char(6), DataStatus_Form, 112)      
                     else ''      
               end AnoMesConclusao      
   from     [hrh-data].dbo.[Cand-Formacao] CF  with(nolock) inner join Export.ExactTarget.Graduado G on G.chaveSQL_form = CF.chaveSQL_form       
               left outer join [hrh-data].dbo.Cad_cursos_graduacao CG on CF.CodCursoGrad_form = CG.Cod_cursoGrad -- Descr_CursoGrad         
   )      
   , Experiencia as      
   (      
   select   CodCand_exp      
            , isnull(CP.Descr_porte, '') PorteUltEmpresa      
            , isnull(replace(CS.Descr_segmento,',',';'), '') SegmentoUltEmpresa      
            , isnull(CH.Descr_Hierarquia, '') NivelProfissionalUltEmpresa       
            , isnull(CT.Descr_setor, '') AreaUltEmpresa       
            ,  case        
                     when isnull(Inic_exp, '') <> '' then convert(char(6), Inic_exp, 112)      
                     else ''      
               end dtEntradaUltEmpresa      
            ,  case        
                     when isnull(fim_exp, '') <> '' then convert(char(6), fim_exp, 112)      
                     else ''      
               end dtSaidaUltEmpresa      
            , isnull(CE.Descr_exp, '') ExperienciaUltEmpresa       
            , isnull(CE.UltCargo_exp, '') CargoUltEmpresa       
   from     [hrh-data].dbo.[Cand-Experiencia] CE inner join Export.ExactTarget.Experiencia E on E.ChaveSQL_Exp = CE.ChaveSQL_Exp       
             left outer join [hrh-data].dbo.[Cand-ExpOcupacoes] CO with(nolock)   on CO.cod_expOcup = E.cod_expOcup      
             left outer join [hrh-data].dbo.cad_portes cp on ce.codporte_exp = cp.cod_porte      
             left outer join [hrh-data].dbo.Cad_segmentos CS on CE.CodSegmento_exp = CS.cod_segmento      
             left outer join [hrh-data].dbo.Cad_setores CT on CT.cod_setor = CO.CodSetor_expocup        
             left outer join [hrh-data].dbo.cad_hierarquias CH on ch.Cod_hierarquia = CO.CodHierarquia_expocup      
   )      
select 'hash' [email], 'id' id/*, 'nome' nome*/, 'data de cadastro' dtCadastro, 'data de atualizacao' dtUltAtualizacao, 'genero' genero, 'estado civil' estadoCivil      
  , 'qtd de filhos' qtdFilho, 'cidade' cidade, 'estado' estado, 'data de nascimento' DtNasc_cand, 'ultimo salario' ultSalario, 'pretensao salarial' PretSalario      
  , 'objetivo profissional 1' objetivo1, 'objetivo profissional 2' objetivo2, 'objetivo profissional 3' objetivo3, 'objetivo profissional 4' objetivo4      
  , 'objetivo profissional 5' objetivo5, 'nivel profissional do objetivo' NivelProfissionalObjetivo, 'idioma 1' idioma1, 'idioma 2' idioma2, 'idioma 3' idioma3      
  , 'fluencia 1' fluencia1, 'fluencia 2' fluencia2, 'fluencia 3' fluencia3, 'formacao' Formacao, 'classificacao do curso' ClassificaoCursoGraduacao      
  , 'instituicao de graduacao' InstituicaoGraduacao, 'situacao atual' SituacaoAtual, 'ano mes de conclusao' AnoMesConclusao, 'porte da ultima empresa' PorteUltEmpresa      
  , 'segmento da ultima empresa' SegmentoUltEmpresa, 'area da ultima empresa' AreaUltEmpresa, 'data de entrada na ultima empresa' dtEntradaUltEmpresa      
  , 'data de saida da ultima empresa' dtSaidaUltEmpresa, 'nivel profissional na ultima empresa' NivelProfissionalUltEmpresa, 'cargo na ultima empresa' CargoUltEmpresa      
  , 'candidato sem experiencia' CandidatoSemExperiencia, 'mala direta' MalaDireta_cand, 'data da ultima candidatura' dtUltCandidatura,  
  'professor' professor,'tecnologia' tecnologia,'engenharia' engenharia,'direito' direito,'marketing_comunicacao' marketing_comunicacao,'rh' rh,'administracao' administracao,   
  'lideranca' lideranca,  
  'autonomo_empreendedor' autonomo_empreendedor,  
  'lookalike_rev' lookalike_rev,  
  'lookalike_ingles' lookalike_ingles,  
  'lookalike_ingles_2' lookalike_ingles_2,  
  'nivel_ingles' nivel_ingles,  
  'nivel_espanhol' nivel_espanhol,  
  'primeiro_emprego' primeiro_emprego,  
  'nivel_profissional' nivel_profissional,  
  'ultimo_salario' ultimo_salario,   
  'OP' OP      
union all      
select       
 --lower(convert(varchar(max), HASHBYTES('SHA2_256',lower(Email_cand)), 2)) email      
 lower(convert(varchar(max), HASHBYTES('SHA2_256',lower(CONVERT(VARCHAR,Email_cand))), 2)) email      
   , cast(tc.Cod_cand as varchar) id      
        -- , ExactTarget.RemoverCharEspecial(Nome_cand) nome      
         , convert(varchar, DtCriacao_cand, 103) dtCadastro      
         , convert(varchar, tc.UltDtAtual_cand, 103) dtUltAtualizacao      
         ,  case  isnull(masc_cand, '')      
                  when 0 then 'F'      
                  when 1 then 'M'      
            else ''      
            end as genero      
         ,REPLACE(REPLACE(REPLACE(isnull(Descr_estado_civil, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') estadoCivil      
   
         , isnull(cast(NroFilhos_cand as varchar), '') qtdFilho      
         ,REPLACE(REPLACE(REPLACE(isnull(Descr_cidadeMer, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') cidade 
         ,REPLACE(REPLACE(REPLACE(isnull(Descr_estadoMer, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') estado
         , isnull(convert(varchar, DtNasc_cand, 103), '') DtNasc_cand      
         --, isnull(cast(UltSal_cand as varchar), '') ultSalario      
         ,'' as ultSalario  
         , isnull(cast(ValSalPret_cand as varchar), '') PretSalario      
               
         -- Visão Objetivo      
         --, ExactTarget.RemoverCharEspecial(isnull(obj1, '')) objetivo1      
         --, ExactTarget.RemoverCharEspecial(isnull(obj2, '')) objetivo2      
         --, ExactTarget.RemoverCharEspecial(isnull(obj3, '')) objetivo3      
         --, ExactTarget.RemoverCharEspecial(isnull(obj4, '')) objetivo4      
         --, ExactTarget.RemoverCharEspecial(isnull(obj5, '')) objetivo5    
       
         --, REPLACE(REPLACE(REPLACE(isnull(obj1, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') objetivo1      
         --, REPLACE(REPLACE(REPLACE(isnull(obj2, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') objetivo2      
         --, REPLACE(REPLACE(REPLACE(isnull(obj3, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') objetivo3      
         --, REPLACE(REPLACE(REPLACE(isnull(obj4, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') objetivo4      
         --, REPLACE(REPLACE(REPLACE(isnull(obj5, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') objetivo5    
         ,'' objetivo1  
         ,'' objetivo2  
         ,'' objetivo3  
         ,'' objetivo4  
         ,'' objetivo5  
         
         , '' NivelProfissionalObjetivo      
         --,ISNULL(F.NivelProfissionalObjetivo,'') NivelProfissionalObjetivo      
  
         -- Visão Idioma      
         /*  
         , isnull(idi1, '') idioma1      
         , isnull(idi2, '') idioma2      
         , isnull(idi3, '') idioma3      
         , isnull(flu1, '') fluencia1      
         , isnull(flu2, '') fluencia2      
         , isnull(flu3, '') fluencia3      
         */  
         , '' idioma1      
         , '' idioma2      
         , '' idioma3      
         , '' fluencia1      
         , '' fluencia2      
         , '' fluencia3      
  
         -- Visão Formação      
         , isnull(replicate('0', 2 - len(cod_formMax)) + cast(cod_formMax as varchar) + Descr_formMax, '') Formacao -- Formação Max        
         ,REPLACE(REPLACE(REPLACE(isnull(ClassificaoCursoGraduacao, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') ClassificaoCursoGraduacao -- Visão Grauação      
         --, ExactTarget.RemoverCharEspecial(isnull(InstituicaoGraduacao, '')) InstituicaoGraduacao      
         ,REPLACE(REPLACE(REPLACE(isnull(InstituicaoGraduacao, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') InstituicaoGraduacao      
         ,REPLACE(REPLACE(REPLACE(isnull(SituacaoAtual, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') SituacaoAtual
		 ,REPLACE(REPLACE(REPLACE(isnull(AnoMesConclusao, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') AnoMesConclusao
      
         -- Visao Experiencia      
		 ,REPLACE(REPLACE(REPLACE(isnull(E.PorteUltEmpresa, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') PorteUltEmpresa  

         --, ExactTarget.RemoverCharEspecial(isnull(E.SegmentoUltEmpresa, '')) SegmentoUltEmpresa      
		 ,REPLACE(REPLACE(REPLACE(isnull(E.SegmentoUltEmpresa, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') SegmentoUltEmpresa      
         ,REPLACE(REPLACE(REPLACE(isnull(E.AreaUltEmpresa, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') AreaUltEmpresa       

         , isnull(convert(varchar, E.dtEntradaUltEmpresa, 103), '') dtEntradaUltEmpresa      
         , isnull(convert(varchar, E.dtSaidaUltEmpresa, 103), '') dtSaidaUltEmpresa      
         ,REPLACE(REPLACE(REPLACE(isnull(E.NivelProfissionalUltEmpresa, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') NivelProfissionalUltEmpresa       

         --, ExactTarget.RemoverCharEspecial(isnull(E.CargoUltEmpresa, '')) CargoUltEmpresa       
		, REPLACE(REPLACE(REPLACE(isnull(E.CargoUltEmpresa, ''),CHAR(10),''),CHAR(13),''),CHAR(9),'') CargoUltEmpresa       
         , case         
               when  (      
                     isnull(E.PorteUltEmpresa, '') = ''      
                     and isnull(E.SegmentoUltEmpresa, '') = ''      
                     and isnull(E.AreaUltEmpresa, '') = ''      
                     and isnull(convert(varchar, E.dtEntradaUltEmpresa, 103), '') = ''      
                     and isnull(convert(varchar, E.dtSaidaUltEmpresa, 103), '') = ''      
                     and isnull(E.NivelProfissionalUltEmpresa, '') = ''      
                     and isnull(E.ExperienciaUltEmpresa, '') = ''      
                     and isnull(E.CargoUltEmpresa, '') = ''        
                     ) then '1'      
               else '0'      
            end CandidatoSemExperiencia      
  , isnull(cast(tc.MalaDireta_cand as varchar), '') MalaDireta_cand          
         , isnull(convert(varchar, U.UltimaCandidatura, 103), '') dtUltCandidatura    
   ,CASE WHEN T1.TIPO_PERFIL = 1 THEN 'S' ELSE 'N' END AS professor     
   ,CASE WHEN T2.TIPO_PERFIL = 2 THEN 'S' ELSE 'N' END AS tecnologia     
   ,CASE WHEN T3.TIPO_PERFIL = 3 THEN 'S' ELSE 'N' END AS engenharia  
   ,CASE WHEN T4.TIPO_PERFIL = 4 THEN 'S' ELSE 'N' END AS direito  
   ,CASE WHEN T5.TIPO_PERFIL = 5 THEN 'S' ELSE 'N' END AS marketing_comunicacao  
   ,CASE WHEN T6.TIPO_PERFIL = 6 THEN 'S' ELSE 'N' END AS rh  
   ,CASE WHEN T7.TIPO_PERFIL = 7 THEN 'S' ELSE 'N' END AS administracao  
   ,CASE WHEN T8.TIPO_PERFIL = 8 THEN 'S' ELSE 'N' END AS lideranca  
   ,CASE WHEN T9.TIPO_PERFIL = 14 THEN 'S' ELSE 'N' END AS autonomo_empreendedor   
     
   ,'' AS lookalike_rev  
   ,'' AS lookalike_ingles   
--    ,CASE WHEN T13.TIPO_PERFIL = 13 THEN '3' -- GRUPO DE CONTROLE  
--          WHEN T11.TIPO_PERFIL = 11 THEN '1' -- ALTA PROB. DE CONVERSAO  
--          WHEN T12.TIPO_PERFIL = 12 THEN '2' -- BAIXA PROB. DE CONVERSAO  
--          ELSE '0' END AS lookalike_ingles_2   
   ,'' as lookalike_ingles_2  
   ,ISNULL(IDIOMA1.NIVEL_INGLES,'') AS NIVEL_INGLES  
   ,ISNULL(IDIOMA2.NIVEL_ESPANHOL,'') AS NIVEL_ESPANHOL  
   ,CASE WHEN T10.TIPO_PERFIL = 15 THEN 'S' ELSE 'N' END AS PRIMEIRO_EMPREGO  
   ,REPLACE(ISNULL(F.NivelProfissionalObjetivo,''),CHAR(9),'') NIVEL_PROFISSIONAL  
   ,ISNULL(cast(UltSal_cand as varchar), '') ULTIMO_SALARIO  
   , 'UPS' OP -- Coluna obrigatoria para UPDATE na TailTarget.      
 from     Export.ExactTarget.ControleExportacao tc inner join [hrh-data].dbo.Candidatos C on tc.cod_cand = C.cod_cand       
             left outer join [hrh-data].dbo.Cad_estado_civil CEC on C.CodEstadoCivil_cand = CEC.Cod_estado_civil      
             left outer join [hrh-data].dbo.Meridian_Cad_Cidades MCC on C.CodCidade_cand = MCC.Cod_cidadeMer      
             left outer join [hrh-data].dbo.Meridian_Cad_Estados MEC on C.CodUF_cand = MEC.Cod_estadoMer      
             --left outer join objetivo5 oc on oc.CodCand_cargo = C.Cod_cand      
             --left outer join Idioma3 idi on idi.CodCand_idiomaCand = C.Cod_cand  
             OUTER APPLY ( SELECT TOP 1 CASE WHEN C1.Nivel_fluencia IN ('Avançada') THEN 'Fluente'  
                                       ELSE C1.Nivel_fluencia END AS NIVEL_INGLES  
                              FROM [hrh-data].[dbo].[Cand-idiomas] A1  
                              INNER JOIN [hrh-data].[dbo].[Cad_idiomas] B1 ON B1.Cod_idioma = A1.Cod_idiomaCand   
                              INNER JOIN [hrh-data].[dbo].[Cad_fluencias] C1 ON C1.Cod_fluencia = A1.Nconv_idiomaCand  
                              WHERE B1.descr_idioma = 'Inglês'   
                              AND A1.CodCand_idiomaCand = C.Cod_cand ) IDIOMA1  
             OUTER APPLY ( SELECT TOP 1 CASE WHEN C1.Nivel_fluencia IN ('Avançada') THEN 'Fluente'  
                                       ELSE C1.Nivel_fluencia END AS NIVEL_ESPANHOL  
                              FROM [hrh-data].[dbo].[Cand-idiomas] A1  
                              INNER JOIN [hrh-data].[dbo].[Cad_idiomas] B1 ON B1.Cod_idioma = A1.Cod_idiomaCand   
                              INNER JOIN [hrh-data].[dbo].[Cad_fluencias] C1 ON C1.Cod_fluencia = A1.Nconv_idiomaCand  
                              WHERE B1.descr_idioma = 'Espanhol'   
                              AND A1.CodCand_idiomaCand = C.Cod_cand ) IDIOMA2  
             left outer join [hrh-data].dbo.Cad_formacaoMax FM on C.CodFormMax_Cand = FM.Cod_formMax       
             left outer join Graduado G on C.Cod_cand = G.CodCand_form      
             left outer join Experiencia E on C.Cod_cand = E.CodCand_exp  
             OUTER APPLY ( SELECT TOP 1 B1.Descr_hierarquia AS NivelProfissionalObjetivo  
                           FROM [hrh-data].dbo.[Cand-ExpOcupacoes] A1  
                           INNER JOIN [hrh-data].dbo.cad_hierarquias B1 ON B1.Cod_hierarquia = A1.CodHierarquia_ExpOcup  
                           WHERE CodCand_ExpOcup =  c.cod_Cand  
          ORDER BY A1.AnoIni_ExpOcup DESC  ) F  
             left outer join ExactTarget.UltimaCandidatura U on c.cod_Cand = U.cod_cand      
    LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T1 ON T1.COD_CAND = C.COD_CAND    
                    AND T1.TIPO_PERFIL = 1 -- PROFESSOR    
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T2 ON T2.COD_CAND = C.COD_CAND    
                    AND T2.TIPO_PERFIL = 2 -- TECNOLOGIA  
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T3 ON T3.COD_CAND = C.COD_CAND    
                    AND T3.TIPO_PERFIL = 3 -- ENGENHARIA  
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T4 ON T4.COD_CAND = C.COD_CAND    
                    AND T4.TIPO_PERFIL = 4 -- DIREITO  
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T5 ON T5.COD_CAND = C.COD_CAND    
                    AND T5.TIPO_PERFIL = 5 -- MARKETING_COMUNICACAO  
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T6 ON T6.COD_CAND = C.COD_CAND    
                    AND T6.TIPO_PERFIL = 6 -- RH  
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T7 ON T7.COD_CAND = C.COD_CAND    
                    AND T7.TIPO_PERFIL = 7 -- ADMINISTRACAO  
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T8 ON T8.COD_CAND = C.COD_CAND    
                    AND T8.TIPO_PERFIL = 8 -- LIDERANCA  
 LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T9 ON T9.COD_CAND = C.COD_CAND    
                    AND T9.TIPO_PERFIL = 14 -- AUTONOMO_EMPREENDEDOR  
      LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T10 ON T10.COD_CAND = C.COD_CAND    
                    AND T10.TIPO_PERFIL = 15 -- PRIMEIRO_EMPREGO  
 -- lookalike revendedoras desabilitado  
      --LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T9 ON T9.COD_CAND = C.COD_CAND    
      --              AND T9.TIPO_PERFIL = 9 -- LOOKALIKE REVENDEDORES (BOTICARIO)  
      -- LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T11 ON T11.COD_CAND = C.COD_CAND    
      --               AND T11.TIPO_PERFIL = 11 -- LOOKALIKE INGLES COM ALTA PROB. CONVERTER   
      -- LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T12 ON T12.COD_CAND = C.COD_CAND    
      --               AND T12.TIPO_PERFIL = 12 -- LOOKALIKE INGLES COM BAIXA PROB. CONVERTER   
      -- LEFT OUTER JOIN VAGAS_DW.VAGAS_DW.TAIL_CANDIDATO_PERFIL T13 ON T13.COD_CAND = C.COD_CAND    
      --               AND T13.TIPO_PERFIL = 13 -- LOOKALIKE INGLES GRUPO DE CONTROLE  
--where tc.MalaDireta_cand = 1     
where  UltDtControle = cast(getdate() as date) -- 1o. arquivo, apenas com tc.MalaDireta_cand = 1    
  